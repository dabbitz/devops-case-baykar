# CASE SONU CEVAPLARI

Bu dosyada aşağıdaki soruların tamamını, yaptığınız çalışma ile doğrudan ilişkilendirerek cevaplayın.

Cevaplarınızın kısa, somut ve teknik kararlarınızı açıklayacak düzeyde olması beklenmektedir. Gerekli gördüğünüz yerlerde ilgili kaynak koduna, manifest dosyasına, pipeline adımına veya dokümana dosya yolu vererek referans verebilirsiniz. Çalışma kanıtları ve ekran görüntüleri ayrıca `TESLIM_KANITLARI.md` dosyasında sunulmalıdır.

---

## Aday Bilgileri

- **Ad Soyad:** Tunahan Değirmencioğlu
- **Repository adresi:** `https://github.com/dabbitz/devops-case-baykar.git`
- **Çalışmanın tamamlandığı tarih:** 13.09.2026
- **Kullanılan hedef ortam:** AWS EKS (`devops-case-eks`, `eu-central-1`)

---

## 1. Mimari ve İstek Akışı

Kurduğunuz mimariyi ve bir kullanıcı isteğinin frontend’den başlayarak backend ve veritabanına kadar izlediği yolu açıklayın.

Ayrıca sistem bileşenlerini, bileşenler arasındaki bağlantıları, trafik akışını ve dış erişim noktalarını gösteren bir mimari diyagram hazırlayarak proje reposuna aşağıdaki dosyalardan biri olarak ekleyin:

- `docs/architecture.md`
- `docs/architecture.pdf`

Diyagram Mermaid, Draw.io, Excalidraw veya benzeri bir araçla hazırlanabilir. Düzenlenebilir kaynak dosyasının da repoya eklenmesi beklenmektedir.

**Cevap:**

Ana deployment AWS EKS üzerinde çalışmaktadır. Frontend ve backend `Deployment + ClusterIP Service`, Python ETL ise saatlik `CronJob` olarak çalışır.

```text
User / Browser
      ↓
AWS Load Balancer
      ↓
Envoy Gateway
      ↓
HTTPRoute
   ┌──┴────┐
   ↓       ↓
Frontend Backend
Service  Service
   ↓       ↓
React   Node.js
+ NGINX + Express
           ↓
      MongoDB Atlas
```

Frontend NGINX `/api/` isteklerini backend'e yönlendirecek şekilde yapılandırılmıştır. EKS ortamında dış `/api` trafiği ise Envoy Gateway ve HTTPRoute üzerinden backend Service'e yönlendirilir.

ETL ayrı bir iş akışı olarak GitHub API'den repository bilgilerini alır ve `github_id` üzerinden `github_repositories` collection'ındaki kaydı upsert eder.

Ayrıca, MongoDB Atlas verileri günlük `mongodb-backup` Kubernetes CronJob ile `mongodump` kullanılarak yedeklenir ve Amazon S3 üzerinde cluster dışında saklanır.

Ayrıntılı mimari: `docs/architecture.md`

---

## 2. Kritik Bulgular ve Önceliklendirme

Başlangıç projelerinde tespit ettiğiniz en kritik üç sorun neydi? Bu sorunları hangi etki ve risk kriterlerine göre önceliklendirdiniz?

**Cevap:**

Öncelikli üç sorun:

1. **Frontend API adresinin hardcoded olması:** Localhost bağımlılığı deployment taşınabilirliğini azaltıyordu. API adresi configuration/environment üzerinden yönetilecek şekilde düzeltildi.
2. **Input validation ve ObjectId kontrolü:** Geçersiz isteklerin database katmanına ulaşmasını engellemek için server-side validation ve ObjectId kontrolü eklendi.
3. **MongoDB bağlantı hatasının kontrollü ele alınmaması:** Backend MongoDB bağlantısında fail-fast davranacak şekilde düzenlendi.

Önceliklendirmede production etkisi, güvenilirlik, güvenlik, deployment taşınabilirliği ve veri erişimi üzerindeki riskler dikkate alındı.

Ayrıntılar: `docs/findings.md`

---

## 3. Kapsam Dışında Bırakılan Konular

