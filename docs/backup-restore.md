# Backup & Restore Runbook

Bu runbook, MongoDB Atlas üzerinde kullanılan `sample_training` database'inin yedeklenmesi ve geri yüklenmesi için kullanılan yöntemi ve gerçekleştirilen uçtan uca doğrulama senaryosunu açıklamaktadır.

---

## 1. Yaklaşım / Approach

|                                                                        |                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yedekleme yöntemi / Backup method                                      | MongoDB Database Tools `mongodump` kullanılarak `sample_training` database'inin tamamı yedeklenmiştir.                                                                                                                                                                                                                                               |
| Nasıl çalıştırılıyor / Execution method (script, Job, CronJob, manuel) | Bu case kapsamında manuel PowerShell komutu ile çalıştırılmıştır. Production ortamında zamanlanmış ve otomatik bir backup mekanizması tercih edilmelidir.                                                                                                                                                                                            |
| Yedeğin saklandığı konum / Backup storage location                     | Case çalışma ortamında proje kökü altındaki `backups/sample-training-backup/` klasörü.                                                                                                                                                                                                                                                               |
| Yedek formatı ve boyutu / Backup format and size                       | MongoDB BSON dump formatı ve collection metadata dosyaları kullanılmıştır. Backup içerisinde `records.bson`, `github_repositories.bson` ve ilgili metadata dosyaları bulunmaktadır.                                                                                                                                                                  |
| Sıklık / Frequency                                                     | Bu case kapsamında manuel olarak alınmıştır. Production ortamı için zamanlanmış günlük veya daha sık backup önerilmektedir.                                                                                                                                                                                                                          |
| Retention süresi / Retention period                                    | Case çalışma ortamında belirlenmiş otomatik retention mekanizması bulunmamaktadır. Production ortamında en az 7 günlük veya iş gereksinimine göre daha uzun bir retention politikası uygulanmalıdır.                                                                                                                                                 |
| Şifreleme ve erişim kontrolü / Encryption and access control           | MongoDB bağlantı bilgileri backup komutuna repository içerisinden sabit olarak yazılmamış, yerel `.env` değişkeninden okunmuştur. Backup dosyaları repository'ye eklenmemekte ve `backups/` `.gitignore` tarafından hariç tutulmaktadır. Production ortamında backup dosyaları erişim kontrollü ve şifreli bir harici storage üzerinde tutulmalıdır. |

## 2. Hedefler / Targets

|     | Hedef / Target                                                                                                               | Ölçülen / Measured                                                                                              |
| --- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| RPO | Production hedefi: en fazla 24 saat veri kaybı. Daha kritik bir sistemde daha sık backup ile daha düşük RPO hedeflenmelidir. | Case kapsamında manuel backup alındığı için otomatik olarak garanti edilen bir RPO bulunmamaktadır.             |
| RTO | Production hedefi: uygulamanın kabul edilebilir süre içerisinde tekrar çalışır hale getirilmesi.                             | Gerçek restore komutu yaklaşık 1.3 saniye içinde tamamlanmıştır. Uçtan uca RTO'nun tamamı ayrıca ölçülmemiştir. |

## 3. Yedek alma adımları / Backup procedure

MongoDB Database Tools kullanılarak `sample_training` database'inin tamamı yedeklenmiştir.

Öncelikle yerel `.env` dosyasındaki `ATLAS_URI` değeri PowerShell değişkenine alınmıştır:

```powershell
$atlasUri = (Get-Content .\.env | Where-Object { $_ -match '^ATLAS_URI=' }) -replace '^ATLAS_URI=', ''
```

Backup klasörü oluşturulmuştur:

```powershell
New-Item -ItemType Directory -Path ".\backups" -Force
```

Ardından tüm `sample_training` database'i aşağıdaki komut ile yedeklenmiştir:

```powershell
& "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe" `
  --uri="$atlasUri" `
  --db=sample_training `
  --out=".\backups\sample-training-backup"
```

Backup sonucunda aşağıdaki collection'lar yedeklenmiştir:

```text
sample_training.records              → 2 documents
sample_training.github_repositories  → 1 document
```

Backup konumu:

```text
backups/
└── sample-training-backup/
    └── sample_training/
        ├── records.bson
        ├── records.metadata.json
        ├── github_repositories.bson
        ├── github_repositories.metadata.json
        └── prelude.json
