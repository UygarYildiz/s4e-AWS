# Kubernetes Cluster Kurulumu ve Network Policy Uygulaması

Bu proje, S4E şirketi için DevOps stajyer adayı görevi olarak hazırlanmıştır. Proje, 3 node'lu bir Kubernetes cluster kurulumu, Helm chart ile uygulama dağıtımı ve namespace'ler arası network policy yapılandırmasını içermektedir.

## Proje Bileşenleri

1. **Sanal Makine Kurulumu**
   - 1 adet Control Plane (Master) node
   - 2 adet Worker node
   - Ubuntu 22.04 LTS işletim sistemi

2. **Kubernetes Cluster Kurulumu**
   - Kubernetes v1.26.x
   - Container runtime: containerd
   - Cluster kurulum aracı: kubeadm
   - CNI: Calico

3. **Namespace ve Uygulama Dağıtımı**
   - `codegen` namespace: İlk_Proje uygulaması (Helm chart ile)
   - `nonamens` namespace: Örnek nginx uygulaması

4. **Network Policy Yapılandırması**
   - `nonamens` namespace'inden `codegen` namespace'ine erişim engelleme
   - Test ve doğrulama adımları

## Dizin Yapısı

```
.
├── vm-setup/                  # Sanal makine kurulum scriptleri
│   ├── master-setup.sh        # Master node kurulum scripti
│   └── worker-setup.sh        # Worker node kurulum scripti
├── k8s-setup/                 # Kubernetes kurulum dosyaları
│   ├── kubeadm-config.yaml    # kubeadm yapılandırma dosyası
│   └── calico.yaml            # Calico CNI yapılandırması
├── namespaces/                # Namespace tanımları
│   ├── codegen.yaml           # codegen namespace tanımı
│   └── nonamens.yaml          # nonamens namespace tanımı
├── helm-charts/               # Helm chart dosyaları
│   └── codegen-app/           # codegen uygulaması için Helm chart
├── deployments/               # Deployment dosyaları
│   └── nginx-deployment.yaml  # nonamens için nginx deployment
└── network-policies/          # Network policy dosyaları
    └── deny-access.yaml       # Namespace'ler arası erişim engelleme
```

## Kurulum Adımları

### 1. Sanal Makine Kurulumu

Her bir sanal makine için aşağıdaki gereksinimleri sağlayın:
- Ubuntu 22.04 LTS
- En az 2 CPU
- En az 4GB RAM
- En az 20GB disk alanı

Sanal makineleri aşağıdaki isimlerle oluşturun:
- `k8s-master` (Control Plane)
- `k8s-worker1` (Worker Node 1)
- `k8s-worker2` (Worker Node 2)

### 2. Kubernetes Cluster Kurulumu

Detaylı kurulum adımları için `vm-setup/` klasöründeki script dosyalarını kullanın.

### 3. Namespace ve Uygulama Dağıtımı

Namespace'leri oluşturmak için:
```bash
kubectl apply -f namespaces/
```

codegen uygulamasını Helm ile dağıtmak için:
```bash
helm install codegen-app ./helm-charts/codegen-app -n codegen
```

nginx uygulamasını dağıtmak için:
```bash
kubectl apply -f deployments/nginx-deployment.yaml -n nonamens
```

### 4. Network Policy Yapılandırması

Network policy'leri uygulamak için:
```bash
kubectl apply -f network-policies/deny-access.yaml
```

## Test ve Doğrulama

Network policy'nin doğru çalıştığını test etmek için:

1. `nonamens` namespace'indeki bir pod'a bağlanın:
```bash
kubectl exec -it $(kubectl get pod -n nonamens -o name | head -n 1) -n nonamens -- /bin/bash
```

2. `codegen` namespace'indeki servise ping atmayı deneyin:
```bash
ping codegen-app.codegen.svc.cluster.local
```

Beklenen sonuç: Ping paketleri engellenmelidir.

## Ek Dokümanlar

Bu projede aşağıdaki ek dokümanlar bulunmaktadır:

- [Kurulum Kılavuzu](KURULUM_KILAVUZU.md) - Detaylı kurulum adımları
- [Test Senaryoları](TEST_SENARYOLARI.md) - Network policy test senaryoları
- [Test Script](test-network-policy.sh) - Otomatik test scripti

## Kaynaklar

- [Kubernetes Resmi Dokümantasyonu](https://kubernetes.io/docs/)
- [kubeadm Kurulum Kılavuzu](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Calico Dokümantasyonu](https://docs.projectcalico.org/)
- [Kubernetes Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