Hangi sorunları bilinçli olarak düzeltmediniz veya kapsam dışında bıraktınız? Bu kararların gerekçelerini açıklayın.

**Cevap:**

Temel case gereksinimleri ve seçilen üst kriterler (2, 3, 4, 5, 6, 7) tamamlanmıştır. **Birinci üst kriter olan tam Infrastructure as Code yaklaşımı ise bu case kapsamında uygulanmamıştır; EKS altyapısı mevcut declarative yapılandırma ve AWS/EKS araçlarıyla yönetilmiş, ancak Terraform/OpenTofu tabanlı tam IaC çözümü geliştirilmemiştir.**

Bunun dışında aşağıdaki ileri seviye production özellikleri uygulanmamıştır. Bu özelliklerin sağladığı ihtiyaçlar, case'in mevcut ölçeği ve gereksinimleri doğrultusunda daha basit ve uygun yaklaşımlarla karşılanmıştır:

- **Prometheus/Grafana tabanlı merkezi monitoring:** Merkezi monitoring kurulmamış, bunun yerine ETL ve healthcheck kontrollerine dayalı doğrulanabilir alarm senaryoları uygulanmıştır.
- **HPA/PDB ve çoklu node yüksek erişilebilirlik:** Mevcut tek node'lu kaynak yapısı korunmuş; deployment dayanıklılığı kontrollü `RollingUpdate`, readiness/liveness probe'ları ve resource yönetimi ile sağlanmıştır.
- **GitOps tabanlı deployment:** Argo CD/Flux gibi bir GitOps controller kullanılmamış; production release kontrolü GitHub Actions, Kustomize ve manuel approval mekanizması ile sağlanmıştır.
- **Canary / blue-green deployment:** Bu release modelleri yerine kontrollü `RollingUpdate` kullanılmıştır.
- **PITR ve otomatik restore verification:** Günlük otomatik S3 backup ve ayrıca manuel uçtan uca restore testi uygulanarak backup ve geri yüklenebilirlik doğrulanmıştır.
- **S3 Lifecycle tabanlı otomatik retention:** Formal retention politikası tanımlanmamış; mevcut case kapsamında günlük backup'ların S3 üzerinde ayrı archive object'leri olarak saklanması yeterli görülmüştür.
- **Distributed tracing:** Merkezi tracing altyapısı kurulmamış; mevcut ölçekte log, healthcheck, rollout ve alarm kontrolleri operasyonel teşhis için kullanılmıştır.

Bu tercihler, case kapsamındaki gereksinimleri gereksiz altyapı ve operasyonel karmaşıklık eklemeden karşılamaya yönelik olarak yapılmıştır.

---

## 4. Hedef Ortam Seçimi

Cloud veya sanal makine tercihinin gerekçesi nedir? Gerçek bir production ortamında mevcut çözümden farklı olarak hangi bileşenleri veya yaklaşımları kullanırdınız?

**Cevap:**

AWS EKS seçilmiştir çünkü uygulama container tabanlıdır ve frontend, backend ve periyodik ETL workload'larının managed Kubernetes üzerinde gerçek bir cloud ortamında çalıştırılması hedeflenmiştir.

Bu seçim ile Amazon ECR, AWS IAM, GitHub OIDC, EKS RBAC, Envoy Gateway, AWS Load Balancer ve Amazon S3 birlikte kullanılabilmiştir.

Mevcut case ortamında kontrollü production approval ile release kontrolü uygulanmıştır. Gerçek production ortamında ise mevcut yapının üzerine Terraform/OpenTofu ile tam IaC, HPA ve node autoscaling, PDB ve multi-node dağılım, Prometheus/Grafana, merkezi secret management, HTTPS/domain yönetimi, tanımlı backup retention, otomatik restore verification/PITR ve daha gelişmiş release stratejileri eklerdim.

---

## 5. MongoDB Yaklaşımı

MongoDB için kullandığınız deployment ve servis yaklaşımını neden seçtiniz? Değerlendirdiğiniz alternatifleri, avantajları, dezavantajları ve operasyonel trade-off’ları açıklayın.

**Cevap:**

Normal deployment'ta MongoDB Atlas kullanılmıştır. Böylece database persistence ve operasyonları Kubernetes workload'larından ayrılmıştır.

