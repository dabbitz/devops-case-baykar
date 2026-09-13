# Baykar DevOps Teknik Case

Bu repository, DevOps Teknik Case kapsamında geliştirilen MERN uygulaması ve Python ETL iş yükünün containerization, Kubernetes deployment, AWS EKS, Amazon ECR, CI/CD, backup/restore ve environment yönetimi süreçleriyle birlikte dokümantasyonunu içermektedir.

## Proje Yapısı

```text
DevOps_Case_Final/
├── .github/
│   └── workflows/
│       └── ci.yml                         # GitHub Actions CI/CD pipeline
│
├── docs/
│   ├── screenshots/                       # Çalışma kanıtları
│   ├── architecture.md                    # Sistem mimarisi ve istek akışı
│   ├── backup-restore.md                  # Backup/restore runbook'u
│   └── findings.md                        # Uygulama ilk açıldığında bulunan hatalar
│
├── k8s/
│   ├── eks/                               # EKS ortak Kubernetes kaynakları
│   │   ├── backend-deployment.yaml        # EKS backend Deployment
│   │   ├── backend-service.yaml           # EKS backend ClusterIP Service
│   │   ├── backup-cronjob.yaml            # Günlük MongoDB → S3 backup CronJob
│   │   ├── backup-serviceaccount.yaml     # Backup workload ServiceAccount
│   │   ├── cd-rbac.yaml                   # GitHub Actions Kubernetes RBAC
│   │   ├── etl-cronjob.yaml               # EKS saatlik Python ETL CronJob
│   │   ├── frontend-deployment.yaml       # EKS frontend Deployment
│   │   ├── frontend-service.yaml          # EKS frontend ClusterIP Service
│   │   ├── gateway.yaml                   # EKS Envoy Gateway
│   │   ├── gatewayclass.yaml              # EKS Envoy Gateway Class
│   │   ├── http-route.yaml                # EKS HTTPRoute
│   │   └── kustomization.yaml             # EKS Kustomize base
│   │
│   ├── overlays/
│   │   ├── dev/
│   │   │   └── kustomization.yaml         # Development overlay
│   │   ├── prod/
│   │   │   └── kustomization.yaml         # Production overlay
│   │   └── test/
│   │       └── kustomization.yaml         # Test overlay
│   │
│   ├── backend-deployment.yaml            # Local Kubernetes backend Deployment
│   ├── backend-service.yaml               # Local Kubernetes backend ClusterIP Service
│   ├── ci-mongodb.yaml                    # CI/CD için geçici MongoDB
│   ├── etl-cronjob.yaml                   # Local Kubernetes saatlik Python ETL CronJob
│   ├── frontend-deployment.yaml           # Local Kubernetes frontend Deployment
│   ├── frontend-service.yaml              # Local Kubernetes frontend ClusterIP Service
│   ├── gateway.yaml                       # Local Envoy Gateway
│   ├── gatewayclass.yaml                  # Local Envoy GatewayClass
│   ├── http-route.yaml                    # Local HTTPRoute
│   └── namespace.yaml                     # Local Kubernetes namespace
│
├── mern-project/
│   ├── client/                            # React frontend
│   ├── server/                            # Express.js backend
│   └── .gitignore                         # mern-project klasörünün .gitignore dosyası
│
├── python-project/
│   ├── .dockerignore                      # python-project klasörünün .dockerignore dosyası
│   ├── Dockerfile                         # ETL container image
│   ├── ETL.py                             # Güncel ETL implementation
│   ├── README.md                          # ETL başlangıç açıklamaları
│   └── requirements.txt                   # Python bağımlılıkları
│
├── scripts/
│   ├── backup-restore.ps1                 # MongoDB backup/restore script'i
│   └── check-alerts.ps1                   # Kritik alarm kontrolleri
│
├── .gitignore                             # Projenin .gitignore dosyası
├── CASE_END_ANSWERS.md                    # İngilizce case sonu cevapları
├── CASE_SONU_CEVAPLARI.md                 # Case sonu cevapları
├── DevOps_Technical_Case_EN.docx          # İngilizce case dokümanı
├── DevOps_Teknik_Case_TR.docx             # Türkçe case dokümanı
├── docker-compose.yml                     # Local Docker Compose ortamı
├── eks-cluster.yaml                       # AWS EKS cluster ve node group yapılandırması
├── README_EN.md                           # İngilizce README
├── README.md                              # Proje ve çalıştırma dokümantasyonu
├── setup-k8s.ps1                          # Local Kubernetes kurulum/doğrulama script'i
├── SUBMISSION_EVIDENCE.md                 # İngilizce teslim kanıtları
└── TESLIM_KANITLARI.md                    # Teslim kanıtları
```

