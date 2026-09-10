# TESLİM KANITLARI

Teslimin başarılı şekilde tamamlanmış sayılabilmesi için çalışan sisteme ait ekran görüntülerini `docs/screenshots/` klasörüne ekleyin ve aşağıdaki maddelerde ilgili dosya yolunu belirtin.

Ekran görüntülerinde gerçek credential, token, parola, private key veya hassas bağlantı bilgileri görünmemelidir.

---

## 1. Web Uygulaması

### 1.1 Ana sayfa

* **Görsel:** `docs/screenshots/01-web-home.png`

* **Açıklama:**
  React frontend uygulamasının erişilebilir ve çalışır durumda olduğu gösterilmektedir. Ana sayfa üzerinden uygulamanın temel kullanıcı akışlarına erişilebilmektedir.

### 1.2 Create işlemi

* **Form görseli:** `docs/screenshots/02-record-create-form.png`

* **Başarılı sonuç görseli:** `docs/screenshots/03-record-created.png`

* **Açıklama:**
  Yeni bir kayıt oluşturma formu doldurulmuş ve create işlemi başarıyla gerçekleştirilmiştir. Oluşturulan kayıt `/records` ekranında doğrulanmıştır.

### 1.3 Edit işlemi

* **İşlem öncesi görseli:** `docs/screenshots/04-record-edit-before.png`

* **İşlem sonrası görseli:** `docs/screenshots/05-record-edit-after.png`

* **Açıklama:**
  Mevcut kayıt edit formu üzerinden güncellenmiştir. Güncelleme sonrasında yeni değerlerin `/records` ekranında görüntülendiği doğrulanmıştır.

---

## 2. Docker

* **Kubernetes image build görseli:** `docs/screenshots/06-docker-images-kubernetes-build.png`

* **Compose image build görseli:** `docs/screenshots/07-docker-images-compose-build.png`

* **Çalışan container görseli:** `docs/screenshots/08-docker-images-compose-and-kubernetes.png`

* **Açıklama:**
  Frontend, backend ve Python ETL için Docker image'larının başarıyla oluşturulduğu ve container ortamlarında çalıştırılabildiği gösterilmektedir. Aynı uygulama image'larının AWS EKS deployment'ı için Amazon ECR'a da push edildiği CI/CD kanıtlarında ayrıca gösterilmektedir.

---

## 3. Kubernetes

### 3.1 Local Kubernetes

* **Pod/workload durumu:** `docs/screenshots/09-kubernetes-workloads.png`

* **Service ve Gateway durumu:** `docs/screenshots/10-kubernetes-services-gateway.png`

* **ETL CronJob/Job durumu:** `docs/screenshots/11-etl-cronjob-job.png`

* **Açıklama:**
  Uygulama local Kubernetes ortamında `devops-case` namespace'i içerisinde çalıştırılmıştır. Frontend ve backend Deployment/Service kaynakları oluşturulmuş, Python ETL ise saatlik çalışan bir CronJob olarak yapılandırılmıştır. Envoy Gateway ve HTTPRoute üzerinden uygulama içi yönlendirme sağlanmıştır.

### 3.2 AWS EKS

* **EKS cluster ve node durumu:** `docs/screenshots/12-eks-cluster-node.png`

* **EKS workload durumu:** `docs/screenshots/13-eks-workloads.png`

* **Service ve Gateway durumu:** `docs/screenshots/14-eks-services-gateway.png`

* **ECR image'ları (backend):** `docs/screenshots/15-ecr-images-backend.png`

* **ECR image'ları (frontend):** `docs/screenshots/16-ecr-images-frontend.png`

* **ECR image'ları (etl):** `docs/screenshots/17-ecr-images-etl.png`

* **Açıklama:**
  Uygulama AWS EKS üzerinde `devops-case-eks` cluster'ına deploy edilmiştir. Backend ve frontend Deployment'ları, Service kaynakları ve Python ETL CronJob'u EKS üzerinde çalışmaktadır. Container image'ları Amazon ECR üzerinden çekilmektedir.

### 3.3 Cloud dış erişim

* **AWS Load Balancer ve Gateway görseli:** `docs/screenshots/18-eks-external-access.png`

* **Backend healthcheck görseli:** `docs/screenshots/19-eks-backend-healthcheck.png`