Değerlendirilen alternatifler:

| Yaklaşım          | Avantaj                          | Dezavantaj                                                |
| ----------------- | -------------------------------- | --------------------------------------------------------- |
| MongoDB Atlas     | Managed operasyon ve persistence | External network dependency                               |
| StatefulSet + PVC | Kubernetes-native kontrol        | Storage, backup ve replication yönetimi kullanıcıya kalır |
| Geçici MongoDB    | CI/test için basit               | Production data için uygun değil                          |

Bu nedenle uygulama deployment'ında Atlas, CI doğrulamasında ise ephemeral MongoDB kullanılmıştır. `k8s/ci-mongodb.yaml` yalnızca CI/test amaçlıdır.

---

## 6. Helm veya Manifest Yönetimi

Çözümünüzde Helm kullandıysanız neden tercih ettiğinizi ve Helm’in bu projede hangi problemi çözdüğünü açıklayın.

Düz Kubernetes manifestleri veya Kustomize gibi alternatiflerle karşılaştırıldığında sağladığı avantajları ve oluşturduğu ek karmaşıklığı belirtin.

Helm kullanmadıysanız tercih ettiğiniz yöntemi ve seçim gerekçenizi açıklayın.

**Cevap:**

Uygulamanın kendi Kubernetes kaynakları Kustomize kullanılarak ortak bir base ve environment-specific overlay yapısında yönetilmiştir.

Ortak kaynaklar `k8s/eks/` altında tutulurken `k8s/overlays/dev`, `k8s/overlays/test` ve `k8s/overlays/prod` altında environment-specific farklılıklar tanımlanmıştır.

Kustomize tercih edilmesinin nedeni, aynı kaynakları farklı ortamlar için yönetirken Helm templating yapısının getireceği ek karmaşıklığa ihtiyaç duyulmamasıdır. Environment'lar arasında backend ve frontend CPU request değerleri değiştirilmiş, memory request değerleri ise tek `t3.small` worker node kapasitesi nedeniyle `32Mi` tutulmuştur.

Helm ise uygulama workload'larını paketlemek için değil, Envoy Gateway gibi üçüncü taraf Kubernetes bağımlılıklarını kurmak için kullanılmıştır.

Bu nedenle:

```text
Application Kubernetes resources → Kustomize
Envoy Gateway                    → Helm
```

Düz manifestler daha basit olmakla birlikte environment-specific yapılandırma arttıkça tekrar ve manuel değişiklik miktarını artırabilir. Helm daha güçlü templating ve package/version management sağlar; ancak mevcut uygulama kaynakları için gerekli görülmemiştir.

Kustomize yapısı: `k8s/eks/`, `k8s/overlays/`

---

## 7. Kubernetes Service Tipleri

Kubernetes Service tiplerini hangi kriterlere göre belirlediniz?

Her servis için neden `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName` veya headless Service tercih ettiğinizi açıklayın. Hangi servislerin cluster dışından erişilebilir olması gerektiğini ve gereksiz dış erişimi nasıl engellediğinizi belirtin.

**Cevap:**

Servis tipleri, **minimum dışa açıklık (least exposure) ve merkezi trafik yönetimi** kriterlerine göre kurgulanmıştır.

Frontend ve backend için `ClusterIP` kullanılmıştır:

```text
frontend-service → ClusterIP :80
backend-service  → ClusterIP :5050
```

Frontend ve backend'in doğrudan dışarıya açık olması gerekmediği için NodePort veya ayrı LoadBalancer Service'leri tercih edilmemiştir. Dış trafik tek bir giriş noktası üzerinden AWS Load Balancer → Envoy Gateway → HTTPRoute → Service akışıyla yönlendirilir.

Headless veya ExternalName Service için de uygulamanın gerektirdiği bir kullanım bulunmadığından bu tipler tercih edilmemiştir.

Manifestler: `k8s/` ve `k8s/eks/`

---

## 8. Kubernetes Workload Türleri

Uygulama bileşenleri için kullandığınız iş yükü (workload) türlerini hangi kriterlere göre seçtiniz?