## AWS EKS Deployment

Projenin ana deployment ortamı AWS EKS'dir. Frontend, backend ve Python ETL workload'ları Kubernetes üzerinde çalışmakta; Envoy Gateway üzerinden AWS Elastic Load Balancer ile dış erişim sağlanmaktadır.

Repository'de ayrıca Docker Compose ve local Kubernetes yapılandırmaları, uygulamanın geliştirme, test ve yeniden üretilebilirlik amacıyla local ortamda çalıştırılabilmesi için sağlanmıştır. Bu local yapılandırmalar, AWS EKS üzerindeki ana deployment'ın alternatifidir ve cloud ortamının yerini almaz.

### Mevcut AWS EKS Deployment

Projenin çalışma sırasında kullanılan AWS EKS deployment'ı üzerinden uygulamaya erişim sağlanmıştır. Aşağıdaki adreslerde yer alan AWS Load Balancer hostname'leri, public repository'de gereksiz cloud ortamı ayrıntılarını paylaşmamak amacıyla `[REDACTED]` olarak gösterilmiştir.

**Uygulama:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/
```

**Records:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/records
```

**Backend healthcheck:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/api/healthcheck
```

**Create:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/create
```

**Edit:**

```text
http://[REDACTED].eu-central-1.elb.amazonaws.com/edit/<document-id>
```

> **Önemli:** Kullanılan adresler, bu çalışma sırasında oluşturulmuş olan mevcut AWS Load Balancer'a aittir. Bu adresler **kalıcı bir production URL'si olarak değerlendirilmemelidir**. Özellikle EKS cluster'ı, Envoy Gateway veya Load Balancer yeniden oluşturulursa AWS yeni bir hostname atayabilir. Ayrıca teslim sonrasında kullanılan AWS kaynaklarının kaldırılması durumunda erişilemez hale gelebilir.

> **Gerçek EKS erişim adresi:** Public repository'de Load Balancer hostname'i `[REDACTED]` olarak gösterilmiştir. Çalışma sırasında kullanılan gerçek erişim adresi teslim edilen `.zip` dosyasının içinde, projenin root'unda, `aws_url.txt` dosyasında paylaşılmıştır.

### Güncel EKS Erişim Adresini Bulma

AWS Load Balancer tarafından verilen güncel hostname'i Kubernetes üzerinden terminal çıktısından öğrenebilirsiniz.

Öncelikle Envoy Gateway Service'lerini görüntüleyin:

```powershell
kubectl get svc -n envoy-gateway-system
```

Çıktıda `TYPE` değeri `LoadBalancer` olan Envoy Gateway Service'ini bulun. Bu satırdaki `EXTERNAL-IP` alanı, AWS tarafından atanmış güncel Load Balancer hostname'idir.

Örneğin:

```text
NAME                                  TYPE          CLUSTER-IP    EXTERNAL-IP
envoy-devops-case-devops-gateway-...  LoadBalancer  10.x.x.x      <AWS Load Balancer hostname>
```

Güncel hostname'i daha ayrıntılı görmek için:

```powershell
kubectl get svc -n envoy-gateway-system -o wide
```

Buradaki `<AWS Load Balancer hostname>` değeri kullanılarak erişim adresleri aşağıdaki biçimde oluşturulur:

```text
http://<EXTERNAL-IP>/
http://<EXTERNAL-IP>/api/healthcheck
http://<EXTERNAL-IP>/records
http://<EXTERNAL-IP>/create
http://<EXTERNAL-IP>/edit/<document-id>
```

Dolayısıyla README'deki mevcut hostname artık geçerli değilse, yeni adresi yeniden README'ye eklemek yerine öncelikle Kubernetes Service üzerinden güncel `EXTERNAL-IP` değeri kontrol edilmelidir.

### EKS Cluster Yapılandırması

```text
Cluster:
devops-case-eks

Region:
eu-central-1

Managed node group:
devops-workers

Node instance type:
t3.small
```

AWS EKS ortamını kontrol etmek için:

