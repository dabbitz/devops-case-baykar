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

- **İşlem öncesi görsel:** `docs/screenshots/04-record-edit-before.png`
- **İşlem sonrası görsel:** `docs/screenshots/05-record-edit-after.png`
- **Açıklama:** Mevcut kayıt edit formu üzerinden güncellenmiştir. Güncelleme sonrasında yeni değerlerin `/records` ekranında görüntülendiği doğrulanmıştır.

## 2. Docker

- **Kubernetes image build görseli:** `docs/screenshots/06-docker-images-kubernetes-build.png`
- **Compose image build görseli:** `docs/screenshots/07-docker-images-compose-build.png`
- **Çalışan container görseli:** `docs/screenshots/08-docker-images-compose-and-kubernetes.png`
- **Açıklama:** Frontend, backend ve Python ETL için Docker image'larının başarıyla oluşturulduğu ve container ortamında çalıştırılabildiği gösterilmektedir.

## 3. Kubernetes

- **Pod/workload durumu:** `docs/screenshots/09-kubernetes-workloads.png`
- **Service ve varsa Ingress durumu:** `docs/screenshots/10-kubernetes-services-gateway.png`
- **ETL CronJob/Job durumu:** `docs/screenshots/11-etl-cronjob-job.png`
- **Açıklama:** Uygulama Kubernetes üzerinde namespace içerisinde çalıştırılmıştır. Frontend ve backend Deployment/Service kaynakları oluşturulmuş, Python ETL ise saatlik çalışan bir CronJob olarak yapılandırılmıştır. Envoy Gateway ve HTTPRoute üzerinden dış erişim sağlanmıştır.

## 4. Python ETL

### 4.1 İlk veri aktarımı

GitHub repository bilgilerinin MongoDB’ye ilk kez kaydedildiğini gösterin.

- **Görsel veya terminal çıktısı:** `docs/screenshots/12-etl-first-load.png`
- **Açıklama:** Python ETL, GitHub API üzerinden repository bilgisini alarak MongoDB'ye kaydetmektedir. İlk çalışmada repository için yeni kayıt oluşturulmuştur.

### 4.2 Aynı repository için güncelleme

Aynı repository tekrar işlendiğinde duplicate kayıt oluşmadığını ve mevcut kaydın güncellendiğini gösterin. Mümkünse repository sayısını ve güncellenen alanı aynı kanıt içinde belirtin.

- **Görsel veya terminal çıktısı:** `docs/screenshots/13-etl-update-without-duplicate.png`
- **Kullanılan benzersiz alan:** `github_id`
- **Açıklama:** Aynı repository tekrar işlendiğinde yeni bir MongoDB document oluşturulmamış, mevcut kayıt `github_id=1361100555` üzerinden güncellenmiştir. ETL logunda `UPDATE: repository updated` mesajı ve `MongoDB document count: 1` çıktısı görülmektedir. Bu durum duplicate oluşmadığını ve upsert/update mantığının çalıştığını göstermektedir.

## 5. CI/CD

- **Başarılı pipeline görseli:** `docs/screenshots/14-cicd-pipeline-success.png`
- **Build/image/deployment aşamalarını gösteren görsel:** `docs/screenshots/15-build-image-steps.png`
- **Açıklama:** GitHub Actions üzerinde CI pipeline başarıyla çalıştırılmıştır. Pipeline frontend build, backend validation, Python ETL validation ve Docker image build aşamalarını otomatik olarak gerçekleştirmiştir. Herhangi bir aşamanın başarısız olması durumunda job başarısız olarak sonuçlanmaktadır.

## 6. Backup ve Restore

Aşağıdaki altı adımın tamamı kanıtlanmalıdır. Adımların aynı kayıt üzerinde ve sırayla yapıldığı anlaşılmalıdır.

### 6.1 Kayıt oluşturma

- **Görsel 1:** `docs/screenshots/16-backup-record-created-01.png`
- **Görsel 2:** `docs/screenshots/17-backup-record-created-02.png`
- **Açıklama:** Backup senaryosu başlatılmadan önce uygulama verilerinin mevcut olduğu doğrulanmıştır. MongoDB Atlas üzerinde `sample_training` database'i ve ilgili collection'lar görüntülenmiştir.

### 6.2 Yedek alma

