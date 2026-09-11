# CASE SONU CEVAPLARI

Bu dosyada aşağıdaki soruların tamamını, yaptığınız çalışma ile doğrudan ilişkilendirerek cevaplayın.

Cevaplarınızın kısa, somut ve teknik kararlarınızı açıklayacak düzeyde olması beklenmektedir. Gerekli gördüğünüz yerlerde ilgili kaynak koduna, manifest dosyasına, pipeline adımına veya dokümana dosya yolu vererek referans verebilirsiniz. Çalışma kanıtları ve ekran görüntüleri ayrıca `TESLIM_KANITLARI.md` dosyasında sunulmalıdır.

---

## Aday Bilgileri

- **Ad Soyad:** Tunahan Değirmencioğlu
- **Repository adresi:** `https://github.com/dabbitz/devops-case-baykar.git`
- **Çalışmanın tamamlandığı tarih:** 11.09.2026
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
React    Node.js
+ NGINX  + Express
             ↓
        MongoDB Atlas
```

Frontend NGINX `/api/` isteklerini `backend-service:5050` adresine yönlendirir. Backend record CRUD işlemlerini MongoDB Atlas'taki `sample_training` database'inde gerçekleştirir.

ETL ayrı olarak GitHub API'den repository bilgilerini alır ve `github_id` üzerinden `github_repositories` collection'ını upsert eder.

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

Temel case gereksinimleri tamamlanmış; ancak bazı production-level özellikler kapsam dışında bırakılmıştır.

Örneğin Terraform/OpenTofu ile tam IaC, Prometheus/Grafana, HPA/PDB, GitOps, canary/blue-green deployment, otomatik off-site backup retention ve distributed tracing uygulanmamıştır.

Buna karşılık çözüm AWS EKS, Amazon ECR, GitHub OIDC, IAM, EKS RBAC, Helm tabanlı Envoy Gateway, non-root container hardening ve doğrulanabilir alert kontrolleri ile genişletilmiştir.

Üretim ortamında bu eksik alanlar gerektiğinde ayrı bir ölçekleme, gözlemlenebilirlik ve disaster recovery katmanı olarak eklenebilir.

---

## 4. Hedef Ortam Seçimi

Cloud veya sanal makine tercihinin gerekçesi nedir? Gerçek bir production ortamında mevcut çözümden farklı olarak hangi bileşenleri veya yaklaşımları kullanırdınız?

**Cevap:**

AWS EKS seçilmiştir çünkü uygulama container tabanlıdır ve frontend, backend ve periyodik ETL workload'larının managed Kubernetes üzerinde gerçek bir cloud ortamında çalıştırılması hedeflenmiştir.

Bu seçim ile Amazon ECR, AWS IAM, GitHub OIDC, EKS RBAC, Envoy Gateway ve AWS Load Balancer birlikte kullanılabilmiştir.

Production ortamında mevcut yapının üzerine Terraform/OpenTofu, HPA ve node autoscaling, PDB/multi-node dağılımı, Prometheus/Grafana, merkezi secret management, otomatik off-site backup, HTTPS/domain yönetimi ve kontrollü release stratejileri eklerdim.

---

## 5. MongoDB Yaklaşımı

MongoDB için kullandığınız deployment ve servis yaklaşımını neden seçtiniz? Değerlendirdiğiniz alternatifleri, avantajları, dezavantajları ve operasyonel trade-off’ları açıklayın.

**Cevap:**

Normal deployment'ta MongoDB Atlas kullanılmıştır. Böylece database persistent storage ve operasyonları Kubernetes workload'larından ayrılmıştır.

Değerlendirilen alternatifler:

| Yaklaşım          | Avantaj                          | Dezavantaj                                            |
| ----------------- | -------------------------------- | ----------------------------------------------------- |
| MongoDB Atlas     | Managed operasyon ve persistence | External network dependency                           |
| StatefulSet + PVC | Kubernetes-native kontrol        | Storage/backup/replication yönetimi kullanıcıya kalır |
| Geçici MongoDB    | CI/test için basit               | Production data için uygun değil                      |

Bu nedenle uygulama deployment'ında Atlas, CI doğrulamasında ise ephemeral MongoDB kullanılmıştır. `k8s/ci-mongodb.yaml` yalnızca CI/test amaçlıdır.

---

## 6. Helm veya Manifest Yönetimi

Çözümünüzde Helm kullandıysanız neden tercih ettiğinizi ve Helm’in bu projede hangi problemi çözdüğünü açıklayın.

Düz Kubernetes manifestleri veya Kustomize gibi alternatiflerle karşılaştırıldığında sağladığı avantajları ve oluşturduğu ek karmaşıklığı belirtin.

Helm kullanmadıysanız tercih ettiğiniz yöntemi ve seçim gerekçenizi açıklayın.

**Cevap:**

Uygulamanın kendi Kubernetes kaynakları düz manifest dosyalarıyla yönetilmiştir. Bu kaynaklarda ortak bir templating veya çoklu environment değer yönetimi gereksinimi bulunmadığı için Helm chart yerine doğrudan manifest kullanımı tercih edilmiştir.

Karşılaştırma ve Tercih Nedenleri:

- **Düz Manifestler**: Okunması, anlaşılması ve hata ayıklaması en kolay yöntemdir. Projede çoklu ortam ihtiyacı olmadığı için kendi kaynaklarımızı düz YAML dosyalarıyla yönetiyoruz.
- **Helm / Kustomize**: Şablonlama, parametre yönetimi ve versiyonlama sunar. Ancak mevcut proje ölçeğinde kendi manifestlerimiz için kullanılması gereksiz karmaşıklık oluşturacağından, yalnızca Envoy Gateway gibi üçüncü taraf bağımlılıkların yönetiminde kullanılmıştır.

Envoy Gateway ise birden fazla ilişkili Kubernetes kaynağından oluşan third-party bir bileşen olduğundan, resmi Helm chart'ı üzerinden kurulmuştur.

Bu nedenle:

```text
Application workloads  → Kubernetes manifests
Envoy Gateway          → Helm
```

yaklaşımı kullanılmıştır.

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

Uygulama bileşenlerinin doğrudan dışarıya açık olması güvenlik açısından iyi değildir. Bu nedenle node'ların portlarını dışarı açan NodePort veya her servis için bulut sağlayıcıda ayrı bir yük dengeleyici oluşturup trafiği Gateway dışına çıkaran LoadBalancer tipleri tercih edilmemiştir.

Özel bir DNS çözümleme (pod-to-pod doğrudan erişim) veya dış kaynak proxy'leme ihtiyacı olmadığı için Headless veya ExternalName de kullanılmamıştır. Dış trafik AWS Load Balancer → Envoy Gateway → HTTPRoute üzerinden Service'lere yönlendirilir.

Böylece NodePort veya doğrudan LoadBalancer kullanılarak backend'in ayrıca dışarıya açılması engellenmiştir.

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

- **Frontend → `Deployment`:** Stateless web workload'dur; kalıcı storage, özel Pod kimliği veya sıralı çalışma gerektirmez. Replica ve rolling update desteklenir. Liveness/readiness probe'ları ve CPU/memory resource requests/limits tanımlıdır.
- **Backend → `Deployment`:** Stateless REST API'dir; kalıcı veri MongoDB'de tutulur. Özel Pod kimliği gerekmez ve yatay ölçeklenebilir. `/healthcheck/` üzerinden liveness/readiness probe'ları ve CPU/memory resource requests/limits tanımlıdır. Tek node'lu EKS ortamında kontrollü rolling update için `maxSurge: 0` ve `maxUnavailable: 1` kullanılmıştır.
- **MongoDB:** Normal deployment'ta MongoDB Atlas kullanıldığı için Kubernetes `StatefulSet` kullanılmamıştır. CI'daki MongoDB yalnızca ephemeral test workload'udur.
- **ETL → `CronJob`:** Saatlik çalışan periyodik bir workload'dur. Her çalışma ayrı bir `Job` oluşturur; `Forbid` ile çakışan çalışmalar engellenir, başarısız çalışmalarda retry uygulanır ve CPU/memory resource requests/limits tanımlıdır.

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

Bir Secret değiştirildiğinde mevcut Pod içindeki environment variable otomatik değişmeyeceğinden workload yeni Pod oluşturacak şekilde rollout edilmelidir. Production'da secret rotation için merkezi secret manager kullanılabilir.

---

## 10. MongoDB Erişim Problemi

MongoDB erişilemez hale gelirse backend uygulaması, readiness/liveness kontrolleri ve kullanıcı istekleri nasıl davranır?

Kullanıcı etkisini azaltmak ve servisin kontrollü şekilde toparlanmasını sağlamak için hangi önlemleri aldınız veya alırdınız?

**Cevap:**

Backend, MongoDB bağlantısını startup sırasında kurar ve bağlantı başarısız olduğunda fail-fast davranarak process'i sonlandırır.

Mevcut `/healthcheck/` endpoint'i HTTP process erişilebilirliğini doğrular ve backend Deployment'ında hem readiness hem de liveness probe olarak kullanılmaktadır; MongoDB dependency'sini doğrudan kontrol etmez.

Production'da readiness probe'u MongoDB dahil gerekli dependency'leri kontrol edecek şekilde ayırırdım. Böylece database erişimi olmayan bir Pod yeni kullanıcı trafiğini almaktan çıkarılabilir.

Backend healthcheck, CI/CD deployment sonrasında da doğrulanmaktadır.

---

## 11. Hatalı Deployment ve Rollback

Hatalı bir sürüm deploy edildiğinde problemi nasıl tespit edersiniz?

Rollback işlemini hangi yöntemle gerçekleştirirsiniz ve önceki çalışan sürümün güvenli şekilde devreye alındığını nasıl doğrularsınız?

**Cevap:**

Önce:

```powershell
kubectl get pods -n devops-case
kubectl describe pod <pod> -n devops-case
kubectl logs <pod> -n devops-case
kubectl get events -n devops-case
```

komutlarıyla Pod ve event'ler ne durumda incelerim.

Deployment geçmişine bakarım:

```powershell
kubectl rollout history deployment/backend -n devops-case
kubectl rollout history deployment/frontend -n devops-case
```

Ve önceki sürüme dönerim:

```powershell
kubectl rollout undo deployment/backend -n devops-case
kubectl rollout undo deployment/frontend -n devops-case
```

Rollback yaptıktan sonra rollout status, backend healthcheck ve frontend erişimi tekrar doğrulanır.

CI/CD deployment sonrası healthcheck başarısız olduğunda job başarısız sonuçlanır.

---

## 12. Ölçeklenebilirlik ve Darboğazlar

Trafik 10 kat arttığında ilk darboğazın nerede oluşmasını beklersiniz?

Hangi bileşenleri, hangi metriklere ve eşiklere göre ölçeklersiniz? Veritabanı bağlantıları, kaynak kullanımı ve bağımlı servisleri nasıl değerlendirirsiniz?

**Cevap:**

Trafiğin 10 kat artması durumunda ilk olarak backend CPU/memory kullanımı ve MongoDB connection/query yükünü incelerim.

İncelenmesi gereken önemli değerler:

- CPU / memory
- request rate
- response latency
- error rate
- MongoDB connection usage
- query latency

Backend ve frontend stateless olduğu için replica sayıları arttırılabilir. Gerek görülürse Pod seviyesinde HPA (Horizontal Pod Autoscaler) kullanılabilir. Node kapasitesi yetersiz kaldığında ise Cluster Autoscaler veya Karpenter gibi node autoscaling mekanizmaları kullanılabilir.

MongoDB'nin replica sayısı, connection ve database yükünü arttıracağından ayrıca değerlendirilmelidir.

---

## 13. Logging, Monitoring ve Alarm Yönetimi

Hangi log'ları, metrikleri ve alarmları oluşturdunuz?

Bir incident sırasında problemi teşhis etmek için ilk olarak hangi dashboard, log, metrik veya alarm kayıtlarını incelersiniz?

**Cevap:**

Backend ve ETL tarafında işlemlerle ilgili log'lar tutulmaktadır.

ETL log'ları repository, MongoDB bağlantısı, update işlemi, document count ve başarılı tamamlanma durumlarını gösterir.

İki kritik alarm senaryosu uygulanmıştır:

- **ALERT-001:** ETL başarısızlığı veya beklenen sürede başarılı ETL çalışmasının bulunmaması
- **ALERT-002:** Frontend veya backend health endpoint'lerinin erişilememesi

Bu kontroller `scripts/check-alerts.ps1` ile test edilmiştir.

Incident sırasında önce alert sonucu, Kubernetes Pod/Job durumu, ilgili log'lar, rollout durumu ve healthcheck sonuçları incelenir.

---

## 14. Güvenlik Riskleri

Çözümünüzde gördüğünüz en önemli üç güvenlik riski nedir?

Bu riskleri azaltmak için uyguladığınız veya production ortamında uygulayacağınız kontrolleri açıklayın.

**Cevap:**

Üç önemli risk ve alınan önlemler:

1. **Secret exposure:** Secret'lar, GitHub Actions Secrets / Kubernetes Secrets üzerinden yönetilmiş, source code ve image içine gömülmemiştir.
2. **Root container kullanımı:** `runAsNonRoot`, `allowPrivilegeEscalation: false` ve `capabilities.drop: ALL` parametreleri kullanılmıştır.
3. **Gereksiz dış erişim:** Frontend ve backend, `ClusterIP` olarak bırakılmıştır ve dış erişim Envoy Gateway üzerinden sağlanmıştır.

Aynı zamanda GitHub Actions AWS erişimi için OIDC, IAM least privilege ve namespace-scoped Kubernetes RBAC kullanılmıştır.

---

## 15. Python ETL Güncelleme Yaklaşımı

Python ETL aynı repository bilgisini tekrar aldığında mevcut kaydı nasıl bulup güncelliyor? Benzersiz kayıt anahtarı olarak hangi alanı kullandınız ve duplicate oluşmadığını hangi ekran görüntüsü veya çıktı ile gösterdiniz?

**Cevap:**

Benzersiz kayıt anahtarı olarak:

```text
github_id
```

kullanılmıştır.

Örneğin (bu projenin github'daki repo id'si):

```text
github_id = 1361100555
```

Aynı repository tekrar işlendiğinde `update_one(..., upsert=True)` ile mevcut document güncellenir; yeni duplicate document oluşturulmaz.

Kanıt:

- `docs/screenshots/20-etl-first-load.png`
- `docs/screenshots/21-etl-update-without-duplicate.png`
- `docs/screenshots/22-eks-etl-success.png`

ETL log'ları update işlemini ve `MongoDB document count: 1` sonucunu göstermektedir. Aynı zamanda hangi alanların update edildiği de `Updated fields: ...` şeklinde gösterilmiştir.

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
records                 → 1 document
github_repositories     → 1 document
Total                   → 2 documents
```