```powershell
eksctl get cluster --region eu-central-1
kubectl get nodes -o wide
kubectl get pods -n devops-case
kubectl get deployments -n devops-case
kubectl get cronjobs -n devops-case
kubectl get services -n devops-case
```

Çalışan EKS node'u Kubernetes `v1.36.3-eks-cb19647` ve Amazon Linux 2023 kullanmaktadır.

### EKS Workloads

```text
Frontend → Deployment + ClusterIP Service + liveness/readiness probes
Backend  → Deployment + ClusterIP Service + liveness/readiness probes + controlled RollingUpdate
ETL      → CronJob
Backup   → Daily CronJob → mongodump → Amazon S3
Gateway  → Envoy Gateway
Routing  → HTTPRoute
```

Backend, frontend ve ETL workload'larında CPU ve memory resource requests/limits tanımlıdır.

EKS deployment'ı için ortak Kubernetes kaynakları `k8s/eks/` altında, environment-specific yapılandırmalar ise Kustomize overlay'leri altında yönetilmektedir. Ayrıntılar **Kustomize Environment Management** bölümünde açıklanmıştır.

EKS üzerinde çalışan workload'ları kontrol etmek için:

```powershell
kubectl get pods -n devops-case -o wide
kubectl get deployments -n devops-case
kubectl get services -n devops-case
kubectl get cronjobs -n devops-case
kubectl get gateway -n devops-case
kubectl get httproute -n devops-case
```

Backend ve frontend Deployment'larında liveness/readiness probe'ları tanımlanmıştır. Backend'in uygulama içi healthcheck endpoint'i `/healthcheck/`, frontend'in healthcheck endpoint'i ise `/` olarak tanımlanmıştır.

Backend Deployment'ı tek node'lu EKS ortamına uygun olarak `maxSurge: 1` ve `maxUnavailable: 0` ile yapılandırılmıştır. Yeni Pod, readiness probe ile hazır olduktan sonra eski Pod sonlandırılır ve geçiş `v1 → v1 + v2 → v2` şeklinde gerçekleşir.

EKS dış erişiminde `/` istekleri frontend'e, `/api` istekleri backend'e yönlendirilir. Bu nedenle backend'in `/healthcheck/` endpoint'i, Envoy Gateway üzerinden public olarak `/api/healthcheck` adresinden erişilebilir durumdadır.

### EKS Gateway Yapılandırması

`GatewayClass` cluster-scoped bir kaynak olduğu için EKS Kustomize base içerisinde yer almamaktadır. EKS cluster'ında mevcut olan Envoy GatewayClass yeniden kullanılmaktadır. Böylece GitHub Actions deployment rolüne gereksiz cluster-wide yetkiler verilmemektedir.

## Sistem Mimarisi

Uygulamanın AWS EKS üzerindeki temel istek akışı aşağıdaki şekildedir:

```text
Kullanıcı / Browser
        ↓
AWS Elastic Load Balancer
        ↓
Envoy Gateway
        ↓
HTTPRoute
   ┌────┴────┐
   ↓         ↓
Frontend   Backend
Service    Service
   ↓         ↓
React      Node.js
+ NGINX    + Express
             ↓
         MongoDB Atlas
```

Python ETL ayrı bir iş akışı olarak GitHub API'den repository bilgisini alarak MongoDB'deki `github_repositories` collection'ını günceller.

```text
GitHub API
    ↓
Python ETL
    ↓
MongoDB Atlas
```

MongoDB Atlas verileri ayrıca günlük olarak otomatik şekilde yedeklenmektedir:

```text
MongoDB Atlas
      ↓
mongodb-backup CronJob
      ↓
mongodump
      ↓
.archive.gz
      ↓
Amazon S3
```

Local Kubernetes ortamında AWS Elastic Load Balancer yerine local Envoy Gateway üzerinden erişim sağlanabilir.

Ayrıntılı mimari diyagram ve bileşen açıklamaları:

`docs/architecture.md`

## Teknolojiler

- React
- Node.js / Express
- MongoDB Atlas
- Python
- Docker / Docker Compose
- Kubernetes
- Kustomize
- AWS EKS
- Amazon ECR
- Amazon S3
- AWS IAM
- GitHub Actions
- GitHub OIDC
- Trivy
- Kubernetes RBAC
- Envoy Gateway
- Helm

