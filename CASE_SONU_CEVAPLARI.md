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
                ┌────┴────┐
                ↓         ↓
            Frontend   Backend
             Service   Service
                ↓         ↓
              React    Node.js
             + NGINX   + Express
                           ↓
                      MongoDB Atlas
```

Frontend NGINX `/api/` isteklerini `backend-service:5050` adresine yönlendirir. Backend record CRUD işlemlerini MongoDB Atlas'taki `sample_training` database'inde gerçekleştirir.

ETL ayrı bir iş akışı olarak GitHub API'den repository bilgilerini alır ve `github_id` üzerinden `github_repositories` collection'ındaki kaydı upsert eder.

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

Temel case gereksinimleri tamamlanmış; ancak bazı ileri seviye production özellikleri kapsam dışında bırakılmıştır.

Terraform/OpenTofu ile tam IaC, Prometheus/Grafana tabanlı gelişmiş monitoring, HPA/PDB ve çoklu node yüksek erişilebilirliği, GitOps, canary/blue-green deployment, otomatik off-site backup/retention ve distributed tracing uygulanmamıştır.

Buna karşılık mevcut case ortamının kapasitesine uygun olarak kontrollü `RollingUpdate`, CPU/memory resource yönetimi, Kustomize ile environment yönetimi, doğrulanabilir alarm kontrolleri ve Trivy image/dependency/secret scanning uygulanmış ve gerçek EKS ortamında doğrulanmıştır.

Production ortamında kapsam dışında bırakılan özellikler; ölçekleme, gözlemlenebilirlik, release management ve disaster recovery ihtiyaçlarına göre ayrıca eklenebilir.

---

## 4. Hedef Ortam Seçimi

Cloud veya sanal makine tercihinin gerekçesi nedir? Gerçek bir production ortamında mevcut çözümden farklı olarak hangi bileşenleri veya yaklaşımları kullanırdınız?

**Cevap:**

AWS EKS seçilmiştir çünkü uygulama container tabanlıdır ve frontend, backend ve periyodik ETL workload'larının managed Kubernetes üzerinde gerçek bir cloud ortamında çalıştırılması hedeflenmiştir.

Bu seçim ile Amazon ECR, AWS IAM, GitHub OIDC, EKS RBAC, Envoy Gateway ve AWS Load Balancer birlikte kullanılabilmiştir.

Production ortamında mevcut yapının üzerine Terraform/OpenTofu ile tam IaC, HPA ve node autoscaling, PDB ve multi-node dağılım, Prometheus/Grafana, merkezi secret management, otomatik off-site backup, HTTPS/domain yönetimi ve kontrollü release stratejileri eklerdim.

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
- **Backend → `Deployment`:** Stateless REST API'dir; kalıcı veri MongoDB Atlas'ta tutulur. Özel Pod kimliği veya sıralı çalışma gerekmez ve yatay olarak ölçeklenebilir. `/healthcheck/` üzerinden liveness/readiness probe'ları ve CPU/memory resource requests/limits tanımlıdır. Kontrollü `RollingUpdate` için `maxSurge: 1` ve `maxUnavailable: 0` kullanılmıştır.
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

Mevcut `/healthcheck/` endpoint'i HTTP process erişilebilirliğini doğrular ve backend Deployment'ında readiness/liveness probe olarak kullanılmaktadır; MongoDB dependency'sini doğrudan kontrol etmez.

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

MongoDB Atlas verisi `mongodump` ile `sample_training` database'i seviyesinde yedeklenmiş ve backup `backups/sample-training-backup/` altında saklanmıştır.

Test kapsamında:

```text
records              → 1 document
github_repositories  → 1 document
Total                → 2 documents
```

yedeklenmiştir.

Mevcut case çözümünde backup işlemi otomatik zamanlanmış bir mekanizma ile çalıştırılmamaktadır. Backup ve restore işlemlerini tekrarlanabilir hale getirmek için `scripts/backup-restore.ps1` script'i repository'ye eklenmiş ve `-Action Backup` ile `-Action Restore -DropExisting` senaryoları gerçek veri üzerinde başarıyla test edilmiştir.

End-to-end restore testinde database silinmiş, veri kaybı UI ve MongoDB üzerinden doğrulanmış, ardından backup geri yüklenerek collection/document count ve uygulama erişimi tekrar kontrol edilmiştir.

Restore sonucu:

```text
2 documents restored successfully.
0 documents failed to restore.
```

Ölçülen `mongorestore` çalışma süresi yaklaşık **1.3 saniyedir**. Bu değer yalnızca restore komutunun çalışma süresidir; uçtan uca production RTO olarak değerlendirilmemiştir.

Mevcut case çözümünde formal bir production RPO/RTO SLA'sı ve otomatik retention mekanizması tanımlanmamıştır.

Production ortamında otomatik ve encrypted backup, tanımlı retention, off-site/object storage, backup integrity verification, düzenli restore testleri ve açıkça belirlenmiş RPO/RTO hedefleri kullanılmalıdır.

Runbook: `docs/backup-restore.md`
Script: `scripts/backup-restore.ps1`
Kanıtlar: `TESLIM_KANITLARI.md`, `6. Backup ve Restore` bölümünden: 

- **Kayıt oluşturma 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Kayıt oluşturma 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Yedek alma (görsel veya terminal çıktısı):** `docs/screenshots/31-backup-taken.png`
- **Collection veya veritabanının silinmesi (görsel veya terminal çıktısı)** `docs/screenshots/32-collection-dropped.png`
- **Verinin kaybolduğunun gösterilmesi (arayüz görseli):** `docs/screenshots/33-data-missing-after-drop-ui.png`
- **Verinin kaybolduğunun gösterilmesi (veritabanı çıktısı):** `docs/screenshots/34-data-missing-after-drop-database.png`
- **Yedekten geri yükleme (görsel veya terminal çıktısı):** `docs/screenshots/35-restore-executed.png`
- **Verinin geri geldiğinin doğrulanması (arayüz görseli):** `docs/screenshots/36-data-restored-verified-ui.png`
- **Verinin geri geldiğinin doğrulanması (veritabanı çıktısı (1)):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Verinin geri geldiğinin doğrulanması (veritabanı çıktısı (2)):** `docs/screenshots/38-data-restored-verified-database-02.png`

---

## Ek Notlar

Case kapsamında özellikle belirtmek istediğiniz ek kararlar, sınırlamalar veya sonraki geliştirme adımları varsa bu bölümde açıklayabilirsiniz.

**Cevap:**

Çalışmanın son aşamasında uygulama gerçek AWS EKS ortamına taşınmış ve GitHub Actions üzerinden otomatik cloud deployment sağlanmıştır.

CI/CD akışında GitHub OIDC ile AWS IAM Role kullanılmış, image'lar commit SHA ile Amazon ECR'a gönderilmiş ve production deployment `k8s/overlays/prod` Kustomize overlay'i üzerinden gerçekleştirilmiştir.

Deployment öncesinde Kustomize çıktısı server-side dry-run ile doğrulanmış, ardından production overlay EKS'e uygulanmıştır. Deployment sonrasında image sürümleri commit SHA ile güncellenmiş, rollout ve healthcheck kontrolleri gerçekleştirilmiştir.

Ana case kriterleri uygulanmış ve doğrulanmıştır. Ayrıca Kustomize ile environment yönetimi, kontrollü RollingUpdate ve kapasiteye uygun workload yapılandırması, doğrulanmış alarm senaryoları ve Trivy ile image/dependency/secret scanning uygulanmıştır.

Daha ileri production ihtiyaçları olarak tam IaC, gelişmiş monitoring ve autoscaling, merkezi secret management, multi-node yüksek erişilebilirlik, kontrollü release stratejileri ve gelişmiş disaster recovery sonraki geliştirme alanları olarak değerlendirilebilir.