- **Görsel veya terminal çıktısı:** `docs/screenshots/18-backup-taken.png`
- **Kullanılan yöntem ve komutlar (3 komut, sırasıyla, proje kökünden):** MongoDB Database Tools mongodump kullanılmıştır:

- - New-Item -ItemType Directory -Path ".\backups" -Force

- - $atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''

- - "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" "
    --uri="$atlasUri" '
    --db=sample_training '
    --out=".\backups\sample-training-backup"
- **Yedeğin saklandığı konum:** `backups/sample-training-backup`
- **Açıklama:** Tüm `sample_training` database'i yedeklenmiştir. Backup çıktısında `sample_training.records` ve `sample_training.github_repositories` için birer document yedeklendiği görülmektedir.

### 6.3 Collection veya veritabanının silinmesi

- **Görsel veya terminal çıktısı:** `docs/screenshots/19-collection-dropped.png`
- **Açıklama:** `sample_training` database'i MongoDB Atlas üzerinden tamamen silinmiştir.

### 6.4 Verinin kaybolduğunun gösterilmesi

- **Arayüz görseli:** `docs/screenshots/20-data-missing-after-drop-ui.png`
- **Veritabanı çıktısı:** `docs/screenshots/21-data-missing-after-drop-database.png`
- **Açıklama:** Database silindikten sonra uygulamanın `/records` ekranında kayıtların artık görüntülenmediği ve MongoDB Atlas üzerinde `sample_training` database'inin bulunmadığı doğrulanmıştır.

### 6.5 Yedekten geri yükleme

- **Görsel veya terminal çıktısı:** `docs/screenshots/22-restore-executed.png`
- **Ölçülen geri yükleme süresi:** Restore komutu yaklaşık 1.3 saniye içerisinde tamamlanmıştır. Bu değer yalnızca restore komutunun çalışma süresini göstermektedir, uçtan uca production RTO olarak değerlendirilmemiştir.
- **Açıklama:** `mongorestore` kullanılarak `sample_training` database'i backup'tan geri yüklenmiştir. Restore sonucunda toplam 2 document başarıyla geri yüklenmiş ve 0 document restore hatası alınmıştır.

### 6.6 Verinin geri geldiğinin doğrulanması

- **Arayüz görseli:** `docs/screenshots/23-data-restored-verified-ui.png`
- **Veritabanı çıktısı:** `docs/screenshots/24-data-restored-verified-database.png`
- **Açıklama:** Restore işleminden sonra `sample_training.records` ve `sample_training.github_repositories` collection'larının yeniden oluşturulduğu ve önceki verilerin MongoDB Atlas ile web arayüzünde tekrar erişilebilir olduğu doğrulanmıştır.

> Runbook, RPO/RTO hedefleri ve retention süresi `docs/backup-restore.md` içinde dokümante edilmelidir.

## 7. Logging, Monitoring ve Üst Kriterler

Uyguladığınız logging, monitoring, alarm, Helm, Terraform, güvenlik taraması veya diğer üst kriterlere ait kanıtları ekleyin.

- **Görsel:** `docs/screenshots/25-ETL-cronjob-logging.png`
- **Açıklama:** Kubernetes üzerinde çalışan ETL CronJob'un logları GitHub repository'sinin alınmasını, MongoDB bağlantısını, mevcut repository'nin github_id üzerinden güncellenmesini, document count kontrolünü ve ETL işleminin başarıyla tamamlanmasını göstermektedir.

### 7.1 Critical Alerts

- **Alert kontrolü ve test görseli:** `docs/screenshots/26-alerts-check.png`

- **Alert tanımı:** `scripts/check-alerts.ps1`

- **Açıklama:** `check-alerts.ps1` script'i iki kritik olay için çalıştırılabilir alarm kontrolü sağlamaktadır. `ALERT-001` ETL CronJob'un başarısız olması veya beklenen zaman aralığında başarılı bir çalışmanın bulunmaması durumunu, `ALERT-002` ise frontend veya backend health endpoint'lerinin erişilememesi durumunu kontrol etmektedir. Test modunda her iki alarm da bilinçli olarak tetiklenmiş ve script `exit code 1` ile sonlandırılmıştır. Sistem sağlıklı durumdayken gerçekleştirilen normal kontrolde ise kritik alarm üretilmemiş ve script başarılı şekilde sonlanmıştır.

## 8. Ek Kanıtlar

- **Görsel:** `docs/screenshots/...`
- **Açıklama:**