yedeklenmiştir.

Mevcut case çözümünde backup işlemi otomatik zamanlanmış bir mekanizma ile çalıştırılmamaktadır; gerçek E2E test manuel olarak gerçekleştirilmiştir. Bunun yanında backup ve restore işlemlerini tekrarlanabilir şekilde çalıştırmak için `scripts/backup-restore.ps1` PowerShell script'i repository'ye eklenmiştir. `-Action Backup` ve `-Action Restore -DropExisting` senaryoları başarıyla test edilmiştir. Otomatik backup sıklığı ve retention uygulanmamıştır.

Restore doğrulamasında:

- database silinerek veri kaybı doğrulanmıştır,
- `mongorestore` sonucu ve hata sayısı kontrol edilmiştir,
- collection ve document count doğrulanmıştır,
- verinin uygulama üzerinden tekrar okunabildiği doğrulanmıştır.

Restore sonucu:

```text
2 documents restored successfully.
0 documents failed to restore.
```

Production ortamında otomatik ve encrypted backup, tanımlı retention, off-site/object storage, düzenli restore testleri ve gerçek RPO/RTO takibi kullanırdım.

Runbook: `docs/backup-restore.md`
Script: `scripts/backup-restore.ps1`
Kanıtlar: `TESLIM_KANITLARI.md` "6. Backup ve Restore" bölümünden:

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

