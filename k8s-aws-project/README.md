# AWS Free Tier ile Kubernetes Cluster Kurulumu

Bu proje, AWS Free Tier kullanarak Kind ile 3 node'lu bir Kubernetes cluster kurulumu, Helm chart ile uygulama dağıtımı ve namespace'ler arası network policy yapılandırmasını içermektedir.

## Proje Bileşenleri

1. **AWS Altyapısı**
   - Terraform ile otomatik oluşturma
   - t3.micro EC2 instance (AWS Free Tier kapsamında)
   - Gerekli güvenlik grupları

2. **Kubernetes Cluster**
   - Kind ile 3 node'lu cluster (1 control-plane, 2 worker)
   - Docker container'ları içinde Kubernetes node'ları

3. **Namespace ve Uygulama Dağıtımı**
   - `codegen` namespace: Yapay Zeka Destekli Kod Üretici uygulaması (Helm chart ile)
   - `nonamens` namespace: Örnek nginx uygulaması

4. **Network Policy Yapılandırması**
   - `nonamens` namespace'inden `codegen` namespace'ine erişim engelleme
   - Test ve doğrulama adımları

## Kurulum Adımları

### 1. AWS Hesabı Oluşturma ve Yapılandırma

1. [AWS'ye kaydolun](https://aws.amazon.com/free/)
2. AWS Management Console'da bir SSH key pair oluşturun:
   - EC2 servisine gidin
   - "Key Pairs" > "Create key pair" seçin
   - İsim: `k8s-key-pair`
   - Format: `.pem` (macOS/Linux) veya `.ppk` (Windows)
   - İndirilen key dosyasını güvenli bir yere kaydedin

3. AWS CLI'ı yapılandırın:
   ```bash
   aws configure
   ```
   - AWS Access Key, Secret Key ve bölge bilgilerinizi girin
   - Default output format: `json`

### 2. Terraform ile AWS Altyapısını Oluşturma

1. Terraform'u başlatın:
   ```bash
   cd k8s-aws-project
   terraform init
   ```

2. Altyapı planını kontrol edin:
   ```bash
   terraform plan
   ```

3. Altyapıyı oluşturun:
   ```bash
   terraform apply
   ```

4. Çıktıda görünen EC2 instance IP adresini not alın.

### 3. EC2 Instance'a Bağlanma

```bash
# macOS/Linux için
chmod 400 k8s-key-pair.pem
ssh -i k8s-key-pair.pem ubuntu@<EC2_IP_ADRESI>

# Windows için PuTTY kullanabilirsiniz
```

### 4. Kind ile Kubernetes Cluster Oluşturma

1. EC2 instance'a bağlandıktan sonra, proje dosyalarını kopyalayın:
   ```bash
   # Yerel bilgisayarınızdan SCP ile
   scp -i k8s-key-pair.pem -r k8s-aws-project/* ubuntu@<EC2_IP_ADRESI>:~/
   ```

2. Kind cluster'ı oluşturun:
   ```bash
   kind create cluster --config kind-config.yaml --name k8s-cluster
   ```

3. Cluster'ı kontrol edin:
   ```bash
   kubectl get nodes
   ```

### 5. Namespace ve Uygulama Dağıtımı

1. Namespace'leri oluşturun:
   ```bash
   kubectl apply -f namespaces/
   ```

2. nginx uygulamasını dağıtın:
   ```bash
   kubectl apply -f deployments/nginx-deployment.yaml
   ```

3. Codegen uygulamasını Helm ile dağıtın:
   ```bash
   # values.yaml dosyasını düzenleyerek Gemini API anahtarınızı ekleyin
   nano helm-charts/codegen-app/values.yaml
   
   # Uygulamayı dağıtın
   helm install codegen-app ./helm-charts/codegen-app -n codegen
   ```

### 6. Network Policy Yapılandırması

Network policy'leri uygulayın:
```bash
kubectl apply -f network-policies/deny-access.yaml
```

### 7. Test ve Doğrulama

Test scriptini çalıştırın:
```bash
chmod +x test-network-policy.sh
./test-network-policy.sh
```

## Temizlik

Kullanımınız bittiğinde, AWS kaynaklarını silmek için:

```bash
terraform destroy
```

## Notlar

- Bu proje, AWS Free Tier kapsamında ücretsiz olarak çalıştırılabilir.
- EC2 instance'ı kullanmadığınız zamanlarda durdurmak, Free Tier saatlerinizi korumak için önemlidir.
- AWS hesabınızda ücret alarmları kurmayı unutmayın.
