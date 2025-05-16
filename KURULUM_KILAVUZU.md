# Kubernetes Cluster Kurulum Kılavuzu

Bu kılavuz, 3 node'lu bir Kubernetes cluster kurulumu, uygulama dağıtımı ve network policy yapılandırması için adım adım talimatları içermektedir.

## İçindekiler

1. [Sanal Makine Kurulumu](#1-sanal-makine-kurulumu)
2. [Kubernetes Cluster Kurulumu](#2-kubernetes-cluster-kurulumu)
3. [Namespace ve Uygulama Dağıtımı](#3-namespace-ve-uygulama-dağıtımı)
4. [Network Policy Yapılandırması](#4-network-policy-yapılandırması)
5. [Test ve Doğrulama](#5-test-ve-doğrulama)
6. [Sorun Giderme](#6-sorun-giderme)

## 1. Sanal Makine Kurulumu

### Gereksinimler

Her bir sanal makine için aşağıdaki gereksinimleri sağlayın:
- Ubuntu 22.04 LTS
- En az 2 CPU
- En az 4GB RAM
- En az 20GB disk alanı

### Sanal Makine Oluşturma

Aşağıdaki isimlerle 3 adet sanal makine oluşturun:
- `k8s-master` (Control Plane)
- `k8s-worker1` (Worker Node 1)
- `k8s-worker2` (Worker Node 2)

### Ağ Yapılandırması

Tüm sanal makinelerin birbirleriyle iletişim kurabilmesi için aynı ağda olduklarından emin olun. Sabit IP adresleri atayın ve `/etc/hosts` dosyasına ekleyin:

```bash
# /etc/hosts dosyasına ekleyin (tüm node'larda)
192.168.1.10 k8s-master
192.168.1.11 k8s-worker1
192.168.1.12 k8s-worker2
```

## 2. Kubernetes Cluster Kurulumu

### Master Node Kurulumu

1. Master node'a bağlanın ve kurulum scriptini çalıştırın:

```bash
# Script'i çalıştırılabilir yapın
chmod +x vm-setup/master-setup.sh

# Root olarak çalıştırın
sudo ./vm-setup/master-setup.sh
```

2. Kurulum tamamlandığında, worker node'ları eklemek için kullanılacak `kubeadm join` komutu görüntülenecektir. Bu komutu not alın.

### Worker Node Kurulumu

1. Her bir worker node'a bağlanın ve kurulum scriptini çalıştırın:

```bash
# Script'i çalıştırılabilir yapın
chmod +x vm-setup/worker-setup.sh

# Root olarak çalıştırın
sudo ./vm-setup/worker-setup.sh
```

2. Master node'dan aldığınız `kubeadm join` komutunu her bir worker node'da çalıştırın:

```bash
# Örnek join komutu (sizin komutunuz farklı olacaktır)
sudo kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:1234...
```

### Cluster Durumunu Kontrol Etme

Master node'da aşağıdaki komutu çalıştırarak node'ların durumunu kontrol edin:

```bash
kubectl get nodes
```

Tüm node'ların `Ready` durumunda olduğundan emin olun.

## 3. Namespace ve Uygulama Dağıtımı

### Namespace Oluşturma

Master node'da aşağıdaki komutu çalıştırarak namespace'leri oluşturun:

```bash
kubectl apply -f namespaces/
```

Namespace'lerin oluşturulduğunu doğrulayın:

```bash
kubectl get namespaces
```

### codegen Uygulamasını Dağıtma

1. Helm chart değerlerini güncelleyin:

```bash
# values.yaml dosyasını düzenleyin
nano helm-charts/codegen-app/values.yaml
```

2. `secrets.geminiApiKey` değerini Gemini API anahtarınızla güncelleyin.

3. Helm chart'ı yükleyin:

```bash
helm install codegen-app ./helm-charts/codegen-app -n codegen
```

4. Dağıtımı kontrol edin:

```bash
kubectl get all -n codegen
```

### nginx Uygulamasını Dağıtma

```bash
kubectl apply -f deployments/nginx-deployment.yaml
```

Dağıtımı kontrol edin:

```bash
kubectl get all -n nonamens
```

## 4. Network Policy Yapılandırması

Network policy'leri uygulamak için:

```bash
kubectl apply -f network-policies/deny-access.yaml
```

Network policy'lerin oluşturulduğunu doğrulayın:

```bash
kubectl get networkpolicy --all-namespaces
```

## 5. Test ve Doğrulama

Network policy'lerin doğru çalıştığını test etmek için test scriptini çalıştırın:

```bash
chmod +x test-network-policy.sh
./test-network-policy.sh
```

### Manuel Test

1. `nonamens` namespace'indeki bir pod'a bağlanın:

```bash
kubectl exec -it $(kubectl get pod -n nonamens -o name | head -n 1) -n nonamens -- /bin/bash
```

2. `codegen` namespace'indeki servise ping atmayı deneyin:

```bash
ping codegen-app.codegen.svc.cluster.local
```

Beklenen sonuç: Ping paketleri engellenmelidir.

3. HTTP isteği göndermeyi deneyin:

```bash
curl codegen-app.codegen.svc.cluster.local
```

Beklenen sonuç: İstek zaman aşımına uğramalıdır.

## 6. Sorun Giderme

### Node Durumu Sorunları

Node'lar `NotReady` durumunda ise:

```bash
# Node durumunu kontrol edin
kubectl describe node <node-adı>

# Kubelet servisini kontrol edin
systemctl status kubelet
```

### Network Policy Sorunları

Network policy'ler çalışmıyorsa:

1. Calico CNI'nin doğru çalıştığından emin olun:

```bash
kubectl get pods -n kube-system | grep calico
```

2. Network policy'leri kontrol edin:

```bash
kubectl describe networkpolicy -n codegen
```

3. Pod'ların doğru etiketlere sahip olduğunu kontrol edin:

```bash
kubectl get pods -n codegen --show-labels
kubectl get pods -n nonamens --show-labels
```

### Pod Bağlantı Sorunları

Pod'lar başlatılamıyorsa:

```bash
kubectl describe pod <pod-adı> -n <namespace>
kubectl logs <pod-adı> -n <namespace>
```

## Sonuç

Bu kılavuzu takip ederek:

1. 3 node'lu bir Kubernetes cluster kurdunuz
2. İki farklı namespace oluşturdunuz
3. Her namespace'e uygulama dağıttınız
4. Namespace'ler arası erişimi kısıtlayan network policy'ler uyguladınız
5. Yapılandırmanın doğru çalıştığını test ettiniz

Tebrikler! Kubernetes cluster kurulumu ve network policy yapılandırması başarıyla tamamlandı.