Frontend, backend, MongoDB ve ETL bileşenlerinde neden `Deployment`, `StatefulSet`, `Job`, `CronJob` veya farklı bir workload türü kullandığınızı açıklayın.

Karar verirken aşağıdaki konuları nasıl değerlendirdiğinizi belirtin:

- Stateless veya stateful çalışma modeli
- Kalıcı depolama ihtiyacı
- Pod kimliği ve sıralı çalışma gereksinimi
- Çalışma sıklığı
- Yeniden başlatma davranışı
- Ölçeklenebilirlik ihtiyacı

**Cevap:**

- **Frontend → `Deployment`:** Stateless web workload'dur; kalıcı storage, özel Pod kimliği veya sıralı çalışma gerektirmez. Rolling update ve replica yönetimi desteklenir. Liveness/readiness probe'ları ve CPU/memory resource requests/limits tanımlıdır.
- **Backend → `Deployment`:** Stateless REST API'dir; kalıcı veri MongoDB Atlas'ta tutulur. Özel Pod kimliği veya sıralı çalışma gerekmez ve yatay olarak ölçeklenebilir. `/api/healthcheck/` üzerinden liveness/readiness probe'ları ve CPU/memory resource requests/limits tanımlıdır. Kontrollü `RollingUpdate` için `maxSurge: 1` ve `maxUnavailable: 0` kullanılmıştır.
- **MongoDB → MongoDB Atlas:** Normal application deployment'ında MongoDB Kubernetes içinde çalıştırılmadığından `StatefulSet` kullanılmamıştır. CI'daki MongoDB yalnızca ephemeral test workload'udur.
- **ETL → `CronJob`:** Saatlik çalışan periyodik bir workload'dur. Her çalışma ayrı bir `Job` oluşturur. `Forbid` concurrency policy ile çakışan çalışmalar engellenir ve başarısız çalışmalarda retry uygulanır.

```text
0 * * * *
```

Bu seçimlerde stateless/stateful çalışma, persistence, Pod kimliği ve sıralama ihtiyacı, çalışma sıklığı, yeniden başlatma davranışı, kaynak kullanımı ve ölçeklenebilirlik dikkate alınmıştır.

---

## 9. Konfigürasyon ve Secret Yönetimi

Uygulama konfigürasyonlarını ve secret bilgilerini nasıl yönettiniz?

Bir secret değeri değiştirildiğinde veya yenilendiğinde uygulamanın yeni değeri güvenli şekilde kullanmasını nasıl sağlarsınız?

**Cevap:**

Secret'lar source code veya Docker image içine hardcode edilmemiştir.

Local Kubernetes deployment'ında `setup-k8s.ps1` `.env` değerlerinden Secret kaynakları oluşturur. AWS EKS deployment'ında ise değerler GitHub Actions Secrets üzerinden Kubernetes Secrets'a aktarılır.

Önemli değerler arasında `ATLAS_URI`, `GITHUB_TOKEN` ve `MONGODB_URI` bulunmaktadır.

Environment variable olarak kullanılan bir Secret değiştirildiğinde mevcut Pod içindeki değer otomatik değişmeyeceğinden ilgili workload yeni Pod oluşturacak şekilde rollout edilmelidir. Production'da secret rotation için merkezi secret manager kullanılabilir.

---

## 10. MongoDB Erişim Problemi

MongoDB erişilemez hale gelirse backend uygulaması, readiness/liveness kontrolleri ve kullanıcı istekleri nasıl davranır?

Kullanıcı etkisini azaltmak ve servisin kontrollü şekilde toparlanmasını sağlamak için hangi önlemleri aldınız veya alırdınız?

**Cevap:**

Backend, MongoDB bağlantısını startup sırasında kurar ve bağlantı başarısız olduğunda fail-fast davranarak process'i sonlandırır.

Mevcut `/api/healthcheck/` endpoint'i HTTP process erişilebilirliğini doğrular ve backend Deployment'ında readiness/liveness probe olarak kullanılmaktadır; MongoDB dependency'sini doğrudan kontrol etmez.

Production'da readiness probe'u MongoDB dahil gerekli dependency'leri kontrol edecek şekilde ayırırdım. Böylece database erişimi olmayan bir Pod yeni kullanıcı trafiğini almaktan çıkarılabilir.

---