> Helm bu projede uygulama workload'larını paketlemek için değil, Envoy Gateway gibi Kubernetes bağımlılıklarını kurmak için kullanılmaktadır. Uygulamanın kendi Kubernetes kaynakları Kustomize ile yönetilmektedir.

## Gereksinimler

AWS üzerinde çalışan mevcut deployment'ı kullanmak için temel olarak:

- AWS hesabı ve gerekli yetkiler
- GitHub repository erişimi

gereklidir.

Local çalıştırma veya geliştirme için ayrıca:

- Docker Desktop (Kubernetes açık)
- Docker Compose
- Node.js 20+
- Python 3.10+
- `kubectl`
- Helm

kullanılabilir.

AWS EKS yönetimi ve infrastructure işlemleri için ayrıca:

- AWS CLI
- `eksctl`

kullanılabilir.

## Konfigürasyon

Secret veya bağlantı bilgileri source code içerisinde hardcode edilmemiştir.

Cloud deployment'ında hassas değerler GitHub Actions Secrets üzerinden Kubernetes Secret kaynaklarına aktarılmaktadır. Local çalıştırmada ise `.env` dosyası kullanılmaktadır.

### 1. MongoDB Atlas hazırlığı

Normal Kubernetes deployment'ında MongoDB, Kubernetes cluster'ı içerisinde çalıştırılmamakta; MongoDB Atlas kullanılmaktadır.

Kendi MongoDB Atlas hesabınızda:

1. Bir MongoDB deployment oluşturun.
2. `sample_training` adında bir database kullanın.
3. Backend'in kullanacağı `records` collection'ının oluşturulmasına izin verin.
4. ETL'nin kullanacağı `github_repositories` collection'ını oluşturun veya ilk ETL çalışmasında oluşturulmasına izin verin.
5. Kullanacağınız IP adresinin MongoDB Atlas Network Access bölümünde erişime izinli olduğundan emin olun.
6. Uygun bir database user oluşturun ve gerekli erişim yetkilerini verin.
7. Connection URI bilgisini alın.

> Uygulamanın production ortamında MongoDB Atlas kullanması nedeniyle database adı ve collection isimleri aşağıdaki environment değişkenleri ile proje kodundaki kullanım ile uyumlu olmalıdır.

### 2. GitHub API hazırlığı

Python ETL, GitHub API üzerinden repository bilgisi almaktadır.

Kendi GitHub repository'nizi kullanacaksanız aşağıdaki değerleri buna göre değiştirin:

```text
GITHUB_OWNER=<GitHub kullanıcı veya organizasyon adı>
GITHUB_REPO=<repository adı>
GITHUB_TOKEN=<GitHub Personal Access Token>
```

Kullanılan token yalnızca gerekli GitHub API erişimlerini içermelidir.

### 3. `.env` dosyasını oluşturma

Local çalıştırma için proje kökünde `.env` adlı bir dosya oluşturun.

Örnek yapı:

```text
ATLAS_URI=<MongoDB Atlas connection string>
GITHUB_OWNER=<GitHub owner>
GITHUB_REPO=<GitHub repository>
GITHUB_TOKEN=<GitHub token>
MONGODB_DB=sample_training
MONGODB_URI=<MongoDB connection string>
MONGODB_COLLECTION=github_repositories
```

`ATLAS_URI` backend tarafından, `MONGODB_URI`, `MONGODB_DB` ve `MONGODB_COLLECTION` ise Python ETL tarafından kullanılmaktadır.

Gerçek credential, token veya connection string değerlerini source code'a yazmayın ve Git repository'sine commit etmeyin.

### 4. İsim uyuşmazlıklarına dikkat

Kurulum sırasında aşağıdaki isimlerin kod ve konfigürasyon ile uyumlu olması gerekir:

| Alan                 | Kullanım                   |
| -------------------- | -------------------------- |
| `MONGODB_DB`         | `sample_training`          |
| `MONGODB_COLLECTION` | `github_repositories`      |
| `GITHUB_OWNER`       | GitHub repository sahibi   |
| `GITHUB_REPO`        | GitHub repository adı      |
| `ATLAS_URI`          | Backend MongoDB bağlantısı |
| `MONGODB_URI`        | ETL MongoDB bağlantısı     |

`GITHUB_OWNER` ve `GITHUB_REPO` değiştirilebilir. Ancak farklı bir repository kullanıldığında ETL'nin erişim yetkisine sahip bir GitHub token verilmelidir.

