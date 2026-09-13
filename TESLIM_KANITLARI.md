# TESLİM KANITLARI

Teslimin başarılı şekilde tamamlanmış sayılabilmesi için çalışan sisteme ait ekran görüntülerini `docs/screenshots/` klasörüne ekleyin ve aşağıdaki maddelerde ilgili dosya yolunu belirtin.

Ekran görüntülerinde gerçek credential, token, parola, private key veya hassas bağlantı bilgileri görünmemelidir.

## 1. Web Uygulaması

### 1.1 Ana sayfa

- **Görsel:** `docs/screenshots/01-web-home.png`
- **Açıklama:** React frontend uygulamasının erişilebilir ve çalışır durumda olduğu gösterilmektedir. Ana sayfa üzerinden uygulamanın temel kullanıcı akışlarına erişilebilmektedir.

### 1.2 Create işlemi

- **Form görseli:** `docs/screenshots/02-record-create-form.png`
- **Başarılı sonuç görseli:** `docs/screenshots/03-record-created.png`
- **Açıklama:** Yeni bir kayıt oluşturma formu doldurulmuş ve create işlemi başarıyla gerçekleştirilmiştir. Oluşturulan kayıt `/records` ekranında doğrulanmıştır.

### 1.3 Edit işlemi

- **İşlem öncesi görseli:** `docs/screenshots/04-record-edit-before.png`
- **İşlem sonrası görseli:** `docs/screenshots/05-record-edit-after.png`
- **Açıklama:** Mevcut kayıt edit formu üzerinden güncellenmiştir. Güncelleme sonrasında yeni değerlerin `/records` ekranında görüntülendiği doğrulanmıştır.

## 2. Docker

- **Kubernetes image build görseli:** `docs/screenshots/06-docker-images-kubernetes-build.png`
- **Compose image build görseli:** `docs/screenshots/07-docker-images-compose-build.png`
- **Çalışan container görseli:** `docs/screenshots/08-docker-images-compose-and-kubernetes.png`
- **Açıklama:** Frontend, backend ve Python ETL için Docker image'larının başarıyla oluşturulduğu ve container ortamlarında çalıştırılabildiği gösterilmektedir. Aynı uygulama image'larının AWS EKS deployment'ı için Amazon ECR'a da push edildiği CI/CD kanıtlarında ayrıca gösterilmektedir.

## 3. Kubernetes

### 3.1 Local Kubernetes

- **Pod/workload durumu:** `docs/screenshots/09-kubernetes-workloads.png`
- **Service ve Gateway durumu:** `docs/screenshots/10-kubernetes-services-gateway.png`
- **ETL CronJob/Job durumu:** `docs/screenshots/11-etl-cronjob-job.png`
- **Açıklama:** Uygulama local Kubernetes ortamında `devops-case` namespace'i içerisinde çalıştırılmıştır. Frontend ve backend Deployment/Service kaynakları oluşturulmuş, Python ETL ise saatlik çalışan bir CronJob olarak yapılandırılmıştır. Envoy Gateway ve HTTPRoute üzerinden uygulama içi yönlendirme sağlanmıştır.

### 3.2 AWS EKS

- **EKS cluster ve node durumu:** `docs/screenshots/12-eks-cluster-node.png`
- **EKS workload durumu:** `docs/screenshots/13-eks-workloads.png`
- **Service ve Gateway durumu:** `docs/screenshots/14-eks-services-gateway.png`
- **ECR image'ları (backend):** `docs/screenshots/15-ecr-images-backend.png`
- **ECR image'ları (frontend):** `docs/screenshots/16-ecr-images-frontend.png`
- **ECR image'ları (etl):** `docs/screenshots/17-ecr-images-etl.png`
- **Health check ve resource tanımları (backend):** `docs/screenshots/39-eks-healthchecks-resources-backend.png`
- **Health check ve resource tanımları (frontend):** `docs/screenshots/40-eks-healthchecks-resources-frontend.png`
- **Health check ve resource tanımları (etl):** `docs/screenshots/41-eks-cpu-memory-limits-etl.png`
- **Açıklama:** Uygulama AWS EKS üzerinde `devops-case-eks` cluster'ına deploy edilmiştir. Backend ve frontend Deployment'ları, Service kaynakları ve Python ETL CronJob'u EKS üzerinde çalışmaktadır. Container image'ları Amazon ECR üzerinden çekilmektedir.