## 11. Hatalı Deployment ve Rollback

Hatalı bir sürüm deploy edildiğinde problemi nasıl tespit edersiniz?

Rollback işlemini hangi yöntemle gerçekleştirirsiniz ve önceki çalışan sürümün güvenli şekilde devreye alındığını nasıl doğrularsınız?

**Cevap:**

Önce Pod, event ve log durumunu incelerim:

```powershell
kubectl get pods -n devops-case
kubectl describe pod <pod> -n devops-case
kubectl logs <pod> -n devops-case
kubectl get events -n devops-case
```

Deployment geçmişini kontrol ederim:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

Gerekirse önceki çalışan sürüme dönerim:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

Rollback sonrasında rollout status, backend healthcheck ve frontend erişimi tekrar doğrulanır.

Backend `RollingUpdate` yapılandırması sayesinde yeni Pod readiness probe ile hazır olmadan eski Pod sonlandırılmaz.

CI/CD deployment sonrasında rollout veya healthcheck kontrolleri başarısız olursa workflow başarısız sonuçlanır.

---

## 12. Ölçeklenebilirlik ve Darboğazlar

Trafik 10 kat arttığında ilk darboğazın nerede oluşmasını beklersiniz?

Hangi bileşenleri, hangi metriklere ve eşiklere göre ölçeklersiniz? Veritabanı bağlantıları, kaynak kullanımı ve bağımlı servisleri nasıl değerlendirirsiniz?

**Cevap:**

Trafiğin 10 kat artması durumunda ilk olarak backend CPU/memory kullanımı ve MongoDB connection/query yükünü incelerim.

Önemli metrikler:

- CPU / memory
- request rate
- response latency
- error rate
- MongoDB connection usage
- query latency

Backend ve frontend stateless olduğu için replica sayıları artırılabilir. Gerek görülürse HPA kullanılabilir. Node kapasitesi yetersiz kaldığında Cluster Autoscaler veya Karpenter gibi node autoscaling mekanizmaları değerlendirilebilir.

MongoDB tarafında connection, query latency ve database kaynak kullanımı ayrıca izlenmelidir.

---

## 13. Logging, Monitoring ve Alarm Yönetimi

Hangi log'ları, metrikleri ve alarmları oluşturdunuz?

Bir incident sırasında problemi teşhis etmek için ilk olarak hangi dashboard, log, metrik veya alarm kayıtlarını incelersiniz?

**Cevap:**

Backend ve ETL tarafında operasyonel loglar tutulmaktadır.

ETL logları repository, MongoDB bağlantısı, update işlemi, document count ve başarılı tamamlanma durumlarını gösterir.

İki kritik alarm senaryosu uygulanmıştır:

- **ALERT-001:** ETL başarısızlığı veya beklenen sürede başarılı ETL çalışmasının bulunmaması
- **ALERT-002:** Frontend veya backend health endpoint'lerinin erişilememesi

Bu kontroller `scripts/check-alerts.ps1` ile test edilmiştir.

Mevcut case ortamında merkezi bir Prometheus/Grafana dashboard'u bulunmadığından incident sırasında öncelikle alert sonucu, Kubernetes Pod/Job durumu, ilgili loglar, rollout durumu ve healthcheck sonuçları incelenir.

---

## 14. Güvenlik Riskleri

Çözümünüzde gördüğünüz en önemli üç güvenlik riski nedir?

Bu riskleri azaltmak için uyguladığınız veya production ortamında uygulayacağınız kontrolleri açıklayın.

**Cevap:**

Üç önemli risk ve alınan önlemler:

1. **Secret exposure:** Secret'lar GitHub Actions Secrets / Kubernetes Secrets üzerinden yönetilmiş, source code ve image içine gömülmemiştir.
2. **Container ve image güvenliği:** `runAsNonRoot`, `allowPrivilegeEscalation: false` ve `capabilities.drop: ALL` kullanılmıştır. Docker image'ları CI aşamasında Trivy ile OS package, dependency ve secret scanning'den geçirilmektedir. Mevcut case yapılandırmasında tarama bulguları raporlanmakta ancak deployment otomatik olarak engellenmemektedir.
3. **Gereksiz dış erişim:** Frontend ve backend `ClusterIP` olarak bırakılmıştır ve dış erişim Envoy Gateway üzerinden sağlanmıştır.