### 5. Kubernetes Secret'ları

Local Kubernetes deployment'ında `setup-k8s.ps1` script'i `.env` içerisindeki hassas değerleri okuyarak gerekli Kubernetes Secret kaynaklarını oluşturur.

AWS EKS deployment'ında ise Secret değerleri GitHub Actions Secrets üzerinden alınarak EKS namespace'indeki Kubernetes Secret kaynaklarına aktarılır.

Secret değerleri workflow dosyasına veya source code'a hardcode edilmemektedir.

---

## MERN Uygulamasını Çalıştırma

### Frontend

```powershell
cd mern-project/client
npm install
npm start
```

Frontend varsayılan olarak:

```text
http://localhost:3000
```

üzerinden çalışır.

### Backend

```powershell
cd mern-project/server
npm install
npm start
```

Backend:

```text
http://localhost:5050
```

üzerinden çalışır.

Healthcheck:

```text
GET /healthcheck/
```

## Docker Compose

Kubernetes kullanmadan local container ortamını doğrulamak için proje kökünde:

```powershell
docker compose build
docker compose up -d
```

Container durumunu kontrol etmek için:

```powershell
docker compose ps
```

Frontend:

```text
http://localhost:3000
```

Backend healthcheck:

```text
http://localhost:5050/healthcheck/
```

ETL container'ı one-shot workload olarak çalışır ve işlem tamamlandığında `Exited (0)` durumuna geçmesi beklenir.

Temizlik:

```powershell
docker compose down
```

## Kubernetes Deployment

Local Kubernetes manifestleri `k8s/` klasöründe bulunmaktadır.

Kurulumun otomatik gerçekleştirilmesi için:

```powershell
.\setup-k8s.ps1
```

Script aşağıdaki işlemleri gerçekleştirmektedir:

1. Namespace oluşturma
2. Kubernetes Secret oluşturma
3. Docker image'larını build etme
4. Image'ları Kubernetes ortamına aktarma
5. Frontend, backend ve ETL workload'larını deploy etme
6. Container security kontrollerini doğrulama
7. Envoy Gateway kurulumu
8. Gateway ve HTTPRoute oluşturma
9. Endpoint doğrulaması

Namespace:

```text
devops-case
```

Workload kontrolü:

```powershell
kubectl get pods -n devops-case
kubectl get deployments -n devops-case
kubectl get cronjobs -n devops-case
kubectl get services -n devops-case
```

Frontend endpoint:

```text
http://localhost/
```

Backend healthcheck:

```text
http://localhost/api/healthcheck/
```

## Kustomize Environment Management

Uygulamanın Kubernetes kaynakları Kustomize kullanılarak ortak bir base ve environment-specific overlay yapısında yönetilmektedir.

Ortak EKS kaynakları:

```text
k8s/eks/
```

Environment overlay'leri:

```text
k8s/overlays/dev/
k8s/overlays/test/
k8s/overlays/prod/
```

Backend ve frontend için environment bazında CPU request değerleri farklılaştırılmış, memory request ise tek `t3.small` worker node üzerindeki kapasite nedeniyle tüm ortamlarda `32Mi` olarak tutulmuştur:

| Environment |  CPU | Memory |
| ----------- | ---: | -----: |
| dev         |  50m |   32Mi |
| test        |  75m |   32Mi |
| prod        | 100m |   32Mi |

Deployment replica sayısı tüm ortamlarda `1` olarak yapılandırılmıştır.

ETL CronJob için environment'lar arasında anlamlı bir farklılık bulunmadığından ortak base yapılandırması kullanılmaktadır.

Secret değerleri Kustomize dosyalarında plaintext olarak tutulmaz; hassas değerler Kubernetes Secret kaynakları üzerinden sağlanır.

Production deployment öncesinde Kustomize çıktısı server-side dry-run ile doğrulanır:

```powershell
kubectl apply --dry-run=server -k k8s/overlays/prod
```

Ardından production overlay EKS'ye uygulanır:

```powershell
kubectl apply -k k8s/overlays/prod
```

Kustomize çıktısını kontrol etmek için:

```powershell
kubectl kustomize .\k8s\overlays\dev
kubectl kustomize .\k8s\overlays\test
kubectl kustomize .\k8s\overlays\prod
```

