# 2NTECH DevOps Teknik Case

Bu repository, 2NTECH DevOps Teknik Case kapsamında geliştirilen MERN uygulaması, Python ETL iş yükü, Docker container'ları, Kubernetes deployment'ları, AWS EKS ortamı, Amazon ECR, CI/CD pipeline'ı ve backup/restore çalışmalarını içermektedir.

## Proje Yapısı

```text
DevOps_Case_Final/
├── .github/
│   └── workflows/
│       └── ci.yml                    # GitHub Actions CI/CD pipeline
│
├── docs/
│   ├── screenshots/                  # Çalışma kanıtları
│   ├── architecture.md               # Sistem mimarisi ve istek akışı
│   ├── backup-restore.md             # Backup/restore runbook'u
│   └── findings.md                   # Uygulama ilk açıldığında bulunan hatalar
│
├── k8s/
│   ├── backend-deployment.yaml       # Local Kubernetes backend Deployment
│   ├── backend-service.yaml          # Local Kubernetes backend ClusterIP Service
│   ├── ci-mongodb.yaml               # CI/CD için geçici MongoDB
│   ├── etl-cronjob.yaml              # Local Kubernetes saatlik Python ETL CronJob
│   ├── frontend-deployment.yaml      # Local Kubernetes frontend Deployment
│   ├── frontend-service.yaml         # Local Kubernetes frontend ClusterIP Service
│   ├── gateway.yaml                  # Envoy Gateway
│   ├── gatewayclass.yaml             # Envoy GatewayClass
│   ├── http-route.yaml               # HTTPRoute
│   ├── namespace.yaml                # Local Kubernetes namespace
│   └── eks/
│       ├── backend-deployment.yaml   # EKS backend Deployment
│       ├── backend-service.yaml      # EKS backend ClusterIP Service
│       ├── cd-rbac.yaml              # GitHub Actions Kubernetes RBAC
│       ├── etl-cronjob.yaml          # EKS saatlik Python ETL CronJob
│       ├── frontend-deployment.yaml  # EKS frontend Deployment
│       ├── frontend-service.yaml     # EKS frontend ClusterIP Service
│       ├── gateway.yaml              # EKS Envoy Gateway
│       ├── gatewayclass.yaml         # EKS Envoy GatewayClass
│       └── http-route.yaml           # EKS HTTPRoute
│
├── mern-project/
│   ├── client/                       # React frontend
│   └── server/                       # Express.js backend
│
├── python-project/
│   ├── Dockerfile                    # ETL container image
│   ├── ETL.py                        # Güncel ETL implementation
│   ├── README.md                     # ETL başlangıç açıklamaları
│   └── requirements.txt              # Python bağımlılıkları
│
├── scripts/
│   └── check-alerts.ps1              # Kritik alarm kontrolleri
│
├── .gitignore
├── CASE_END_ANSWERS.md                # İngilizce case cevapları
├── CASE_SONU_CEVAPLARI.md             # Case sonu cevapları
├── DevOps_Technical_Case_EN.docx      # İngilizce case dokümanı
├── DevOps_Teknik_Case_TR.docx         # Türkçe case dokümanı
├── docker-compose.yml                # Local Docker Compose ortamı
├── eks-cluster.yaml                  # AWS EKS cluster ve node group yapılandırması
├── README_EN.md                        # İngilizce README
├── README.md                           # Proje ve çalıştırma dokümantasyonu
├── setup-k8s.ps1                     # Local Kubernetes kurulum/doğrulama script'i
├── SUBMISSION_EVIDENCE.md             # İngilizce teslim kanıtları
└── TESLIM_KANITLARI.md                # Çalışma kanıtları
```

## Mevcut AWS EKS Deployment

Projenin **bu çalışma sırasında kullanılan mevcut AWS EKS deployment'ına** aşağıdaki adresler üzerinden doğrudan erişilebilir:

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

> **Önemli:** Yukarıdaki adresler, bu çalışma sırasında oluşturulmuş olan mevcut AWS Load Balancer'a aittir. Bu adresler **kalıcı bir production URL'si olarak değerlendirilmemelidir**. Özellikle EKS cluster'ı, Envoy Gateway veya Load Balancer yeniden oluşturulursa AWS yeni bir hostname atayabilir. Ayrıca teslim sonrasında kullanılan AWS kaynaklarının kaldırılması durumunda yukarıdaki adreslere erişim mümkün olmayabilir.

### Güncel EKS erişim adresini bulma

AWS Load Balancer tarafından verilen güncel hostname'i Kubernetes üzerinden terminal çıktısından öğrenebilirsiniz.

Öncelikle Envoy Gateway Service'lerini görüntüleyin:

```powershell
kubectl get svc -n envoy-gateway-system
```

Çıktıda `TYPE` değeri `LoadBalancer` olan Envoy Gateway Service'ini bulun. Bu satırdaki `EXTERNAL-IP` alanı, AWS tarafından atanmış güncel Load Balancer hostname'idir.

Örneğin:

```text
NAME                                      TYPE           CLUSTER-IP      EXTERNAL-IP
envoy-devops-case-devops-gateway-...     LoadBalancer   10.x.x.x        <AWS Load Balancer hostname>
```

Güncel hostname'i daha ayrıntılı görmek için:

```powershell
kubectl get svc -n envoy-gateway-system -o wide
```

Buradaki `<AWS Load Balancer hostname>` değeri kullanılarak erişim adresleri aşağıdaki biçimde oluşturulur:

```text
http://<EXTERNAL-IP>/
http://<EXTERNAL-IP>/records
http://<EXTERNAL-IP>/api/healthcheck
```

Dolayısıyla README'deki mevcut hostname artık geçerli değilse, yeni adresi yeniden README'ye eklemek yerine öncelikle Kubernetes Service üzerinden güncel `EXTERNAL-IP` değeri kontrol edilmelidir.


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

Python ETL ayrı bir iş akışı olarak GitHub API'den repository bilgisini alarak MongoDB'deki `github_repositories` collection'ını günceller:

```text
GitHub API
    ↓
Python ETL
    ↓
MongoDB Atlas
```

Local Kubernetes ortamında AWS Elastic Load Balancer yerine local Envoy Gateway üzerinden erişim sağlanabilir.

Ayrıntılı mimari diyagram ve bileşen açıklamaları:

`docs/architecture.md`

## Teknolojiler

* React
* Node.js / Express
* MongoDB Atlas
* Python
* Docker / Docker Compose
* Kubernetes
* AWS EKS
* Amazon ECR
* AWS IAM
* GitHub Actions
* GitHub OIDC
* Kubernetes RBAC
* Envoy Gateway
* Helm
* Kind

## Gereksinimler

AWS üzerinde çalışan mevcut deployment'ı kullanmak için temel olarak:

* AWS hesabı ve gerekli yetkiler
* GitHub repository erişimi

gereklidir.

Local çalıştırma veya geliştirme için ayrıca:

* Docker Desktop
* Docker Compose
* Node.js 20+
* Python 3.10+
* `kubectl`
* Helm

kullanılabilir.

AWS EKS yönetimi ve infrastructure işlemleri için ayrıca:

* AWS CLI
* `eksctl`

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

## İlk Kurulum

Projenin ana deployment ortamı AWS EKS'dir. Repository'de AWS EKS cluster'ı, ECR image repository'leri ve GitHub Actions tabanlı CI/CD deployment yapısı tanımlanmıştır.

Mevcut cloud deployment için temel akış:

```text
Repository
        ↓
MongoDB Atlas hazırlanması
        ↓
GitHub Actions Secrets
        ↓
main branch'e push
        ↓
CI validation
        ↓
GitHub OIDC
        ↓
AWS IAM Role
        ↓
Amazon ECR
        ↓
AWS EKS
        ↓
Frontend / Backend / ETL
```

AWS EKS cluster yapılandırması:

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

EKS deployment'ında kullanılan manifestler:

```text
k8s/eks/
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

Cloud dış erişimi Envoy Gateway tarafından oluşturulan AWS Elastic Load Balancer üzerinden sağlanmaktadır.

Local geliştirme veya test gerektiğinde aşağıdaki local çalışma yöntemleri ayrıca kullanılabilir.

---

## Alternatif: Docker Compose

Kubernetes kullanmadan local container ortamını doğrulamak için:

```powershell
docker compose build
docker compose up -d
```

Ardından:

```text
Frontend:
http://localhost:3000