* **Frontend dış erişim görseli:** `docs/screenshots/01-web-home.png`

* **Açıklama:**
  Envoy Gateway `LoadBalancer` Service üzerinden AWS Elastic Load Balancer ile internetten erişilebilir hale getirilmiştir. HTTPRoute ile `/` istekleri frontend-service'e, `/api` istekleri backend-service'e yönlendirilmiştir. Dışarıdan yapılan gerçek HTTP isteklerinde React frontend uygulaması ve backend `/api/healthcheck` endpoint'i başarıyla doğrulanmıştır.

---

## 4. Python ETL

### 4.1 İlk veri aktarımı

GitHub repository bilgilerinin MongoDB'ye ilk kez kaydedildiğini gösterin.

* **Görsel veya terminal çıktısı:** `docs/screenshots/20-etl-first-load.png`

* **Açıklama:**
  Python ETL, GitHub API üzerinden repository bilgisini alarak MongoDB'ye kaydetmektedir. İlk çalışmada repository için yeni kayıt oluşturulmuştur.

### 4.2 Aynı repository için güncelleme

Aynı repository tekrar işlendiğinde duplicate kayıt oluşmadığını ve mevcut kaydın güncellendiğini gösterin. Mümkünse repository sayısını ve güncellenen alanı aynı kanıt içinde belirtin.

* **Görsel veya terminal çıktısı:** `docs/screenshots/21-etl-update-without-duplicate.png`

* **Kullanılan benzersiz alan:** `github_id`

* **Açıklama:**
  Aynı repository tekrar işlendiğinde yeni bir MongoDB document oluşturulmamış, mevcut kayıt `github_id=1361100555` üzerinden güncellenmiştir. ETL logunda `UPDATE: repository updated (github_id=1361100555)` mesajı ve `MongoDB document count: 1` çıktısı görülmektedir. Bu durum duplicate oluşmadığını ve upsert/update mantığının çalıştığını göstermektedir.

### 4.3 EKS üzerinde ETL çalışması

* **Görsel veya terminal çıktısı:** `docs/screenshots/22-eks-etl-success.png`

* **Açıklama:**
  EKS üzerinde saatlik çalışan ETL CronJob tarafından oluşturulan Job'un başarıyla tamamlandığı doğrulanmıştır. Job kapsamında GitHub repository bilgisi alınmış, MongoDB bağlantısı kurulmuş ve mevcut repository `github_id` üzerinden güncellenmiştir. Container'ın Amazon ECR'daki commit SHA etiketli ETL image'ı ile çalıştığı ve Job'un `Completed` durumuna ulaştığı doğrulanmıştır.

---

## 5. CI/CD

* **Başarılı CI/CD pipeline görseli:** `docs/screenshots/23-cicd-pipeline-success.png`

* **CI build/validation aşamalarını gösteren görsel:** `docs/screenshots/24-build-validation-steps.png`

* **ECR push ve EKS deployment aşamalarını gösteren görsel:** `docs/screenshots/25-build-ecr-eks-deployment-steps.png`

* **Açıklama:**
  GitHub Actions üzerinde gerçek CI/CD pipeline başarıyla çalıştırılmıştır. CI aşamasında frontend build, backend validation, Python ETL validation ve Docker image build işlemleri gerçekleştirilmiştir.

  `main` branch'ine yapılan push sonrasında `deploy-eks` job'ı çalışmaktadır. Workflow, GitHub OIDC ile AWS IAM Role'u assume etmekte, Docker image'larını commit SHA tag'i ile Amazon ECR'a push etmekte, EKS cluster'ına kubeconfig ile bağlanmakta, Kubernetes Secret'larını güncellemekte ve `k8s/eks/` altındaki Service, Deployment ve CronJob kaynaklarını uygulamaktadır.

  Deployment sonrasında backend ve frontend için rollout durumu kontrol edilmekte, Gateway ve HTTPRoute kaynakları doğrulanmakta ve AWS Load Balancer üzerinden backend healthcheck ile frontend erişimi otomatik olarak test edilmektedir.

  CI aşamasındaki bir build veya validation adımı başarısız olduğunda `deploy-eks` job'ı çalıştırılmamaktadır. Böylece yalnızca başarılı bir CI sonucundan sonra cloud deployment gerçekleştirilmektedir.

### 5.1 GitHub OIDC ve AWS authentication