## Kubernetes Workloads

Backend ve frontend için Kubernetes liveness/readiness probe'ları tanımlanmıştır. Backend `/healthcheck/`, frontend `/` endpoint'i üzerinden kontrol edilmektedir.

Backend Deployment'ı tek node'lu EKS ortamına uygun olarak `maxSurge: 1` ve `maxUnavailable: 0` ile yapılandırılmıştır. Yeni Pod, readiness probe ile hazır olduktan sonra eski Pod sonlandırılır ve geçiş `v1 → v1 + v2 → v2` şeklinde gerçekleşir.

ETL schedule:

```text
0 * * * *
```

ETL `Avrupa/İstanbul` timezone'u kullanarak saatlik çalışmaktadır.

ETL aynı repository tekrar işlendiğinde `github_id` alanını kullanarak mevcut kaydı günceller.

## Kubernetes Güvenliği

Container'lar root kullanıcı ile çalıştırılmamaktadır.

```text
Backend  → node / UID 1000
Frontend → nginx / UID 101
ETL      → appuser / UID 10001
```

Ayrıca Kubernetes workload'larında:

```yaml
runAsNonRoot: true

allowPrivilegeEscalation: false

capabilities:
  drop:
    - ALL
```

kontrolleri uygulanmıştır.

Kubernetes workload'larında ayrıca resource requests/limits ve uygulama health probes tanımlanarak workload'ların kaynak kullanımı ve çalışma durumu Kubernetes tarafından yönetilmektedir.

Secret değerleri repository source code'u veya Docker image içerisine gömülmemektedir.

## Konteynır Güvenlik Taraması

CI/CD pipeline'ında frontend, backend ve Python ETL container image'ları Trivy kullanılarak taranmaktadır.

Trivy taraması:

```text
Docker images
     ↓
Trivy
     ↓
OS package vulnerabilities
Application dependencies
Embedded secrets
```

kontrollerini gerçekleştirmektedir.

Tarama sonuçları GitHub Actions log'larında raporlanmaktadır. Mevcut case yapılandırmasında vulnerability bulguları raporlanmakta, ancak `exit-code: 0` kullanıldığı için bulgular deployment'ı otomatik olarak engellememektedir.

Bu kontrol, CI/CD sürecine image, dependency ve secret scanning eklemektedir.

## Python ETL

ETL, GitHub API'den repository bilgisini alarak MongoDB'ye aktarır.

Kubernetes üzerinde ETL saatlik olarak çalışmaktadır.

Aynı repository tekrar işlendiğinde:

```text
github_id = 1361100555
```

üzerinden mevcut document güncellenir ve duplicate kayıt oluşturulmaz.

ETL log'larında aşağıdaki gibi kayıtlar görülür:

```text
UPDATE: repository updated
Updated fields: ...
MongoDB document count: 1
ETL completed successfully.
```

## CI/CD

CI/CD GitHub Actions üzerinde çalışmaktadır.

Pipeline:

```text
Git Push / Pull Request
        ↓
Frontend build
        ↓
Backend validation
        ↓
Python validation
        ↓
Docker image build
        ↓
Trivy security scan
        ↓
CI başarılı
        ↓
Production approval
        ↓
GitHub OIDC
        ↓
AWS IAM Role
        ↓
Amazon ECR image push
        ↓
AWS EKS authentication
        ↓
Kustomize production overlay validation
        ↓
Kustomize production deployment
        ↓
Image update with commit SHA
        ↓
Rollout verification
        ↓
Backend healthcheck
        ↓
Frontend HTTP check
```

Pull Request açıldığında `validate-and-build` job'ı çalışır; deployment yapılmaz.

`main` branch'ine yapılan başarılı push sonrasında `deploy-eks` job'ı production approval bekleme durumuna geçer. Yetkili reviewer onayından sonra deployment adımları çalıştırılır.

Deployment job'ı:

1. GitHub OIDC üzerinden AWS IAM Role'u assume eder.
2. Frontend, backend ve ETL Docker image'larını build eder.
3. Image'ları Git commit SHA ile tag'ler.
4. Image'ları Amazon ECR'a push eder.
5. Frontend, backend ve ETL image'larını Trivy ile OS package, dependency ve secret taramasından geçirir.
6. EKS cluster'ı için kubeconfig oluşturur.
7. Kubernetes Secret kaynaklarını günceller.
8. `k8s/overlays/prod` Kustomize overlay'ini `kubectl apply --dry-run=server -k k8s/overlays/prod` ile doğrular.
9. Production overlay'ini `kubectl apply -k k8s/overlays/prod` ile EKS'ye uygular.
10. Deployment image'larını commit SHA tag'lerine günceller.
11. Backend ve frontend rollout durumlarını kontrol eder.
12. Gateway ve HTTPRoute kaynaklarını doğrular.
13. AWS Load Balancer üzerinden backend healthcheck gerçekleştirir.
14. Frontend dış erişimini doğrular.

CI aşamasındaki bir build veya validation adımı başarısız olduğunda `deploy-eks` job'ı çalıştırılmamaktadır.

## GitHub OIDC ve AWS Authentication

GitHub Actions'ın AWS erişimi için uzun ömürlü AWS access key kullanılmamaktadır.

Authentication akışı:

```text
GitHub Actions
      ↓
GitHub OIDC token
      ↓
GitHubActions-EKS-Deploy IAM Role
      ↓
Geçici AWS credentials
      ↓
Amazon ECR + AWS EKS
```

IAM Role, GitHub repository'sinin `production` Environment'ı ile sınırlı OIDC trust policy kullanmaktadır. Production Environment yalnızca main branch'inden deployment kabul edecek şekilde yapılandırılmıştır.

## EKS RBAC

GitHub Actions IAM Role'u EKS Access Entry aracılığıyla:

```text
github-actions-deploy
```

Kubernetes grubuna bağlanmıştır.

Bu grup için:

```text
devops-case
```

namespace'i ile sınırlı Kubernetes `Role` ve `RoleBinding` tanımlanmıştır.

GitHub Actions'a `cluster-admin` yetkisi verilmemiştir.

RBAC tanımı:

```text
k8s/eks/cd-rbac.yaml
```

## Amazon ECR

CI/CD pipeline'ında üç ayrı Amazon ECR repository'si kullanılmaktadır:

```text
devops-case-backend
devops-case-frontend
devops-case-etl
```

Image'lar Git commit SHA'sı kullanılarak tag'lenmektedir.

Örnek:

```text
devops-case-etl:<commit-sha>
```

Bu yapı deployment edilen image sürümünün ilgili source commit ile doğrudan ilişkilendirilebilmesini sağlar.

## Backup ve Restore

MongoDB Atlas verileri production ortamında AWS EKS üzerinde çalışan günlük bir Kubernetes CronJob ile otomatik olarak yedeklenmektedir.

Otomatik backup akışı:

```text
MongoDB Atlas
      ↓
EKS mongodb-backup CronJob
      ↓
mongodump
      ↓
.archive.gz
      ↓
Amazon S3
sample_training/
```

Backup schedule:

```text
0 2 * * *
```

Timezone:

```text
Avrupa/İstanbul
```

Backup dosyaları UTC timestamp içeren ayrı archive dosyaları olarak oluşturulmaktadır.

Örnek:

```text
sample_training_20260912T230006Z.archive.gz
```

Backup'lar Amazon S3 üzerinde cluster dışında saklanmaktadır:

```text
s3://devops-case-baykar-backups-203309795174/sample_training/
```

Backup archive'ının boş olmadığı kontrol edilmekte ve S3 upload sonrasında `aws s3api head-object` ile object'ın başarıyla oluşturulduğu doğrulanmaktadır.

Backup workload'u ayrı bir `s3-backup` ServiceAccount kullanmakta ve gerekli S3 erişimi least-privilege IAM policy ile sınırlandırılmaktadır. Backup container'ları non-root kullanıcılarla çalıştırılmakta ve privilege escalation devre dışı bırakılmaktadır.

Bu case kapsamında S3 Lifecycle tabanlı otomatik retention/silme politikası, PITR, otomatik restore verification ve periyodik tam DR drill uygulanmamıştır.

Backup ve restore sürecinin geri yüklenebilirliğini uçtan uca doğrulamak için ayrıca repository içerisinde bulunan PowerShell script'i kullanılabilir. Bu manuel test production'daki otomatik S3 backup mekanizmasından bağımsızdır:

```powershell
.\scripts\backup-restore.ps1 -Action Backup

.\scripts\backup-restore.ps1 -Action Restore
```

Mevcut collection'ların üzerine restore edilmesi gerektiğinde:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