Backend ve frontend Deployment'larında liveness/readiness probe'ları, tüm ana workload'larda ise CPU ve memory resource requests/limits tanımlanmıştır. Backend Deployment'ında `maxSurge: 1` ve `maxUnavailable: 0` ile kontrollü RollingUpdate yapılandırılmıştır (7.2'de detaylandırılmıştır).

### 3.3 Cloud dış erişim

- **AWS Load Balancer ve Gateway görseli:** `docs/screenshots/18-eks-external-access.png`
- **Backend healthcheck görseli:** `docs/screenshots/19-eks-backend-healthcheck.png`
- **Frontend dış erişim görseli:** `docs/screenshots/01-web-home.png`
- **Açıklama:** Envoy Gateway `LoadBalancer` Service üzerinden AWS Elastic Load Balancer ile internetten erişilebilir hale getirilmiştir. HTTPRoute ile `/` istekleri `frontend-service`'e, `/api` istekleri `backend-service`'e yönlendirilmiştir. Dışarıdan yapılan gerçek HTTP isteklerinde React frontend uygulaması ve backend `/api/healthcheck` endpoint'i başarıyla doğrulanmıştır.

## 4. Python ETL

### 4.1 İlk veri aktarımı

GitHub repository bilgilerinin MongoDB'ye ilk kez kaydedildiğini gösterin.

- **Görsel veya terminal çıktısı:** `docs/screenshots/20-etl-first-load.png`
- **Açıklama:** Python ETL, GitHub API üzerinden repository bilgisini alarak MongoDB'ye kaydetmektedir. İlk çalışmada repository için yeni kayıt oluşturulmuştur.

### 4.2 Aynı repository için güncelleme

Aynı repository tekrar işlendiğinde duplicate kayıt oluşmadığını ve mevcut kaydın güncellendiğini gösterin. Mümkünse repository sayısını ve güncellenen alanı aynı kanıt içinde belirtin.

- **Görsel veya terminal çıktısı:** `docs/screenshots/21-etl-update-without-duplicate.png`
- **Kullanılan benzersiz alan:** `github_id`
- **Açıklama:** Aynı repository tekrar işlendiğinde yeni bir MongoDB document oluşturulmamış, mevcut kayıt `github_id=1361100555` üzerinden güncellenmiştir. ETL logunda `UPDATE: repository updated (github_id=1361100555)` mesajı ve `MongoDB document count: 1` çıktısı görülmektedir. Bu durum duplicate oluşmadığını ve upsert/update mantığının çalıştığını göstermektedir.

### 4.3 EKS üzerinde ETL çalışması

- **Görsel veya terminal çıktısı:** `docs/screenshots/22-eks-etl-success.png`
- **Açıklama:** EKS üzerinde saatlik çalışan ETL CronJob tarafından oluşturulan Job'un başarıyla tamamlandığı doğrulanmıştır. Job kapsamında GitHub repository bilgisi alınmış, MongoDB bağlantısı kurulmuş ve mevcut repository `github_id` üzerinden güncellenmiştir. Container'ın Amazon ECR'daki commit SHA etiketli ETL image'ı ile çalıştığı ve Job'un `Completed` durumuna ulaştığı doğrulanmıştır.

## 5. CI/CD

- **Başarılı CI/CD pipeline görseli:** `docs/screenshots/23-cicd-pipeline-success.png`
- **CI build/validation aşamalarını gösteren görsel:** `docs/screenshots/24-build-validation-steps.png`
- **ECR push ve EKS deployment aşamalarını gösteren görsel:** `docs/screenshots/25-build-ecr-eks-deployment-steps.png`
- **Açıklama:** GitHub Actions üzerinde gerçek CI/CD pipeline başarıyla çalıştırılmıştır. CI aşamasında frontend build, backend validation, Python ETL validation ve Docker image build işlemleri gerçekleştirilmiştir. Ayrıca CI aşamasında oluşturulan frontend, backend ve Python ETL container image'ları Trivy ile güvenlik taramasından geçirilmektedir. Trivy; image içerisindeki OS paketleri ve uygulama dependency'leri için bilinen vulnerability'leri ve image içerisinde yanlışlıkla bulunabilecek secret bilgileri kontrol etmektedir. Tarama sonuçları GitHub Actions loglarında raporlanmaktadır. Mevcut case ortamında vulnerability bulguları raporlanmakta ancak `exit-code: 0` kullanıldığı için deployment otomatik olarak engellenmemektedir.

  `main` branch'ine yapılan push sonrasında `deploy-eks` job'ı çalışmaktadır. Workflow, GitHub OIDC ile AWS IAM Role'u assume etmekte, Docker image'larını commit SHA tag'i ile Amazon ECR'a push etmekte, EKS cluster'ına kubeconfig ile bağlanmakta ve Kubernetes Secret'larını güncellemektedir.

  Deployment aşamasında `k8s/overlays/prod` Kustomize overlay'i önce `kubectl apply --dry-run=server -k k8s/overlays/prod` ile doğrulanmakta, ardından `kubectl apply -k k8s/overlays/prod` ile EKS ortamına uygulanmaktadır. Sonrasında image'lar commit SHA tag'leri ile güncellenmekte ve backend, frontend ve ETL workload'larının rollout durumları kontrol edilmektedir.

  Deployment sonrasında Gateway ve HTTPRoute kaynakları doğrulanmakta ve AWS Load Balancer üzerinden backend healthcheck ile frontend erişimi otomatik olarak test edilmektedir.

  CI aşamasındaki bir build veya validation adımı başarısız olduğunda `deploy-eks` job'ı çalıştırılmamaktadır. Böylece yalnızca başarılı bir CI sonucundan sonra cloud deployment gerçekleştirilmektedir.

### 5.1 GitHub OIDC ve AWS authentication

- **Görsel:** `docs/screenshots/26-github-oidc-aws-auth.png`
- **Açıklama:** GitHub Actions'ın AWS erişimi için uzun ömürlü AWS access key kullanılmamıştır. GitHub OIDC üzerinden `GitHubActions-EKS-Deploy` IAM Role'u assume edilmekte ve workflow tarafından alınan geçici AWS kimlik bilgileri ile ECR ve EKS işlemleri gerçekleştirilmektedir.

### 5.2 EKS RBAC

- **Kubernetes RBAC görseli:** `docs/screenshots/27-eks-cd-rbac.png`
- **AWS EKS Access Entry görseli:** `docs/screenshots/28-access-entry.png`
- **Açıklama:** GitHub Actions IAM Role'u EKS Access Entry aracılığıyla `github-actions-deploy` Kubernetes grubuna bağlanmıştır. Bu grup için `devops-case` namespace'i ile sınırlı Role/RoleBinding tanımlanmıştır. GitHub Actions'a gereksiz `cluster-admin` yetkisi verilmemiştir.

## 6. Backup ve Restore

Aşağıdaki altı adımın tamamı kanıtlanmalıdır. Adımların aynı kayıt üzerinde ve sırayla yapıldığı anlaşılmalıdır.

Bu bölümdeki 6.1–6.6 adımları, backup ve restore mekanizmasının gerçek veri üzerinde uçtan uca doğrulandığı **manuel uçtan uca test senaryosunu** göstermektedir.

Production ortamındaki düzenli backup mekanizması ise ayrıca **7.7 – Üst Kriter #7** altında gösterilen otomatik EKS CronJob → Amazon S3 akışıdır.

Aşağıdaki altı adım aynı `sample_training` database'i üzerinde ve sırayla gerçekleştirilmiştir.

### 6.0 Backup/Restore Script

- **Script:** `scripts/backup-restore.ps1`
- **Açıklama:** Backup ve restore işlemleri repository içerisinde bulunan PowerShell script'i üzerinden manuel olarak tekrarlanabilir şekilde çalıştırılabilir. `-Action Backup` ve `-Action Restore -DropExisting` senaryoları başarıyla test edilmiştir.

```powershell
.\scripts\backup-restore.ps1 -Action Backup

.\scripts\backup-restore.ps1 -Action Restore
```

Mevcut collection'ların üzerine restore edilmesi gerektiğinde:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

Script gerçek credential içermemekte; MongoDB bağlantı bilgisini local `.env` içerisindeki `ATLAS_URI` değerinden almaktadır.

Bu script, production'daki günlük otomatik S3 backup mekanizmasından bağımsız olarak **manuel backup/restore uçtan uca testi** amacıyla kullanılmaktadır.

### 6.1 Kayıt oluşturma

- **Görsel 1:** `docs/screenshots/29-backup-record-created-01.png`
- **Görsel 2:** `docs/screenshots/30-backup-record-created-02.png`
- **Açıklama:** Backup senaryosu başlatılmadan önce uygulama verilerinin mevcut olduğu doğrulanmıştır. MongoDB Atlas üzerinde `sample_training` database'i ve ilgili collection'lar görüntülenmiştir. Backup senaryosunda toplam 2 document bulunmaktadır: `records` collection'ında 1 document ve `github_repositories` collection'ında 1 document.

### 6.2 Yedek alma

- **Görsel veya terminal çıktısı:** `docs/screenshots/31-backup-taken.png`
- **Kullanılan yöntem ve komutlar (3 komut, sırasıyla, proje kökünden):**

MongoDB Database Tools `mongodump` kullanılmıştır. Manuel uçtan uca testinde backup işlemi aşağıdaki yöntemle gerçekleştirilmiştir:

```powershell
New-Item -ItemType Directory -Path ".\backups" -Force

$atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''

& "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" `
  --uri="$atlasUri" `
  --db=sample_training `
  --out=".\backups\sample-training-backup"
```

Script de aynı `mongodump` yöntemini kullanmaktadır. Bu local backup işlemi yalnızca uçtan uca backup/restore testinin bir parçasıdır.

- **Yedeğin saklandığı konum:** `backups/sample-training-backup`
- **Açıklama:** Tüm `sample_training` database'i yedeklenmiştir. Backup çıktısında `sample_training.records` için 1 document ve `sample_training.github_repositories` için 1 document yedeklendiği görülmektedir.

Production ortamındaki otomatik backup'lar ise local `backups/` dizininde değil, Amazon S3 üzerinde timestamp'li archive dosyaları olarak saklanmaktadır. Bu yapı 7.7'de gösterilmektedir.

### 6.3 Collection veya veritabanının silinmesi

- **Görsel veya terminal çıktısı:** `docs/screenshots/32-collection-dropped.png`
- **Açıklama:** `sample_training` database'i MongoDB Atlas üzerinden tamamen silinmiştir.

### 6.4 Verinin kaybolduğunun gösterilmesi

- **Arayüz görseli:** `docs/screenshots/33-data-missing-after-drop-ui.png`
- **Veritabanı çıktısı:** `docs/screenshots/34-data-missing-after-drop-database.png`
- **Açıklama:** Database silindikten sonra uygulamanın `/records` ekranında kayıtların artık görüntülenmediği ve MongoDB Atlas üzerinde `sample_training` database'inin bulunmadığı doğrulanmıştır.

### 6.5 Yedekten geri yükleme

- **Görsel veya terminal çıktısı:** `docs/screenshots/35-restore-executed.png`
- **Ölçülen geri yükleme süresi:** Restore komutu yaklaşık 1.3 saniye içerisinde tamamlanmıştır. Bu değer yalnızca restore komutunun çalışma süresini göstermektedir; uçtan uca production RTO olarak değerlendirilmemiştir.
- **Açıklama:** `mongorestore` kullanılarak `sample_training` database'i manuel uçtan uca testinde alınan backup'tan geri yüklenmiştir. Restore sonucunda toplam 2 document başarıyla geri yüklenmiş ve 0 document restore hatası alınmıştır.

### 6.6 Verinin geri geldiğinin doğrulanması

- **Arayüz görseli:** `docs/screenshots/36-data-restored-verified-ui.png`
- **Veritabanı çıktısı (1):** `docs/screenshots/37-data-restored-verified-database-01.png`
- **Veritabanı çıktısı (2):** `docs/screenshots/38-data-restored-verified-database-02.png`
- **Açıklama:** Restore işleminden sonra `sample_training.records` ve `sample_training.github_repositories` collection'larının yeniden oluşturulduğu ve önceki verilerin MongoDB Atlas ile web arayüzünde tekrar erişilebilir olduğu doğrulanmıştır.

> Runbook, RPO/RTO hedefleri, backup schedule ve retention sınırlamaları `docs/backup-restore.md` içinde dokümante edilmiştir.

---

## 7. Logging, Monitoring ve Üst Kriterler

Uyguladığınız logging, monitoring, alarm, Helm, Terraform, güvenlik taraması veya diğer üst kriterlere ait kanıtları ekleyin.

Uygulanan logging, monitoring, alarm, güvenlik ve diğer üst kriterlere ait kanıtlar aşağıda verilmiştir.

### 7.1 Üst Kriter #2 - Paketleme ve Ortam Yönetimi: Kustomize

- **Backend environment kanıtı:** `docs/screenshots/39-kustomize-backend-dev-test-prod.png`
- **Frontend environment kanıtı:** `docs/screenshots/40-kustomize-frontend-dev-test-prod.png`
- **Açıklama:** Kubernetes kaynakları Kustomize kullanılarak base ve environment overlay yapısında yönetilmektedir. Ortak kaynaklar `k8s/eks/` altında tutulmakta, `k8s/overlays/dev`, `k8s/overlays/test` ve `k8s/overlays/prod` altında ortam bazlı farklılıklar tanımlanmaktadır.

  Backend ve frontend için CPU request değerleri dev/test/prod ortamlarında sırasıyla `50m / 75m / 100m` olarak yapılandırılmış, memory request ise tek `t3.small` worker node üzerinde scheduling sorunlarını önlemek amacıyla tüm ortamlarda `32Mi` olarak tutulmuştur. Deployment replica sayısı mevcut Free Tier / tek node kapasitesi nedeniyle tüm ortamlarda `1` olarak bırakılmıştır.

  Ortamlar arasında değişmesi gerekmeyen ETL CronJob yapılandırması ortak base üzerinden yönetilmektedir. Secret değerleri ise düz metin olarak Kustomize dosyalarına yazılmayıp Kubernetes Secret kaynakları üzerinden sağlanmaktadır.

  AWS EKS deployment'ında production ortamı için `k8s/overlays/prod` kullanılmıştır. Kustomize çıktısı deployment öncesinde server-side dry-run ile doğrulanmakta ve ardından `kubectl apply -k k8s/overlays/prod` ile uygulanmaktadır.

  `GatewayClass` cluster-scoped bir kaynak olduğu ve GitHub Actions'ın namespace ile sınırlı RBAC yetkileri kullandığı için Kustomize base içerisine dahil edilmemiştir. EKS cluster'ında mevcut olan GatewayClass kullanılmaktadır; böylece deployment için gereksiz cluster-wide yetki verilmemiştir.

### 7.2 Üst Kriter #3 - Yüksek Erişilebilirlik ve Ölçekleme: Rolling Update ve Kapasite Yaklaşımı

- **Health check ve resource yapılandırması ekran görüntüleri:**

  - `docs/screenshots/41-eks-healthchecks-resources-backend.png`
  - `docs/screenshots/42-eks-healthchecks-resources-frontend.png`
  - `docs/screenshots/43-eks-cpu-memory-limits-etl.png`

- **Rolling update görseli:** `docs/screenshots/44-eks-rolling-update.png`
- **Açıklama:** Kubernetes workload'larında CPU ve memory resource requests/limits tanımlanmıştır. Backend Deployment'ında `maxSurge: 1` ve `maxUnavailable: 0` değerleri kullanılarak kontrollü bir `RollingUpdate` stratejisi uygulanmıştır. Deployment sırasında yeni Pod önce oluşturulmakta ve readiness probe ile hazır olduğu doğrulanmadan eski Pod sonlandırılmamaktadır. Böylece sürüm geçişi `v1 → v1 + v2 → v2` şeklinde gerçekleşmektedir. Bu davranış EKS ortamında gerçek rollout sırasında doğrulanmış ve `docs/screenshots/44-eks-rolling-update.png` ile kanıtlanmıştır.

### 7.3 Üst Kriter #4 - İleri Gözlemlenebilirlik: Doğrulanmış Alarm Senaryoları

- **Alert kontrolü ve test görseli:** `docs/screenshots/45-alerts-check.png`
- **Alert tanımı:** `scripts/check-alerts.ps1`
- **Açıklama:** `check-alerts.ps1` script'i iki kritik olay için çalıştırılabilir alarm kontrolü sağlamaktadır. `ALERT-001`, ETL CronJob'un başarısız olup olmadığını veya beklenen zaman aralığında başarılı bir çalışmanın bulunup bulunmadığını kontrol etmektedir. `ALERT-002`, frontend veya backend health endpoint'lerinin erişilememesi durumunu kontrol etmektedir. Test modunda her iki alarm da bilinçli olarak tetiklenmiş ve script `exit code 1` ile sonlandırılmıştır. Sistem sağlıklı durumdayken gerçekleştirilen normal kontrolde ise kritik alarm üretilmemiş ve script başarılı şekilde sonlanmıştır.

### 7.4 Üst Kriter #5 - İleri Güvenlik: Image / Dependency / Secret Taraması

- **Trivy container security scan görseli:** `docs/screenshots/46-trivy-security-scan.png`
- **Açıklama:** Frontend, backend ve Python ETL container image'ları GitHub Actions CI pipeline'ının bir parçası olarak Trivy kullanılarak taranmaktadır. Tarama kapsamında OS paketleri, uygulama dependency'leri ve image içerisinde bulunabilecek secret bilgiler kontrol edilmektedir. Tarama sonuçları GitHub Actions loglarında raporlanmakta ve mevcut case yapılandırmasında vulnerability bulguları deployment'ı otomatik olarak engellememektedir.

### 7.5 Üst Kriter #7 - İleri Felaket Kurtarma: Off-Cluster Scheduled Backup

- **Otomatik backup ve S3 kanıtı:** `docs/screenshots/47-backup-cronjob-scheduled-success.png`
- **Açıklama:** MongoDB Atlas verilerinin cluster dışında tutulmasını sağlayan otomatik backup mekanizması AWS EKS üzerinde `mongodb-backup` Kubernetes CronJob ile çalışmaktadır. CronJob `0 2 * * *` schedule'ı (Saat 02.00'de) ve `Europe/Istanbul` timezone'u ile günlük olarak çalışacak şekilde yapılandırılmıştır.

  Backup workload'u `mongodump` ile `sample_training` database'ini `.archive.gz` formatında yedeklemekte ve timestamp'li arşiv dosyasını Amazon S3 üzerindeki `sample_training/` prefix'ine yüklemektedir.

  Her backup ayrı bir object olarak saklandığından önceki backup'ların üzerine yazılmamaktadır. Backup dosyasının boş olmadığı `test -s` ile kontrol edilmekte, S3 upload sonrasında `aws s3api head-object` ile object'ın başarıyla oluşturulduğu doğrulanmaktadır.

  Backup workload'u ayrı `s3-backup` ServiceAccount kullanmakta ve gerekli S3 erişimi least-privilege IAM policy ile sınırlandırılmaktadır. Backup container'ları ayrıca non-root ve privilege escalation kapalı şekilde çalıştırılmaktadır.

  Otomatik backup'ın gerçek scheduled Job üzerinden başarıyla çalıştığı ve backup çıktısının S3'e gönderildiği `docs/screenshots/47-backup-cronjob-scheduled-success.png` kanıtı ile gösterilmektedir.

  Bu mekanizma case kapsamındaki manuel uçtan uca backup/restore testinden ayrıdır. Manuel test, backup'ın geri yüklenebilir olduğunu doğrularken; bu otomatik mekanizma düzenli ve cluster dışı backup storage gereksinimini karşılamaktadır.

  Bu case kapsamında S3 Lifecycle tabanlı otomatik retention/silme politikası, PITR, otomatik restore verification ve periyodik tam DR drill uygulanmamıştır. Mevcut backup schedule, storage yaklaşımı, restore yöntemi, RPO/RTO değerlendirmesi ve sınırlamalar `docs/backup-restore.md` içerisinde detaylandırılmıştır.

### 7.6 ETL Logging

- **ETL log görseli:** `docs/screenshots/21-etl-update-without-duplicate.png`
- **Açıklama:** Kubernetes üzerinde çalışan ETL CronJob'un logları GitHub repository'sinin alınmasını, MongoDB bağlantısını, mevcut repository'nin `github_id` kullanılarak güncellenmesini, document count kontrolünü ve ETL işleminin başarıyla tamamlanmasını göstermektedir.

### 7.7 ETL Scheduling
- **EKS CronJob schedule görseli:** `docs/screenshots/48-eks-cronjob-schedule.png`
- **Açıklama:** EKS üzerinde çalışan `etl` CronJob'un saatlik çalışmak üzere `0 * * * *` schedule'ını ve `Europe/Istanbul` timezone'unu kullandığı gösterilmektedir.

## 8. Ek Kanıtlar

### 8.1 Kubernetes Güvenlik Sertleştirmesi

- **Backend non-root kanıtı:** `docs/screenshots/49-backend-non-root-kubernetes.png`
- **Frontend non-root kanıtı:** `docs/screenshots/50-frontend-non-root-kubernetes.png`
- **ETL non-root kanıtı:** `docs/screenshots/51-etl-non-root-kubernetes.png`
- **Açıklama:** Kubernetes workload'larının root kullanıcıyla çalışmadığı doğrulanmıştır. Backend `node` (UID 1000), frontend `nginx` (UID 101) ve ETL `appuser` (UID 10001) olarak çalışmaktadır. Ayrıca `allowPrivilegeEscalation` devre dışı bırakılmış ve tüm Linux capabilities drop edilmiştir.

### 8.2 AWS / EKS Deployment Yapılandırması

- **EKS cluster ve node durumu:** `docs/screenshots/52-eks-cluster-config.png`
- **EKS managed node group yapılandırması:** `docs/screenshots/53-eks-node-group-config.png`
- **Açıklama:** `devops-case-eks` EKS cluster'ının `eu-central-1` region'ında çalıştığı ve `Ready` durumunda bir worker node'a sahip olduğu gösterilmektedir. Çalışan node Kubernetes `v1.36.3` ve Amazon Linux 2023 kullanmaktadır. EKS managed node group'u `devops-workers` adıyla ve `t3.small` instance type'ı kullanılarak 1 adet desired node ile yapılandırılmıştır. Cluster ve node group yapılandırması repository içerisindeki `eks-cluster.yaml` dosyasında tanımlanmıştır. Kubernetes workload'larının ortam bazlı yapılandırması Kustomize overlay'leri ile yönetilmekte ve production deployment `k8s/overlays/prod` üzerinden gerçekleştirilmektedir.