Backend:
http://localhost:5050/healthcheck/
```

ile kontrol edilebilir.

Compose ortamını kapatmak için:

```powershell
docker compose down
```

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

Tüm uygulama bileşenlerini container olarak çalıştırmak için proje kökünde:

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

## AWS EKS Deployment

AWS EKS'e özel Kubernetes manifestleri:

```text
k8s/eks/
```

altında bulunmaktadır.

EKS deployment'ında:

```text
Frontend → Deployment + ClusterIP Service
Backend  → Deployment + ClusterIP Service
ETL      → CronJob
Gateway  → Envoy Gateway
Routing  → HTTPRoute
```

şeklinde çalışmaktadır.

Container image'ları Amazon ECR'dan alınmaktadır.

EKS üzerinde çalışan workload'ları kontrol etmek için:

```powershell
kubectl get pods -n devops-case -o wide
kubectl get deployments -n devops-case
kubectl get services -n devops-case
kubectl get cronjobs -n devops-case
kubectl get gateway -n devops-case
kubectl get httproute -n devops-case
```

EKS dış erişiminde `/` istekleri frontend'e, `/api` istekleri backend'e yönlendirilir.

Backend healthcheck:

```text
/api/healthcheck
```

AWS Load Balancer üzerinden erişilebilir durumdadır.

## Kubernetes Workloads

Frontend:

```text
Deployment + ClusterIP Service
```

Backend:

```text
Deployment + ClusterIP Service
```

Python ETL:

```text
CronJob
```

ETL schedule:

```text
0 * * * *
```

ETL `Europe/Istanbul` timezone'u kullanarak saatlik çalışmaktadır.

ETL aynı repository tekrar işlendiğinde `github_id` alanını kullanarak mevcut kaydı günceller.

## Kubernetes Security

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

Secret değerleri repository source code'u veya Docker image içerisine gömülmemektedir.

## Python ETL

ETL, GitHub API'den repository bilgisini alarak MongoDB'ye aktarır.

Temel akış:

```text
GitHub API
    ↓
Python ETL
    ↓
MongoDB Atlas
```

Kubernetes üzerinde ETL saatlik olarak çalışmaktadır.

Aynı repository tekrar işlendiğinde:

```text
github_id = 1361100555
```

üzerinden mevcut document güncellenir ve duplicate kayıt oluşturulmaz.

ETL loglarında aşağıdaki gibi kayıtlar görülür:

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
CI başarılı
        ↓
GitHub OIDC
        ↓
AWS IAM Role
        ↓
Amazon ECR image push
        ↓
AWS EKS authentication
        ↓
Kubernetes deployment
        ↓
Rollout verification
        ↓
Backend healthcheck
        ↓
Frontend HTTP check
```

Pull Request açıldığında `validate-and-build` job'ı çalışır; deployment yapılmaz.

`main` branch'ine yapılan başarılı push sonrasında `deploy-eks` job'ı çalışır.

Deployment job'ı:

1. GitHub OIDC üzerinden AWS IAM Role'u assume eder.
2. Frontend, backend ve ETL Docker image'larını build eder.
3. Image'ları Git commit SHA ile tag'ler.
4. Image'ları Amazon ECR'a push eder.
5. EKS cluster'ı için kubeconfig oluşturur.
6. Kubernetes Secret kaynaklarını günceller.
7. `k8s/eks/` altındaki Service, Deployment ve CronJob kaynaklarını uygular.
8. Deployment image'larını commit SHA tag'lerine günceller.
9. Gateway ve HTTPRoute kaynaklarını uygular.
10. Backend ve frontend rollout durumlarını kontrol eder.
11. AWS Load Balancer üzerinden backend healthcheck gerçekleştirir.
12. Frontend dış erişimini doğrular.

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

IAM Role, GitHub repository ve `main` branch'i ile sınırlı OIDC trust policy kullanmaktadır.

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

MongoDB backup için `mongodump`, restore için `mongorestore` kullanılmıştır.

Backup konumu:

```text
backups/sample-training-backup/
```

Backup ve restore süreci gerçek veri üzerinde uçtan uca test edilmiştir.

Ayrıntılı komutlar, retention, RPO/RTO ve production sınırlamaları:

`docs/backup-restore.md`

Çalışma kanıtları:

`TESLIM_KANITLARI.md`

## Logging ve Alerts

Backend ve Python ETL tarafında operasyonel loglar kullanılmaktadır.

ETL logları repository bilgisi, MongoDB bağlantısı, update işlemi, document count ve başarılı tamamlanma durumlarını göstermektedir.

Ayrıca:

```text
scripts/check-alerts.ps1
```

script'i iki kritik alarm senaryosunu kontrol etmektedir:

* ETL başarısızlığı veya beklenen sürede başarılı ETL çalışmasının bulunmaması
* Frontend veya backend health endpoint'lerinin erişilememesi

Test modu ile alarm senaryoları doğrulanabilmektedir.

## Bulgular ve İyileştirmeler

Başlangıç uygulamasındaki production-readiness sorunları:

`docs/findings.md`

dosyasında açıklanmıştır.

Başlıca iyileştirmeler:

* Frontend API adresinin environment/config üzerinden yönetilmesi
* Backend input validation
* ObjectId validation
* Database connection error handling
* CORS restriction
* HTTP error handling
* Non-root container kullanımı
* Kubernetes securityContext
* ETL duplicate prevention
* CI/CD validation ve deployment kontrolü
* AWS EKS deployment
* Amazon ECR image management
* GitHub OIDC authentication
* Namespace-scoped Kubernetes RBAC

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

