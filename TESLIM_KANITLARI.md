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

- **Pod/workload durumu:** `docs/screenshots/...`
- **Service ve varsa Ingress durumu:** `docs/screenshots/...`
- **ETL CronJob/Job durumu:** `docs/screenshots/...`
- **Açıklama:**

## 4. Python ETL

### 4.1 İlk veri aktarımı

GitHub repository bilgilerinin MongoDB’ye ilk kez kaydedildiğini gösterin.

- **Görsel veya terminal çıktısı:** `docs/screenshots/...`
- **Açıklama:**

### 4.2 Aynı repository için güncelleme

Aynı repository tekrar işlendiğinde duplicate kayıt oluşmadığını ve mevcut kaydın güncellendiğini gösterin. Mümkünse repository sayısını ve güncellenen alanı aynı kanıt içinde belirtin.

- **Görsel veya terminal çıktısı:** `docs/screenshots/...`
- **Kullanılan benzersiz alan:**
- **Açıklama:**

## 5. CI/CD

- **Başarılı pipeline görseli:** `docs/screenshots/...`
- **Build/image/deployment aşamalarını gösteren görsel:** `docs/screenshots/...`
- **Açıklama:**

## 6. Backup ve Restore

Aşağıdaki altı adımın tamamı kanıtlanmalıdır. Adımların aynı kayıt üzerinde ve sırayla yapıldığı anlaşılmalıdır.

### 6.1 Kayıt oluşturma

- **Görsel:** `docs/screenshots/...`
- **Açıklama:**

### 6.2 Yedek alma

- **Görsel veya terminal çıktısı:** `docs/screenshots/...`
- **Kullanılan yöntem ve komut:**
- **Yedeğin saklandığı konum:**
- **Açıklama:**

### 6.3 Collection veya veritabanının silinmesi

- **Görsel veya terminal çıktısı:** `docs/screenshots/...`
- **Açıklama:**

### 6.4 Verinin kaybolduğunun gösterilmesi

- **Arayüz görseli:** `docs/screenshots/...`
- **Veritabanı çıktısı:** `docs/screenshots/...`
- **Açıklama:**

### 6.5 Yedekten geri yükleme

- **Görsel veya terminal çıktısı:** `docs/screenshots/...`
- **Ölçülen geri yükleme süresi:**
- **Açıklama:**

### 6.6 Verinin geri geldiğinin doğrulanması

- **Arayüz görseli:** `docs/screenshots/...`
- **Veritabanı çıktısı:** `docs/screenshots/...`
- **Açıklama:**

> Runbook, RPO/RTO hedefleri ve retention süresi `docs/backup-restore.md` içinde dokümante edilmelidir.

## 7. Logging, Monitoring ve Üst Kriterler

Uyguladığınız logging, monitoring, alarm, Helm, Terraform, güvenlik taraması veya diğer üst kriterlere ait kanıtları ekleyin.

- **Görsel:** `docs/screenshots/...`
- **Açıklama:**

## 8. Ek Kanıtlar

- **Görsel:** `docs/screenshots/...`
- **Açıklama:**
