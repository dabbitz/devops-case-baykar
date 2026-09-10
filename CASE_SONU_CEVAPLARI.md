# CASE SONU CEVAPLARI

## Aday Bilgileri

* **Ad Soyad:** Tunahan Değirmencioğlu
* **Repository adresi:** `https://github.com/dabbitz/devops-case-baykar.git`
* **Çalışmanın tamamlandığı tarih:** 10.09.2026
* **Kullanılan hedef ortam:** Yerel Kubernetes (Docker Desktop Kubernetes)

---

## 1. Mimari ve İstek Akışı

Sistem; React + NGINX frontend, Node.js/Express backend, Python ETL ve MongoDB Atlas bileşenlerinden oluşmaktadır. Kubernetes üzerinde frontend ve backend Deployment olarak, ETL ise saatlik CronJob olarak çalıştırılmıştır. Dış HTTP erişimi Envoy Gateway ve HTTPRoute üzerinden sağlanmaktadır.

Bir kullanıcı isteğinin akışı şöyledir:

```text
Kullanıcı / Browser
        ↓
Envoy Gateway
        ↓
HTTPRoute
        ↓
frontend-service
        ↓
React + NGINX
        ↓
/api/*
        ↓
backend-service
        ↓
Node.js / Express
        ↓
MongoDB Atlas
```

Frontend içerisindeki NGINX, `/api/` isteklerini Kubernetes içindeki `backend-service:5050` adresine yönlendirmektedir. Backend ise record CRUD işlemlerini MongoDB Atlas üzerindeki `sample_training` database'i içerisinde gerçekleştirmektedir.

Python ETL bu akıştan bağımsız olarak GitHub API'den repository bilgisini almakta ve `github_id` üzerinden MongoDB'deki `github_repositories` collection'ına insert/update işlemi yapmaktadır.

Mimari diyagram `docs/architecture.md` dosyasında bulunmaktadır.

---

## 2. Kritik Bulgular ve Önceliklendirme

Başlangıç projesindeki en kritik üç sorun:

1. **Frontend API adresinin hardcoded olması**

   * Frontend doğrudan `http://localhost:5050` adresine bağımlıydı.
   * Container ve Kubernetes ortamında farklı endpoint kullanımı nedeniyle deployment esnekliğini engelliyordu.
   * Konfigürasyon üzerinden yönetilecek şekilde düzeltildi.

2. **Backend tarafında yetersiz input validation ve ObjectId kontrolü**

   * Geçersiz veya eksik alanlar doğrudan database katmanına ulaşabiliyordu.
   * ObjectId doğrulamasındaki hata hatalı isteklerin yanlış değerlendirilmesine neden olabiliyordu.
   * Server-side validation ve ObjectId kontrolü eklendi.

3. **Database bağlantı hatasının kontrollü ele alınmaması**

   * Başlangıçta MongoDB bağlantısı başarısız olsa bile uygulamanın çalışmaya devam etmesi mümkündü.
   * Bu durum servisin sağlıklı görünmesine rağmen database işlemlerinin başarısız olması riskini oluşturuyordu.
   * Backend bağlantısı fail-fast olacak şekilde düzenlendi.

Önceliklendirme; **production etkisi, güvenilirlik, deployment taşınabilirliği ve veri erişimi üzerindeki risk** kriterlerine göre yapıldı. Özellikle uygulamanın çalışıyor görünmesine rağmen veri katmanına erişememesi daha yüksek öncelikli değerlendirildi.

Detaylar `docs/findings.md` içerisinde bulunmaktadır.

---

## 3. Kapsam Dışında Bırakılan Konular

Aşağıdaki konular mevcut case kapsamında uygulanmadı veya production tasarımı seviyesinde bırakıldı:

* Terraform veya başka bir tam IaC çözümü kullanılmadı. Case'in mevcut kapsamı için Kubernetes manifestleri yeterli görüldü.
* Uygulamanın Helm chart'ı oluşturulmadı. Manifest tabanlı deployment daha küçük kapsam ve daha az ek karmaşıklık sağladığı için tercih edildi.
* Prometheus/Grafana gibi tam kapsamlı monitoring stack'i kurulmadı.
* HPA, PDB ve gelişmiş autoscaling politikaları uygulanmadı.
* GitOps, canary veya blue/green deployment uygulanmadı.
* Production seviyesinde otomatik, off-site ve uzun süreli backup storage kurulmadı.
* MongoDB cluster'ı Kubernetes StatefulSet olarak deploy edilmedi; production kalıcı veri katmanı olarak MongoDB Atlas kullanıldı.

Bu kararların temel nedeni case kapsamında gerekli olan ana DevOps fonksiyonlarını çalışır ve doğrulanabilir şekilde tamamlamak, gereksiz operasyonel karmaşıklık eklememektir.

---

## 4. Hedef Ortam Seçimi

Geliştirme ve doğrulama ortamı olarak **Docker Desktop üzerindeki yerel Kubernetes** kullanılmıştır. Bu seçim; Kubernetes manifestlerinin, Service/Deployment/CronJob yapılandırmalarının, Envoy Gateway erişiminin ve container security ayarlarının gerçek Kubernetes ortamında kolayca test edilebilmesini sağladı.

Ayrıca CI/CD pipeline'ında deployment doğrulaması için GitHub Actions üzerinde geçici bir **Kind Kubernetes cluster** oluşturulmaktadır. Böylece deployment adımları yalnızca geliştirici makinesine bağlı kalmadan CI ortamında da doğrulanmaktadır.

Gerçek production ortamında:

* Cloud veya Linux VM tabanlı kalıcı bir Kubernetes cluster'ı,
* Kalıcı ve erişilebilir ingress/gateway altyapısı,
* Managed MongoDB / MongoDB Atlas,
* TLS ve domain yönetimi,
* Merkezi secret management,
* Monitoring ve alerting platformu,
* Kalıcı container registry,
* Otomatik backup ve off-site retention

kullanırdım.

Mevcut GitHub Actions deployment'ı geçici Kind cluster'ında doğrulama amaçlıdır; production'daki kalıcı Kubernetes cluster'ının yerini tutmamaktadır.

---

## 5. MongoDB Yaklaşımı

Normal uygulama deployment'ında MongoDB **MongoDB Atlas** üzerinde tutulmuştur. Böylece database'in Kubernetes workload'larından ayrılması ve persistent database operasyonlarının managed bir servis tarafından yürütülmesi sağlanmıştır.

Bu seçim için değerlendirilen başlıca alternatifler:

| Yaklaşım                     | Avantaj                                                                  | Dezavantaj                                                               |
| ---------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| MongoDB Atlas                | Managed backup, operasyon ve persistent storage; Kubernetes'ten bağımsız | External network dependency ve erişim/allowlist yönetimi gerekir         |
| Kubernetes StatefulSet + PVC | Cluster içinde tam kontrol ve Kubernetes-native yapı                     | Storage, backup, replication ve database operasyonları kullanıcıya kalır |
| Geçici MongoDB Deployment    | CI/test için basit                                                       | Persistent data ve production kullanımı için uygun değil                 |

Bu nedenle production benzeri normal çalışma için Atlas, CI/CD ortamında ise dış IP allowlist probleminden kaçınmak amacıyla geçici bir MongoDB Deployment seçilmiştir.

CI/CD'deki `k8s/ci-mongodb.yaml` yalnızca ephemeral test ortamı içindir.

---

## 6. Helm veya Manifest Yönetimi

Uygulamanın kendi Kubernetes workload'ları düz manifest dosyaları ile yönetilmiştir.

Örneğin:

```text
k8s/
├── namespace.yaml
├── backend-deployment.yaml
├── backend-service.yaml
├── frontend-deployment.yaml
├── frontend-service.yaml
├── etl-cronjob.yaml
└── ci-mongodb.yaml
```