Manuel E2E testinde kullanılan local backup konumu:

```text
backups/sample-training-backup/
```

Bu dizin `.gitignore` tarafından repository dışında tutulmaktadır.

Backup ve restore süreci gerçek veri üzerinde uçtan uca test edilmiştir. Test sırasında kayıt oluşturulmuş, backup alınmış, database silinmiş, verinin kaybolduğu doğrulanmış ve backup'tan `mongorestore` ile veri geri yüklenmiştir. Restore sonrasında verinin MongoDB Atlas ve web arayüzü üzerinden tekrar erişilebilir olduğu doğrulanmıştır.

## Logging ve Alerts

Backend ve Python ETL tarafında operasyonel log'lar kullanılmaktadır.

ETL log'ları repository bilgisi, MongoDB bağlantı durumu, update işlemleri, document count ve işlemin başarıyla tamamlandığı bilgisini göstermektedir.

Ayrıca:

```text
scripts/check-alerts.ps1
```

script'i iki kritik alarm senaryosunu kontrol etmektedir:

- ETL işleminin başarısız olması veya beklenen zaman aralığında başarılı bir ETL çalışmasının bulunmaması
- Frontend veya backend health endpoint'lerine erişilememesi

Alarm senaryoları test modu kullanılarak doğrulanabilmektedir.

## Bulgular ve İyileştirmeler

Başlangıç uygulamasında tespit edilen production-readiness sorunları:

`docs/findings.md`

dosyasında dokümante edilmiştir.

Başlıca iyileştirmeler:

- Frontend API adresinin environment/configuration üzerinden yönetilmesi
- Backend input validation
- ObjectId validation
- Database connection error handling
- CORS restriction
- HTTP error handling
- Non-root container kullanımı
- Kubernetes securityContext
- ETL duplicate prevention
- CI/CD validation ve deployment kontrolleri
- AWS EKS deployment
- Amazon ECR image yönetimi
- GitHub OIDC authentication
- Namespace-scoped Kubernetes RBAC
- Kustomize environment management
- Trivy ile container image, dependency ve secret scanning
- MongoDB'nin Amazon S3'e otomatik olarak yedeklenmesi

## Rollback

Deployment problemi durumunda mevcut Kubernetes Deployment geçmişi kontrol edilir:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

Önceki çalışan sürüme dönmek için:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

Rollback sonrasında rollout ve healthcheck kontrolleri tekrar gerçekleştirilir.

Deployment edilen image'lar commit SHA ile tag'lendiği için önceki image sürümü Amazon ECR üzerinde de belirlenebilir.

## Temizlik

Local Kubernetes workload'larını kaldırmak için:

```powershell
kubectl delete namespace devops-case
```

Docker Compose ortamını kapatmak için:

```powershell
docker compose down
```

Yerel olarak oluşturulan kullanılmayan Docker image'ları ayrıca Docker üzerinden temizlenebilir.

EKS üzerindeki application workload'larını kaldırmak, EKS cluster'ını veya AWS altyapısını otomatik olarak silmez. Cluster ve altyapı temizliği ayrı olarak yönetilmelidir.

## Ortam Sınırlamaları

AWS EKS case ortamı tek adet `t3.small` worker node ile çalıştırılmaktadır. Free Tier kaynak sınırları nedeniyle sistem bileşenleri ve uygulama workload'ları aynı node üzerinde çalışmaktadır.

Bu kaynak kısıtı nedeniyle uygulama workload'larının replica sayısı tüm ortamlarda `1` olarak tutulmakta ve resource request değerleri düşük tutulmaktadır. Daha yüksek kapasite, birden fazla worker node ve uygun yüksek erişilebilirlik yapılandırması gerçek production ortamlarında tercih edilmelidir.

## Dokümantasyon ve Kanıtlar

Mimari:

`docs/architecture.md`

Başlangıç bulguları:

`docs/findings.md`

Backup/restore runbook:

`docs/backup-restore.md`

Case sonu cevapları:

`CASE_SONU_CEVAPLARI.md`

Çalışma kanıtları:

`TESLIM_KANITLARI.md`

İngilizce teslim kanıtları:

`SUBMISSION_EVIDENCE.md`

Ekran görüntüleri:

`docs/screenshots/`

Ana case dokümanı:

`DevOps_Teknik_Case_TR.docx`