Çalışmanın son aşamasında yerel Kubernetes doğrulamasına ek olarak uygulama gerçek AWS EKS ortamına taşınmış ve GitHub Actions üzerinden otomatik cloud deployment sağlanmıştır.

CI/CD akışında GitHub OIDC ile AWS IAM Role kullanılmış, image'lar commit SHA ile Amazon ECR'a gönderilmiş ve aynı sürümler EKS'e deploy edilmiştir.

Kubernetes workload'ları için liveness/readiness probes, CPU/memory resource requests/limits ve tek node'lu EKS ortamına uygun kontrollü rolling update yapılandırması da uygulanmış ve gerçek EKS ortamında doğrulanmıştır.

Ana case kriterlerinde belirtilen temel gereksinimler uygulanmış ve doğrulanmıştır. Ayrıca üst kriterlerden yüksek erişilebilirlik/ölçekleme alanında kontrollü rolling update ve kapasiteye uygun workload yapılandırması, ileri gözlemlenebilirlik alanında ise doğrulanmış alarm senaryoları uygulanmıştır.

Mevcut çözüm case kapsamındaki gereksinimleri karşılayacak şekilde tamamlanmıştır. Daha ileri production ihtiyaçları olarak altyapının tamamen IaC ile yönetilmesi, gelişmiş monitoring ve autoscaling, merkezi secret management ve gelişmiş disaster recovery sonraki geliştirme alanları olarak değerlendirilebilir.