```

## 4. Geri yükleme adımları / Restore procedure

Database silindikten sonra aynı backup kullanılarak `mongorestore` ile geri yükleme gerçekleştirilmiştir.

```powershell
& "C:\Program Files\MongoDB\Tools\100\bin\mongorestore.exe" `
  --uri="$atlasUri" `
  ".\backups\sample-training-backup"
```

Restore işlemi sonucunda:

```text
finished restoring `sample_training.github_repositories` (1 document, 0 failures)
finished restoring `sample_training.records` (2 documents, 0 failures)

3 document(s) restored successfully. 0 document(s) failed to restore.
```

`github_repositories` collection'ına ait unique `github_id` index'i de backup metadata üzerinden yeniden oluşturulmuştur.

## 5. Doğrulama / Verification

Backup'ın eksik veya bozuk olmadığını doğrulamak için:

1. `mongodump` çıktısında backup'a alınan collection ve document sayıları kontrol edilmiştir.
2. Backup klasöründeki BSON ve metadata dosyalarının oluşturulduğu doğrulanmıştır.
3. `sample_training` database'i tamamen silindikten sonra uygulama ve MongoDB Atlas üzerinden verilerin kaybolduğu doğrulanmıştır.
4. `mongorestore` sonrasında her iki collection'ın başarıyla restore edildiği ve `0 document(s) failed to restore` sonucu alındığı doğrulanmıştır.
5. Restore sonrasında MongoDB Atlas ve web arayüzü üzerinden kayıtların tekrar erişilebilir olduğu doğrulanmıştır.

## 6. Uçtan uca test sonucu / End-to-end test result

Senaryo 9 Eylül 2026 tarihinde gerçekleştirilmiştir.

| # | Adım / Step                                      | Sonuç / Result                                                                | Kanıt / Evidence                              |
| - | ------------------------------------------------ | ----------------------------------------------------------------------------- | --------------------------------------------- |
| 1 | Kayıt oluşturuldu / Record created               | Başarılı. MERN uygulamasında kayıt mevcut durumda doğrulandı.                 | `docs/screenshots/backup-01-before.png`       |
| 2 | Yedek alındı / Backup taken                      | Başarılı. `sample_training` database'inin tamamı `mongodump` ile yedeklendi.  | `docs/screenshots/backup-02-dump.png`         |
| 3 | Collection/DB silindi / Collection or DB dropped | Başarılı. `sample_training` database'i Atlas üzerinden silindi.               | `docs/screenshots/backup-03-dropped.png`      |
| 4 | Verinin kaybolduğu görüldü / Data confirmed gone | Başarılı. Database ve uygulama kayıtlarının kaybolduğu doğrulandı.            | `docs/screenshots/backup-04-data-missing.png` |
| 5 | Yedekten geri yüklendi / Restored from backup    | Başarılı. 3 document, 0 failure ile restore tamamlandı.                       | `docs/screenshots/backup-05-restore.png`      |
| 6 | Veri geri geldi / Data confirmed back            | Başarılı. MongoDB Atlas ve web arayüzünde kayıtların geri geldiği doğrulandı. | `docs/screenshots/backup-06-restored.png`     |

## 7. Bilinen sınırlamalar / Known limitations

Bu case kapsamında backup işlemi manuel olarak gerçekleştirilmiş ve backup dosyaları local filesystem üzerinde tutulmuştur. Bu yaklaşım gerçek production ortamında tek başına yeterli değildir.

Production ortamında:

* Backup işlemi zamanlanmış bir Job/CronJob veya managed backup mekanizması ile otomatikleştirilmelidir.
* Backup'lar uygulama veya cluster ortamından bağımsız bir object storage veya başka bir dayanıklı storage üzerinde tutulmalıdır.
* Backup retention politikası otomatik olarak uygulanmalıdır.
* Backup dosyaları şifreli şekilde saklanmalı ve yalnızca gerekli yetkilere sahip servis veya kullanıcıların erişimine izin verilmelidir.
* Düzenli backup integrity ve restore testleri gerçekleştirilmelidir.
* Daha düşük RPO gereksinimi olan sistemlerde günlük backup yerine daha sık backup veya point-in-time recovery yaklaşımı değerlendirilmelidir.
* Restore sürecinin tamamı periyodik olarak test edilerek gerçek RTO ölçülmelidir.