* **OIDC / başarılı AWS authentication görseli:** `docs/screenshots/26-github-oidc-aws-auth.png`

* **Açıklama:**
  GitHub Actions'ın AWS erişimi için uzun ömürlü AWS access key kullanılmamıştır. GitHub OIDC üzerinden `GitHubActions-EKS-Deploy` IAM Role'u assume edilmekte ve workflow tarafından alınan geçici AWS kimlik bilgileri ile ECR ve EKS işlemleri gerçekleştirilmektedir.

### 5.2 EKS RBAC

* **Kubernetes RBAC görseli:** `docs/screenshots/27-eks-cd-rbac.png`

* **AWS EKS Access Entry görseli:** `docs/screenshots/28-access-entry.png`

* **Açıklama:**
  GitHub Actions IAM Role'u EKS Access Entry aracılığıyla `github-actions-deploy` Kubernetes grubuna bağlanmıştır. Bu grup için `devops-case` namespace'i ile sınırlı Role/RoleBinding tanımlanmıştır. GitHub Actions'a gereksiz `cluster-admin` yetkisi verilmemiştir.

---

## 6. Backup ve Restore

Aşağıdaki altı adımın tamamı aynı `sample_training` database'i üzerinde ve sırayla gerçekleştirilmiştir.

### 6.1 Kayıt oluşturma

* **Görsel 1:** `docs/screenshots/29-backup-record-created-01.png`

* **Görsel 2:** `docs/screenshots/30-backup-record-created-02.png`

* **Açıklama:**
  Backup senaryosu başlatılmadan önce uygulama verilerinin mevcut olduğu doğrulanmıştır. MongoDB Atlas üzerinde `sample_training` database'i ve ilgili collection'lar görüntülenmiştir. Backup senaryosunda toplam 3 document bulunmaktadır: `records` collection'ında 2 document ve `github_repositories` collection'ında 1 document.

### 6.2 Yedek alma

* **Görsel veya terminal çıktısı:** `docs/screenshots/31-backup-taken.png`

* **Kullanılan yöntem ve komutlar (3 komut, sırasıyla, proje kökünden):**

MongoDB Database Tools `mongodump` kullanılmıştır:

```powershell
New-Item -ItemType Directory -Path ".\backups" -Force

$atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''

& "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" `
  --uri="$atlasUri" `
  --db=sample_training `
  --out=".\backups\sample-training-backup"
