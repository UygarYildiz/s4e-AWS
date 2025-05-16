# Network Policy Test Senaryoları

Bu doküman, Kubernetes cluster'ında uygulanan network policy'lerin doğru çalıştığını doğrulamak için test senaryolarını içermektedir.

## Test Ortamı

- 3 node'lu Kubernetes cluster (1 master, 2 worker)
- `codegen` namespace'inde çalışan AI kod üretici uygulaması
- `nonamens` namespace'inde çalışan nginx uygulaması
- Network policy: `nonamens` namespace'inden `codegen` namespace'ine erişim engelleme

## Test Senaryoları

### Senaryo 1: Namespace Erişim Kontrolü

**Amaç:** `nonamens` namespace'inden `codegen` namespace'ine erişimin engellendiğini doğrulamak.

**Adımlar:**

1. `nonamens` namespace'indeki bir pod'a bağlanın:
   ```bash
   kubectl exec -it $(kubectl get pod -n nonamens -o name | head -n 1) -n nonamens -- /bin/bash
   ```

2. `codegen` namespace'indeki servise ping atmayı deneyin:
   ```bash
   ping codegen-app.codegen.svc.cluster.local
   ```

3. `codegen` namespace'indeki servise HTTP isteği göndermeyi deneyin:
   ```bash
   curl codegen-app.codegen.svc.cluster.local
   ```

**Beklenen Sonuç:**
- Ping paketleri engellenmelidir (100% paket kaybı veya zaman aşımı)
- HTTP isteği zaman aşımına uğramalıdır

### Senaryo 2: Ters Yönde Erişim Kontrolü

**Amaç:** `codegen` namespace'inden `nonamens` namespace'ine erişimin mümkün olduğunu doğrulamak.

**Adımlar:**

1. `codegen` namespace'indeki bir pod'a bağlanın:
   ```bash
   kubectl exec -it $(kubectl get pod -n codegen -o name | head -n 1) -n codegen -- /bin/bash
   ```

2. `nonamens` namespace'indeki servise ping atmayı deneyin:
   ```bash
   ping nginx.nonamens.svc.cluster.local
   ```

3. `nonamens` namespace'indeki servise HTTP isteği göndermeyi deneyin:
   ```bash
   curl nginx.nonamens.svc.cluster.local
   ```

**Beklenen Sonuç:**
- Ping paketleri başarıyla iletilmelidir
- HTTP isteği başarıyla yanıt almalıdır (nginx hoş geldiniz sayfası)

### Senaryo 3: Aynı Namespace İçinde Erişim

**Amaç:** Aynı namespace içindeki pod'lar arasında erişimin mümkün olduğunu doğrulamak.

**Adımlar:**

1. `nonamens` namespace'inde ikinci bir nginx pod'u oluşturun:
   ```bash
   kubectl run test-nginx --image=nginx -n nonamens
   ```

2. İlk nginx pod'una bağlanın:
   ```bash
   kubectl exec -it $(kubectl get pod -n nonamens -l app=nginx -o name | head -n 1) -n nonamens -- /bin/bash
   ```

3. İkinci nginx pod'una ping atmayı deneyin:
   ```bash
   ping test-nginx
   ```

4. İkinci nginx pod'una HTTP isteği göndermeyi deneyin:
   ```bash
   curl test-nginx
   ```

**Beklenen Sonuç:**
- Ping paketleri başarıyla iletilmelidir
- HTTP isteği başarıyla yanıt almalıdır (nginx hoş geldiniz sayfası)

## Otomatik Test

Tüm test senaryolarını otomatik olarak çalıştırmak için test scriptini kullanabilirsiniz:

```bash
chmod +x test-network-policy.sh
./test-network-policy.sh
```

Script, aşağıdaki kontrolleri gerçekleştirir:
1. Namespace'lerin varlığını kontrol eder
2. Pod'ların çalışıp çalışmadığını kontrol eder
3. Network policy'lerin varlığını kontrol eder
4. `nonamens`'den `codegen`'e erişim testini gerçekleştirir
5. `codegen`'den `nonamens`'e erişim testini gerçekleştirir

## Sorun Giderme

### Ping Komutu Bulunamıyor Hatası

Bazı container imajlarında ping komutu bulunmayabilir. Bu durumda, ping komutunu yükleyin:

```bash
# Debian/Ubuntu tabanlı imajlar için
apt-get update && apt-get install -y iputils-ping

# Alpine tabanlı imajlar için
apk add --no-cache iputils
```

### Curl Komutu Bulunamıyor Hatası

Bazı container imajlarında curl komutu bulunmayabilir. Bu durumda, curl komutunu yükleyin:

```bash
# Debian/Ubuntu tabanlı imajlar için
apt-get update && apt-get install -y curl

# Alpine tabanlı imajlar için
apk add --no-cache curl
```

### Network Policy Çalışmıyor

Network policy'ler çalışmıyorsa, aşağıdaki kontrolleri yapın:

1. CNI eklentisinin network policy'leri desteklediğinden emin olun (Calico, Cilium, vb.)
2. Network policy tanımlarını kontrol edin:
   ```bash
   kubectl describe networkpolicy -n codegen
   ```
3. Pod'ların doğru etiketlere sahip olduğunu kontrol edin:
   ```bash
   kubectl get pods -n codegen --show-labels
   kubectl get pods -n nonamens --show-labels
   ```