Bu case için düz manifest tercih edilmesinin nedeni workload sayısının düşük olması ve chart templating gerektirecek kadar çok environment/variant bulunmamasıdır.

Helm ise **Envoy Gateway kurulumu** için kullanılmıştır. Böylece hazır ve kompleks bir third-party Kubernetes bileşeni manuel olarak çok sayıda resource ile kurulmak yerine resmi Helm chart üzerinden kurulmuştur.

Helm'in avantajı reusable paketleme, versioning ve dependency yönetimidir. Dezavantajı ise küçük ve sabit bir uygulama için ek templating ve configuration karmaşıklığı oluşturabilmesidir.

Bu nedenle:

* **Kendi uygulamam:** düz manifest
* **Third-party Gateway:** Helm

yaklaşımı kullanılmıştır.

---

## 7. Kubernetes Service Tipleri

Uygulamadaki frontend ve backend Service'leri `ClusterIP` olarak tanımlanmıştır.

### Backend

`backend-service`:

```text
type: ClusterIP
port: 5050
```

Backend'in doğrudan cluster dışından erişilebilir olması gerekmemektedir. Frontend backend'e Kubernetes iç ağından erişmektedir.

### Frontend

`frontend-service`:

```text
type: ClusterIP
port: 80
```

Frontend'in de doğrudan NodePort veya LoadBalancer olarak açılması yerine dış HTTP trafiği Envoy Gateway üzerinden alınmaktadır.

### Dış erişim

Dış erişim:

```text
Internet / Browser
        ↓
Envoy Gateway
        ↓
HTTPRoute
        ↓
frontend-service
```

şeklindedir.

Bu nedenle NodePort ve LoadBalancer kullanılmayarak gereksiz doğrudan dış erişim azaltılmıştır.

MongoDB için Kubernetes Service kullanılmamıştır; normal deployment'ta MongoDB Atlas external managed service olarak kullanılmaktadır.

---

## 8. Kubernetes Workload Türleri

### Frontend

Frontend stateless bir web workload'udur. Kullanıcı verisi Pod filesystem'inde tutulmadığı için `Deployment` kullanılmıştır.

Avantajları:

* Replica artırılabilir.
* Pod yeniden oluşturulduğunda veri kaybı beklenmez.
* Rolling update desteklenir.

### Backend

Backend de stateless REST API olduğu için `Deployment` kullanılmıştır.

Backend'in kalıcı verisi container içerisinde değil MongoDB'de tutulmaktadır.

### MongoDB

Normal uygulama deployment'ında MongoDB Kubernetes üzerinde çalıştırılmamıştır. MongoDB Atlas kullanıldığı için StatefulSet ve PVC yönetimi uygulama cluster'ından ayrılmıştır.

CI/CD pipeline'ında kullanılan MongoDB ise sadece geçici test ortamıdır ve persistent production data taşımamaktadır.

### ETL

ETL periyodik çalışan bir iş olduğu için `CronJob` kullanılmıştır:

```text
0 * * * *
```

Bu yapı ETL'nin her saat başında çalışmasını sağlar.

ETL için Deployment kullanmak sürekli çalışan bir Pod gerektireceği için gereksiz kaynak kullanımı oluştururdu. CronJob ayrıca başarısız çalışmalarda Kubernetes'in Job retry mekanizmasını kullanmasına olanak sağlar.

Ek olarak:

```text
concurrencyPolicy: Forbid
backoffLimit: 2
restartPolicy: Never
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 3
```

ayarları kullanılmıştır.

---

## 9. Konfigürasyon ve Secret Yönetimi

Hassas bilgiler source code içerisinde hardcode edilmemiştir.

Örnek bilgiler:

* MongoDB URI
* GitHub API token

Kubernetes deployment'ında Secret kaynakları kullanılmıştır. Hassas olmayan konfigürasyonlar environment variable olarak sağlanmaktadır.

Örneğin backend için:

```text
ATLAS_URI
ALLOWED_ORIGIN
```

ETL için:

```text
GITHUB_TOKEN
MONGODB_URI
```

gibi değerler kullanılmaktadır.

Bir secret değiştirildiğinde, environment variable olarak Pod'a enjekte edilmiş eski değer çalışan process içerisinde otomatik olarak değişmez. Bu nedenle güvenli uygulama yöntemi secret'ın güncellenmesi ve ilgili Deployment/CronJob workload'larının yeni Pod ile yeniden başlatılmasıdır.

Production ortamında secret rotation için merkezi secret management çözümü ve kontrollü rollout tercih edilebilir.

---

## 10. MongoDB Erişim Problemi

Mevcut backend uygulamasında MongoDB bağlantısı startup sırasında kurulmaktadır. Bağlantı başarısız olursa uygulama fail-fast davranarak process'i sonlandırmaktadır.

Bu yaklaşım sayesinde database olmadan sağlıksız bir backend'in çalışıyor görünmesi engellenmektedir.

Mevcut sistemde `/healthcheck/` endpoint'i process'in HTTP olarak cevap verdiğini kontrol etmektedir. Ancak şu anda MongoDB dependency'sini doğrudan doğrulayan ayrı readiness/liveness probe tanımı bulunmamaktadır.

Production ortamında:

* **Liveness probe:** process'in çalıştığını kontrol eder.
* **Readiness probe:** backend'in MongoDB dahil gerekli dependency'lere erişebildiğini kontrol eder.

şeklinde ayrıştırırdım.

MongoDB erişimi kaybolduğunda readiness başarısız olacak şekilde tasarlanırsa Kubernetes yeni kullanıcı trafiğini sağlıksız Pod'a yönlendirmemeye yardımcı olabilir. Database işlemleri ise kontrollü HTTP hataları ve uygulama logları ile izlenmelidir.

Bu case'te mevcut healthcheck endpoint'i CI/CD sırasında backend'in erişilebilirliğini doğrulamak amacıyla kullanılmıştır.

---

## 11. Hatalı Deployment ve Rollback

Hatalı deployment tespitinde ilk olarak:

```text
kubectl get pods -n devops-case
kubectl describe pod <pod> -n devops-case
kubectl logs <pod> -n devops-case
kubectl get events -n devops-case
```

komutları ile Pod durumu, container logları ve Kubernetes event'leri incelenir.

Deployment rollout durumu:

```text
kubectl rollout status deployment/backend -n devops-case
kubectl rollout status deployment/frontend -n devops-case
```

ile kontrol edilir.

Hatalı bir sürümde önceki çalışan ReplicaSet'e dönmek için:

```text
kubectl rollout undo deployment/backend -n devops-case
```

veya frontend için aynı yöntem kullanılabilir.

Rollback sonrasında:

```text
kubectl rollout status deployment/backend -n devops-case
```

ile rollout doğrulanır ve ardından backend healthcheck ile frontend endpoint tekrar test edilir.

CI/CD pipeline'ında deployment job'ının healthcheck aşaması başarısız olursa pipeline başarısız olarak sonuçlanmaktadır.

---

## 12. Ölçeklenebilirlik ve Darboğazlar

Trafiğin 10 kat artması durumunda ilk darboğaz olarak backend kaynak kullanımı ve ardından MongoDB bağlantıları/database kapasitesini beklerim.

Öncelikle şu metrikleri değerlendirirdim:

* CPU kullanımı
* Memory kullanımı
* HTTP request rate
* Response latency
* HTTP error rate
* MongoDB connection usage
* MongoDB query latency

Backend stateless olduğu için replica sayısı artırılarak yatay ölçekleme yapılabilir.

Production ortamında örneğin CPU ve memory utilization belirli bir seviyenin üzerinde sürekli seyrediyorsa HPA uygulanabilir. Ancak yalnızca CPU'ya göre ölçeklemek yerine request rate ve latency gibi uygulama metrikleri de değerlendirilmelidir.

