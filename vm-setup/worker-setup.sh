#!/bin/bash
# Worker node kurulum scripti

# Script'in root olarak çalıştırılıp çalıştırılmadığını kontrol et
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalıdır" 
   exit 1
fi

# Sistem güncellemelerini yap
echo "[1/9] Sistem güncellemeleri yapılıyor..."
apt-get update && apt-get upgrade -y

# swap'ı devre dışı bırak
echo "[2/9] Swap devre dışı bırakılıyor..."
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# Gerekli paketleri yükle
echo "[3/9] Gerekli paketler yükleniyor..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# containerd kurulumu
echo "[4/9] containerd kurulumu yapılıyor..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y containerd.io

# containerd yapılandırması
echo "[5/9] containerd yapılandırılıyor..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kernel modüllerini yükle
echo "[6/9] Kernel modülleri yükleniyor..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Kubernetes ağ ayarları
echo "[7/9] Kubernetes ağ ayarları yapılıyor..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Kubernetes repo ekle
echo "[8/9] Kubernetes repo ekleniyor..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.26/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.26/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Kubernetes bileşenlerini yükle
echo "[9/9] Kubernetes bileşenleri yükleniyor..."
apt-get update
apt-get install -y kubelet=1.26.0-00 kubeadm=1.26.0-00 kubectl=1.26.0-00
apt-mark hold kubelet kubeadm kubectl

echo "Worker node kurulumu tamamlandı!"
echo "Master node'dan alınan 'kubeadm join' komutunu çalıştırarak cluster'a katılabilirsiniz."