```

* **Yedeğin saklandığı konum:**
  `backups/sample-training-backup`

* **Açıklama:**
  Tüm `sample_training` database'i yedeklenmiştir. Backup çıktısında `sample_training.records` için 2 document ve `sample_training.github_repositories` için 1 document yedeklendiği görülmektedir.

### 6.3 Collection veya veritabanının silinmesi

* **Görsel veya terminal çıktısı:** `docs/screenshots/32-collection-dropped.png`

* **Açıklama:**
  `sample_training` database'i MongoDB Atlas üzerinden tamamen silinmiştir.

### 6.4 Verinin kaybolduğunun gösterilmesi

* **Arayüz görseli:** `docs/screenshots/33-data-missing-after-drop-ui.png`

* **Veritabanı çıktısı:** `docs/screenshots/34-data-missing-after-drop-database.png`

* **Açıklama:**
  Database silindikten sonra uygulamanın `/records` ekranında kayıtların artık görüntülenmediği ve MongoDB Atlas üzerinde `sample_training` database'inin bulunmadığı doğrulanmıştır.

### 6.5 Yedekten geri yükleme

* **Görsel veya terminal çıktısı:** `docs/screenshots/35-restore-executed.png`

* **Ölçülen geri yükleme süresi:**
  Restore komutu yaklaşık 1.3 saniye içerisinde tamamlanmıştır. Bu değer yalnızca restore komutunun çalışma süresini göstermektedir; uçtan uca production RTO olarak değerlendirilmemiştir.

* **Açıklama:**
  `mongorestore` kullanılarak `sample_training` database'i backup'tan geri yüklenmiştir. Restore sonucunda toplam 3 document başarıyla geri yüklenmiş ve 0 document restore hatası alınmıştır.

### 6.6 Verinin geri geldiğinin doğrulanması

* **Arayüz görseli:** `docs/screenshots/36-data-restored-verified-ui.png`

* **Veritabanı çıktısı (1):** `docs/screenshots/37-data-restored-verified-database-01.png`

* **Veritabanı çıktısı (2):** `docs/screenshots/38-data-restored-verified-database-02.png`

* **Açıklama:**
  Restore işleminden sonra `sample_training.records` ve `sample_training.github_repositories` collection'larının yeniden oluşturulduğu ve önceki verilerin MongoDB Atlas ile web arayüzünde tekrar erişilebilir olduğu doğrulanmıştır.

> Runbook, RPO/RTO hedefleri ve retention süresi `docs/backup-restore.md` içinde dokümante edilmiştir.

---

## 7. Logging, Monitoring ve Üst Kriterler

Uygulanan logging, monitoring, alarm, güvenlik ve diğer üst kriterlere ait kanıtlar aşağıda verilmiştir.

* **ETL log görseli:** `docs/screenshots/21-etl-update-without-duplicate.png`

* **Açıklama:**
  Kubernetes üzerinde çalışan ETL CronJob'un logları GitHub repository'sinin alınmasını, MongoDB bağlantısını, mevcut repository'nin `github_id` üzerinden güncellenmesini, document count kontrolünü ve ETL işleminin başarıyla tamamlanmasını göstermektedir.

* **EKS CronJob schedule görseli:** `docs/screenshots/39-eks-cronjob-schedule.png`

* **Açıklama:**
  EKS üzerinde çalışan `etl` CronJob'un `0 * * * *` schedule'ı ile saatlik çalıştığı ve `Europe/Istanbul` timezone kullanacak şekilde yapılandırıldığı gösterilmektedir.

---

## 8. Ek Kanıtlar

### 8.1 Critical Alerts

* **Alert kontrolü ve test görseli:** `docs/screenshots/40-alerts-check.png`

* **Alert tanımı:** `scripts/check-alerts.ps1`

* **Açıklama:**
  `check-alerts.ps1` script'i iki kritik olay için çalıştırılabilir alarm kontrolü sağlamaktadır. `ALERT-001` ETL CronJob'un başarısız olması veya beklenen zaman aralığında başarılı bir çalışmanın bulunmaması durumunu, `ALERT-002` ise frontend veya backend health endpoint'lerinin erişilememesi durumunu kontrol etmektedir. Test modunda her iki alarm da bilinçli olarak tetiklenmiş ve script `exit code 1` ile sonlandırılmıştır. Sistem sağlıklı durumdayken gerçekleştirilen normal kontrolde ise kritik alarm üretilmemiş ve script başarılı şekilde sonlanmıştır.

### 8.2 Kubernetes Security Hardening

* **Backend non-root kanıtı:** `docs/screenshots/41-backend-non-root-kubernetes.png`

* **Frontend non-root kanıtı:** `docs/screenshots/42-frontend-non-root-kubernetes.png`

* **ETL non-root kanıtı:** `docs/screenshots/43-etl-non-root-kubernetes.png`

* **Açıklama:**
  Kubernetes workload'larında container'ların root kullanıcıyla çalışmadığı doğrulanmıştır. Backend `node` (UID 1000), frontend `nginx` (UID 101) ve ETL `appuser` (UID 10001) olarak çalışmaktadır. Ayrıca `allowPrivilegeEscalation` devre dışı bırakılmış ve tüm Linux capabilities drop edilmiştir.

### 8.3 AWS / EKS deployment configuration

- **EKS cluster ve node durumu:** `docs/screenshots/44-eks-cluster-config.png`

- **EKS managed node group configuration:** `docs/screenshots/45-eks-node-group-config.png`

- **Açıklama:**  
  AWS üzerinde `devops-case-eks` adlı EKS cluster'ının `eu-central-1` region'ında çalıştığı ve cluster üzerinde `Ready` durumunda bir worker node bulunduğu doğrulanmıştır. Çalışan node Kubernetes `v1.36.3` kullanmakta ve Amazon Linux 2023 üzerinde çalışmaktadır. EKS managed node group'unun `devops-workers` adıyla ve `t3.small` instance type'ı kullanılarak 1 adet desired node ile yapılandırıldığı ayrıca doğrulanmıştır. Cluster ve node group yapılandırması repository içerisindeki `eks-cluster.yaml` dosyasında tanımlanmıştır.