Frontend de stateless olduğundan benzer şekilde replica artırılabilir.

MongoDB tarafında ise yalnızca application replica sayısını artırmak yeterli değildir. Artan replica sayısının oluşturacağı database connection yükü, query performansı ve database kapasitesi ayrıca değerlendirilmelidir.

Bu nedenle ölçeklendirme kararı application ve database metrikleri birlikte incelenerek verilmelidir.

---

## 13. Logging, Monitoring ve Alarm Yönetimi

Backend ve ETL tarafında operasyonel olarak anlamlı loglar bulunmaktadır.

Backend örnekleri:

```text
Connecting to MongoDB Atlas...
Server listening on port 5050
Database connection failed...
```

ETL örnekleri:

```text
Fetching repository
Github repository received
Connecting to MongoDB
MongoDB connection successful
UPDATE: repository updated
MongoDB document count
ETL completed successfully
```

Kubernetes CronJob logları ETL'nin hangi aşamada olduğunu ve başarılı/başarısız durumunu takip etmek için kullanılmaktadır.

Ayrıca `scripts/check-alerts.ps1` içerisinde iki kritik alarm kontrolü bulunmaktadır:

* **ALERT-001:** ETL başarısızlığı veya beklenen zaman aralığında başarılı ETL çalışmasının bulunmaması
* **ALERT-002:** Frontend veya backend health endpoint'lerinin erişilememesi

Script'in test modu ile iki alarm da bilinçli olarak tetiklenerek doğrulanmıştır.

Incident sırasında ilk olarak:

```text
1. Alert sonucu
2. Kubernetes Pod / Job durumu
3. ETL veya backend logları
4. Deployment rollout durumu
5. Backend healthcheck
6. Frontend endpoint
```

incelenir.

Daha gelişmiş production ortamında Prometheus/Grafana, merkezi log toplama ve gerçek notification kanalları eklenebilir.

---

## 14. Güvenlik Riskleri

### 1. Secret / credential exposure

MongoDB URI ve GitHub API token gibi hassas bilgilerin source code veya image içerisine girmesi ciddi risk oluşturur.

Kontrol olarak:

* Secret bilgileri environment variable / Kubernetes Secret üzerinden sağlanmıştır.
* `.env` ve benzeri secret dosyaları `.gitignore` içerisine alınmıştır.
* Docker image'larına secret değerleri yazılmamıştır.

Production'da merkezi secret management çözümü kullanılabilir.

### 2. Container'ların root olarak çalışması

Root container ele geçirilmesi durumunda container içerisindeki saldırı etkisini artırabilir.

Bu nedenle workload'larda:

```yaml
runAsNonRoot: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
```

kullanılmıştır.

Container kullanıcıları:

```text
Backend  → node / UID 1000
Frontend → nginx / UID 101
ETL      → appuser / UID 10001
```

olarak doğrulanmıştır.

### 3. Gereksiz dış ağ erişimi

Backend'in doğrudan dışarıya NodePort veya LoadBalancer olarak açılması saldırı yüzeyini artırabilir.

Bu nedenle frontend ve backend Service'leri `ClusterIP` olarak kullanılmış, dış erişim Envoy Gateway üzerinden sınırlandırılmıştır.

---

## 15. Python ETL Güncelleme Yaklaşımı

ETL, GitHub repository ID'sini benzersiz kayıt anahtarı olarak kullanmaktadır.

Kullanılan alan:

```text
github_id
```

Örneğin repository'nin ID'si:

```text
1361100555
```

şeklindedir.

Aynı repository tekrar işlendiğinde yeni MongoDB document oluşturmak yerine mevcut kayıt `github_id` üzerinden güncellenmektedir.

Gerçek çalıştırmada:

```text
UPDATE: repository updated (github_id=1361100555)
MongoDB document count: 1
ETL completed successfully.
```

çıktısı alınmıştır.

