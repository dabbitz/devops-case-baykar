# 2NTECH DevOps Teknik Case

Bu repository, 2NTECH DevOps Teknik Case kapsamında geliştirilen MERN uygulaması, Python ETL iş yükü, Docker container'ları, Kubernetes deployment'ı, CI/CD pipeline'ı ve backup/restore çalışmalarını içermektedir.

## Proje Yapısı

```text
DevOps_Case_Final/
├── .github/
│   └── workflows/
│       └── ci.yml                    # GitHub Actions CI/CD pipeline
│
├── backups/                          # Yerel backup çıktıları
│
├── docs/
│   ├── screenshots/                  # Çalışma kanıtları
│   ├── architecture.md               # Sistem mimarisi ve istek akışı
│   ├── backup-restore.md             # Backup/restore runbook'u
│   └── findings.md                   # Uygulama ilk açıldığında bulunan hatalar
│
├── k8s/
│   ├── namespace.yaml                # Kubernetes namespace
│   ├── backend-deployment.yaml       # Backend Deployment
│   ├── backend-service.yaml          # Backend ClusterIP Service
│   ├── frontend-deployment.yaml      # Frontend Deployment
│   ├── frontend-service.yaml         # Frontend ClusterIP Service
│   ├── etl-cronjob.yaml              # Saatlik Python ETL CronJob
│   ├── ci-mongodb.yaml               # CI/CD için geçici MongoDB
│   ├── gatewayclass.yaml             # Envoy GatewayClass
│   ├── gateway.yaml                  # Envoy Gateway
│   └── http-route.yaml               # HTTPRoute
│
├── mern-project/
│   ├── client/                       # React frontend
│   └── server/                       # Express.js backend
│
├── python-project/
│   ├── Dockerfile                    # ETL container image
│   ├── ETL.py                        # Güncel ETL implementation
│   ├── requirements.txt              # Python bağımlılıkları
│   └── README.md                     # ETL başlangıç açıklamaları
│
├── scripts/
│   └── check-alerts.ps1              # Kritik alarm kontrolleri
│
├── .env                              # Yerel environment/config
├── .gitignore
├── docker-compose.yml                # Local Docker Compose ortamı
├── setup-k8s.ps1                     # Kubernetes kurulum/doğrulama script'i
├── CASE_SONU_CEVAPLARI.md            # Case sonu cevapları
├── CASE_END_ANSWERS.md               # İngilizce case cevapları
├── TESLIM_KANITLARI.md               # Çalışma kanıtları
├── SUBMISSION_EVIDENCE.md            # İngilizce teslim kanıtları
├── DevOps_Teknik_Case_TR.docx        # Türkçe case dokümanı
├── DevOps_Technical_Case_EN.docx     # İngilizce case dokümanı
├── README.md                         # Proje ve çalıştırma dokümantasyonu
└── README_EN.md                      # İngilizce README
```

## Sistem Mimarisi

Uygulama aşağıdaki temel bileşenlerden oluşmaktadır:

```text
Kullanıcı / Browser
        ↓
Envoy Gateway
        ↓
HTTPRoute
        ↓
Frontend Service
        ↓
React + NGINX
        ↓
Backend Service
        ↓
Node.js + Express
        ↓
MongoDB Atlas
```

Python ETL ise GitHub API'den repository bilgisini alarak MongoDB'deki `github_repositories` collection'ını günceller.

Ayrıntılı mimari diyagram ve bileşen açıklamaları:

`docs/architecture.md`

## Teknolojiler

* React
* Node.js / Express
* MongoDB Atlas
* Python
* Docker / Docker Compose
* Kubernetes
* Envoy Gateway
* Helm
* GitHub Actions
* Kind

## Gereksinimler

Yerel çalıştırma için aşağıdaki araçların kurulu olması gerekir:

* Docker Desktop
* Docker Compose
* Node.js 20+
* Python 3.10+
* `kubectl`
* Helm

Kubernetes çalıştırılacaksa Docker Desktop Kubernetes veya uygun bir Kubernetes cluster'ı kullanılabilir.

## Konfigürasyon

Secret veya bağlantı bilgileri source code içerisinde hardcode edilmemiştir.

Repository klonlandıktan sonra çalıştırma ortamına ait bazı değerlerin kullanıcı tarafından hazırlanması gerekir. Bu değerler özellikle MongoDB Atlas ve GitHub API erişimi için gereklidir.

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

Proje kökünde `.env` adlı bir dosya oluşturun.

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

`setup-k8s.ps1` script'i `.env` içerisindeki hassas değerleri okuyarak gerekli Kubernetes Secret kaynaklarını oluşturur.

Bu nedenle Kubernetes deployment'ından önce `.env` dosyasının hazırlanmış olması gerekir.

Script secret değerlerini ekrana yazdırmadan kullanacak şekilde tasarlanmıştır.

---

## İlk Kurulum

Repository klonlandıktan sonra önerilen sıra şöyledir:

```text
Repository'yi klonla
        ↓
Gerekli araçları kur
        ↓
MongoDB Atlas'ı hazırla
        ↓
GitHub API token oluştur
        ↓
.env dosyasını oluştur
        ↓
Docker Desktop Kubernetes'i etkinleştir
        ↓
setup-k8s.ps1 çalıştır
        ↓
Kubernetes workload'larını doğrula
        ↓
Frontend / backend endpoint'lerini test et
        ↓
ETL Job / CronJob loglarını kontrol et
```

Kubernetes kurulumu için:

```powershell
.\setup-k8s.ps1
```

Kurulum tamamlandıktan sonra:

```powershell
kubectl get pods -n devops-case
kubectl get services -n devops-case
kubectl get cronjobs -n devops-case
```

ile workload durumu kontrol edilebilir.

Frontend:

```text
http://localhost/
```

Backend healthcheck:

```text
http://localhost/api/healthcheck/
```

### Alternatif: Docker Compose

Kubernetes kullanmadan önce local container ortamını doğrulamak için:

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

Kubernetes manifestleri `k8s/` klasöründe bulunmaktadır.

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
MongoDB
```

Kubernetes üzerinde ETL saatlik olarak çalışmaktadır.

Aynı repository tekrar işlendiğinde:

```text
github_id = 1361100555
```

üzerinden mevcut document güncellenir ve duplicate kayıt oluşturulmaz.

ETL loglarında aşağıdaki gibi bir kayıt görülür:

```text
UPDATE: repository updated
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
Kind Kubernetes cluster
        ↓
Image load
        ↓
Kubernetes deployment
        ↓
Rollout verification
        ↓
Backend healthcheck
        ↓
Frontend HTTP check
```

Deployment job'ı yalnızca CI başarıyla tamamlandığında çalışır.

CI deployment doğrulaması için GitHub Actions üzerinde geçici bir Kind cluster oluşturur. Bu ortamda test amacıyla geçici bir MongoDB container'ı da çalıştırılır.

Bu MongoDB yalnızca CI/CD doğrulaması içindir. Normal uygulama deployment'ında kullanılan veri katmanı MongoDB Atlas'tır.

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

## Temizlik

Kubernetes workload'larını kaldırmak için:

```powershell
kubectl delete namespace devops-case
```

Docker Compose ortamını kapatmak için:

```powershell
docker compose down
```

Yerel olarak oluşturulan kullanılmayan Docker image'ları ayrıca Docker üzerinden temizlenebilir.

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

Ekran görüntüleri:

`docs/screenshots/`

Ana case dokümanı:

`DevOps_Teknik_Case_TR.docx`