Ayrıca GitHub Actions AWS erişimi için OIDC, IAM least privilege ve namespace-scoped Kubernetes RBAC kullanılmıştır.

---

## 15. Python ETL Güncelleme Yaklaşımı

Python ETL aynı repository bilgisini tekrar aldığında mevcut kaydı nasıl bulup güncelliyor? Benzersiz kayıt anahtarı olarak hangi alanı kullandınız ve duplicate oluşmadığını hangi ekran görüntüsü veya çıktı ile gösterdiniz?

**Cevap:**

Benzersiz kayıt anahtarı olarak:

```text
github_id
```

kullanılmıştır.

Bu proje için repository:

```text
github_id = 1361100555
```

değerine sahiptir.

Aynı repository tekrar işlendiğinde `update_one(..., upsert=True)` ile mevcut document güncellenir; yeni duplicate document oluşturulmaz.

Kanıtlar:

- `docs/screenshots/20-etl-first-load.png`
- `docs/screenshots/21-etl-update-without-duplicate.png`
- `docs/screenshots/22-eks-etl-success.png`

ETL logları update işlemini ve `MongoDB document count: 1` sonucunu göstermektedir. Güncellenen alanlar da `Updated fields: ...` çıktısıyla gösterilmektedir.

---

## 16. Backup ve Restore Yaklaşımı

MongoDB için hangi yedekleme yöntemini ve saklama konumunu seçtiniz?

Yedekleme sıklığı, retention süresi, RPO ve RTO hedefleriniz nedir ve ölçtüğünüz gerçek geri yükleme süresi ne kadar oldu?

Yedeğin bozuk veya eksik olmasına karşı hangi doğrulamayı yaparsınız; gerçek bir production ortamında bu yaklaşımı nasıl farklılaştırırdınız?

Runbook’unuzu `docs/backup-restore.md` içinde paylaşın ve kanıtları `TESLIM_KANITLARI.md` dosyasından referanslayın.

**Cevap:**

MongoDB Atlas verilerinin production backup'ı AWS EKS üzerinde çalışan `mongodb-backup` Kubernetes CronJob ile günlük olarak alınmaktadır.

Backup akışı:

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

Backup dosyaları UTC timestamp içeren ayrı archive dosyaları olarak oluşturulmaktadır. Örnek:

```text
sample_training_20260912T230006Z.archive.gz
```

Backup'lar cluster dışındaki Amazon S3 üzerinde saklanmaktadır:

```text
s3://devops-case-baykar-backups-203309795174/sample_training/
```

Backup archive'ının boş olmadığı `test -s` ile kontrol edilmekte ve S3 upload sonrasında `aws s3api head-object` ile object'ın başarıyla oluşturulduğu doğrulanmaktadır.

Backup workload'u ayrı `s3-backup` ServiceAccount kullanmakta ve gerekli S3 erişimi least-privilege IAM policy ile sınırlandırılmaktadır. Backup container'ları non-root kullanıcılarla çalıştırılmakta ve privilege escalation devre dışı bırakılmaktadır.

Bu case kapsamında S3 Lifecycle tabanlı otomatik retention/silme politikası uygulanmamıştır. Bu nedenle formal production retention süresi tanımlanmamıştır.

Günlük backup schedule'ı nedeniyle teorik maksimum backup penceresi yaklaşık 24 saattir; bu değer resmi bir production SLA'sı değil, mevcut case ortamındaki backup sıklığının doğal sonucudur.

Backup archive'ının S3'e başarıyla gönderilmesi otomatik olarak doğrulanmaktadır. Ayrıca backup'ın gerçekten geri yüklenebilir olduğunu doğrulamak için local ortamda manuel bir end-to-end restore testi gerçekleştirilmiştir.

Manuel testte `scripts/backup-restore.ps1` kullanılarak:

```text
Kayıt oluşturma
      ↓
Backup alma
      ↓
Database'i silme
      ↓
Verinin kaybolduğunu doğrulama
      ↓
mongorestore
      ↓
UI + MongoDB verification
```

akışı gerçekleştirilmiştir.