Bu kanıt `docs/screenshots/13-etl-update-without-duplicate.png` dosyasında sunulmuştur.

---

## 16. Backup ve Restore Yaklaşımı

Backup için MongoDB Database Tools içerisindeki `mongodump` kullanılmıştır.

Backup:

```text
MongoDB Atlas
      ↓
mongodump
      ↓
backups/sample-training-backup
```

konumuna alınmıştır.

Backup senaryosunda `sample_training` database'inin tamamı yedeklenmiştir.

Gerçek testte:

```text
sample_training.records               → 1 document
sample_training.github_repositories   → 1 document
Toplam                                → 2 documents
```

yedeklenmiştir.

Daha sonra database silinmiş, hem web arayüzünde hem MongoDB Atlas üzerinde verinin kaybolduğu doğrulanmış ve `mongorestore` ile geri yükleme gerçekleştirilmiştir.

Restore sonucu:

```text
2 document(s) restored successfully.
0 document(s) failed to restore.
```

olarak doğrulanmıştır.

Ölçülen restore komut süresi yaklaşık:

```text
1.3 saniye
```

olmuştur.

Bu süre yalnızca restore komutunun çalışma süresidir; production uçtan uca RTO olarak değerlendirilmemiştir.

### RPO / Retention

Mevcut case çözümünde backup manuel olarak alınmaktadır ve otomatik retention veya off-site backup storage uygulanmamıştır.

Production hedefi olarak en fazla **24 saatlik veri kaybı** kabul edilecek şekilde bir RPO hedeflenebilir. Ancak mevcut manuel yöntem bu RPO'yu garanti etmemektedir.

Retention süresi de mevcut uygulamada otomatik olarak uygulanmamaktadır.

### Backup doğrulaması

Backup'ın kullanılabilirliğini yalnızca dosyanın oluşmasına bakarak değerlendirmem.

Doğrulama için:

1. `mongodump` çıktısı ve document count kontrol edilir.
2. Restore işlemi temiz bir target üzerinde test edilir.
3. `mongorestore` sonucu ve hata sayısı kontrol edilir.
4. Collection ve document count doğrulanır.
5. Uygulama üzerinden verinin tekrar okunabildiği doğrulanır.

Bu case kapsamında bu adımlar gerçek MongoDB Atlas verisi üzerinde gerçekleştirilmiştir.

### Production yaklaşımı

Production ortamında:

* Managed MongoDB backup/snapshot,
* Encrypted off-site/object storage,
* Otomatik retention policy,
* Access control,
* Periyodik restore testleri,
* Backup monitoring ve alerting

kullanırdım.

Ayrıntılı backup/restore runbook'u `docs/backup-restore.md` içerisindedir. Çalışma kanıtları `TESLIM_KANITLARI.md` içerisinde 17–25 numaralı ekran görüntüleri ile sunulmaktadır.

---

## Ek Notlar

Case kapsamında iki üst kriter özellikle uygulanmıştır.

İlk olarak, `scripts/check-alerts.ps1` ile iki kritik alarm senaryosu tanımlanmış ve test edilmiştir. Böylece yalnızca log üretmek yerine doğrulanabilir alarm senaryoları oluşturulmuştur.

İkinci olarak container ve Kubernetes güvenliği güçlendirilmiştir. Backend, frontend ve ETL container'ları non-root kullanıcılarla çalıştırılmış; privilege escalation kapatılmış ve tüm Linux capabilities drop edilmiştir.

CI/CD deployment aşamasında production database'e bağımlı kalmamak amacıyla geçici Kind cluster içerisinde ephemeral MongoDB kullanılmıştır. Böylece GitHub Actions runner IP'sinin MongoDB Atlas allowlist'inde bulunmaması gibi dış ağ bağımlılıkları deployment doğrulamasını engellememektedir.

Bu CI MongoDB yalnızca test/deployment validation amacıyla kullanılmakta, normal uygulama deployment'ındaki MongoDB Atlas veri katmanının yerini almamaktadır.