Test kapsamında:

```text
records              → 1 document
github_repositories  → 1 document
Total                → 2 documents
```

yedeklenmiştir.

Restore sonucunda:

```text
2 documents restored successfully.
0 documents failed to restore.
```

Restore sırasında ölçülen `mongorestore` çalışma süresi yaklaşık **1.3 saniyedir**. Bu değer yalnızca restore komutunun çalışma süresidir; uçtan uca production RTO olarak değerlendirilmemiştir.

Mevcut case ortamında formal production RPO/RTO SLA'sı tanımlanmamıştır. Production ortamında bu hedefler iş gereksinimlerine göre açıkça belirlenmeli; örneğin backup frequency, restore verification, retention, encryption, S3 Lifecycle, PITR ve düzenli DR drill ile desteklenmelidir.

Runbook: `docs/backup-restore.md`

Backup script'i ve manuel E2E test: `scripts/backup-restore.ps1`

Otomatik backup manifestleri:

- `k8s/eks/backup-cronjob.yaml`
- `k8s/eks/backup-serviceaccount.yaml`

Kanıtlar: `TESLIM_KANITLARI.md`, `6. Backup ve Restore` bölümünden: 

- **Kayıt oluşturma 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Kayıt oluşturma 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Manuel yedek alma:** `docs/screenshots/31-backup-taken.png`
- **Collection veya database'in silinmesi:** `docs/screenshots/32-collection-dropped.png`
- **Verinin kaybolduğunun gösterilmesi (UI):** `docs/screenshots/33-data-missing-after-drop-ui.png`
- **Verinin kaybolduğunun gösterilmesi (database):** `docs/screenshots/34-data-missing-after-drop-database.png`
- **Yedekten geri yükleme:** `docs/screenshots/35-restore-executed.png`
- **Restore sonrası UI doğrulaması:** `docs/screenshots/36-data-restored-verified-ui.png`
- **Restore sonrası database doğrulaması (1):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Restore sonrası database doğrulaması (2):** `docs/screenshots/38-data-restored-verified-database-02.png`

Otomatik scheduled backup kanıtı:

`docs/screenshots/49-backup-cronjob-scheduled-success.png`

---

## Ek Notlar

Case kapsamında özellikle belirtmek istediğiniz ek kararlar, sınırlamalar veya sonraki geliştirme adımları varsa bu bölümde açıklayabilirsiniz.

**Cevap:**

Çalışmanın son aşamasında uygulama gerçek AWS EKS ortamına taşınmış ve GitHub Actions üzerinden otomatik cloud deployment sağlanmıştır.

CI/CD akışında GitHub OIDC ile AWS IAM Role kullanılmış, image'lar commit SHA ile Amazon ECR'a gönderilmiş ve production deployment `k8s/overlays/prod` Kustomize overlay'i üzerinden gerçekleştirilmiştir.

Deployment öncesinde Kustomize çıktısı server-side dry-run ile doğrulanmış, ardından production overlay EKS'ye uygulanmıştır. Deployment sonrasında image sürümleri commit SHA ile güncellenmiş, rollout ve healthcheck kontrolleri gerçekleştirilmiştir.

Ana case kriterleri uygulanmış ve doğrulanmıştır. Ayrıca Kustomize ile environment yönetimi, kontrollü RollingUpdate ve kapasiteye uygun workload yapılandırması, doğrulanmış alarm senaryoları, Trivy ile image/dependency/secret scanning ve cluster dışı Amazon S3'e günlük otomatik MongoDB backup uygulanmıştır.

Backup/restore tarafında otomatik production backup mekanizması ile manuel E2E restore testi birbirinden ayrılmıştır. Otomatik mekanizma düzenli ve cluster dışı backup sağlarken, manuel test backup'ın gerçekten geri yüklenebilir olduğunu doğrulamaktadır.

Daha ileri production ihtiyaçları olarak tam IaC, gelişmiş monitoring ve autoscaling, merkezi secret management, multi-node yüksek erişilebilirlik, daha ileri release stratejileri (ör. canary/blue-green), S3 Lifecycle/PITR, otomatik restore verification ve düzenli DR drill sonraki geliştirme alanları olarak değerlendirilebilir.
