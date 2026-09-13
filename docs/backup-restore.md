# Backup & Restore Runbook

Bu runbook, MongoDB Atlas üzerinde kullanılan `sample_training` database'inin yedeklenmesi ve geri yüklenmesi için kullanılan yöntemi, otomatik Kubernetes backup akışını ve gerçekleştirilen doğrulama senaryolarını açıklamaktadır.

---

## 1. Yaklaşım / Approach

|                                                                        |                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yedekleme yöntemi / Backup method                                      | MongoDB Database Tools `mongodump` kullanılarak `sample_training` database'inin tamamı yedeklenmektedir.                                                                                                                                                                                                                                                                                             |
| Nasıl çalıştırılıyor / Execution method (script, Job, CronJob, manuel) | EKS ortamında `mongodb-backup` adlı Kubernetes `CronJob` otomatik olarak çalışmaktadır. Schedule `0 2 * * *`, timezone `Avrupa/İstanbul` şeklindedir. Backup ayrıca repository içerisindeki `scripts/backup-restore.ps1` script'i üzerinden manuel olarak da tekrarlanabilir.                                                                                                                        |
| Yedeğin saklandığı konum / Backup storage location                     | Otomatik backup'lar Amazon S3 üzerinde `s3://devops-case-baykar-backups-203309795174/sample_training/` prefix'i altında saklanmaktadır.                                                                                                                                                                                                                                                              |
| Yedek formatı / Backup format                                          | Kubernetes backup workload'u `mongodump` ile gzip sıkıştırılmış archive formatında `.archive.gz` dosyaları üretmektedir. Dosya adları UTC timestamp içermektedir. Örnek: `sample_training_20260912T230006Z.archive.gz`.                                                                                                                                                                              |
| Sıklık / Frequency                                                     | Otomatik backup her gün saat 02:00'de `Avrupa/İstanbul` timezone'u kullanılarak çalışmaktadır. Her çalışmada yeni ve timestamp'li bir S3 object oluşturulur; önceki backup'ların üzerine yazılmaz.                                                                                                                                                                                                   |
| Retention süresi / Retention period                                    | Otomatik S3 Lifecycle tabanlı retention/silme mekanizması henüz tanımlanmamıştır. Bu nedenle formal bir production retention süresi belirlenmemiştir.                                                                                                                                                                                                                                                |
| Erişim ve güvenlik / Access and security                               | MongoDB bağlantı bilgileri Kubernetes Secret (`etl-secret`) üzerinden sağlanmaktadır. Backup workload'u `s3-backup` ServiceAccount kullanır. S3 erişimi `DevOpsCaseS3BackupPolicy` adlı least-privilege IAM policy ile gerekli bucket/prefix kaynaklarıyla sınırlandırılmıştır. Backup container'ları non-root olarak çalışır, privilege escalation kapalıdır ve tüm Linux capabilities drop edilir. |

## 2. Hedefler / Targets

|     | Hedef / Target                                                                                                                                                                                                                                                                                                        | Ölçülen / Measured                                                                                                                                                                                    |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RPO | Case ortamında formal bir production RPO SLA'sı tanımlanmamıştır. Günlük 02:00 backup schedule'ı nedeniyle otomatik backup mekanizması teorik olarak yaklaşık 24 saate kadar veri kaybı penceresi oluşturabilir. Daha düşük RPO gereksinimleri için daha sık backup veya point-in-time recovery değerlendirilmelidir. | Otomatik backup'ın 13 Eylül 2026 tarihinde gerçek scheduler çalışması doğrulanmıştır. `mongodb-backup-29820900` Job'ı `Complete 1/1` olarak tamamlanmış ve S3'e yeni backup object'i oluşturulmuştur. |
| RTO | Case ortamı için formal bir production RTO SLA'sı tanımlanmamıştır.                                                                                                                                                                                                                                                   | `mongorestore` komutunun ölçülen çalışma süresi yaklaşık 1.3 saniyedir. Bu değer yalnızca restore komutunun çalışma süresidir ve uçtan uca production RTO olarak değerlendirilmemiştir.               |

## 3. Yedek alma adımları / Backup procedure

### Otomatik EKS backup

MongoDB backup işlemi `k8s/eks/backup-cronjob.yaml` içerisindeki Kubernetes `CronJob` tarafından otomatik olarak gerçekleştirilir.

Schedule:

```text
0 2 * * *
```

Timezone:

```text
Avrupa/İstanbul
```

Backup akışı:

```text
MongoDB Atlas
    ↓
mongodb-backup CronJob
    ↓
mongodump
    ↓
/backup/sample_training_<UTC timestamp>.archive.gz
    ↓
Amazon S3
    ↓
S3 head-object verification
```

Backup dosya adı UTC timestamp kullanır:

```text
sample_training_20260912T230006Z.archive.gz
```

Buradaki `Z`, timestamp'in UTC olduğunu ifade eder. Örneğin `23:00 UTC`, `Avrupa/İstanbul` timezone'unda `02:00` değerine karşılık gelir.

S3 backup konumu:

```text
s3://devops-case-baykar-backups-203309795174/sample_training/
```

Otomatik backup workload'u:

```text
k8s/eks/backup-cronjob.yaml
```

Backup ServiceAccount:

```text
s3-backup
```

S3 IAM policy:

```text
DevOpsCaseS3BackupPolicy
```

Backup archive'ı oluşturulduktan sonra dosyanın boş olmadığı `test -s` ile kontrol edilir. `s3-upload` container'ı `aws s3 cp` ile object'i S3'e yükler ve `aws s3api head-object` ile yüklenen object'in S3 üzerinde erişilebilir olduğu doğrulanır.

Örnek başarılı backup:

```text
mongodb-backup-29820900    Complete    1/1
```

S3 üzerinde oluşturulan object:

```text
sample_training_20260912T230006Z.archive.gz
```

### Manuel / tekrarlanabilir backup

Repository içerisinde bulunan script ile manuel backup da çalıştırılabilir:

```powershell
.\scripts\backup-restore.ps1 -Action Backup
```

Bu script, local E2E backup/restore senaryosunda kullanılan `mongodump` yaklaşımını tekrarlanabilir hale getirmektedir.

Test kapsamında `sample_training` database'inde aşağıdaki collection'lar yedeklenmiştir:

```text
sample_training.records              → 1 document
sample_training.github_repositories → 1 document
```

Manuel E2E testte kullanılan backup çalışma alanı:

```text
backups/
└── sample-training-backup/
    └── sample_training/
        ├── github_repositories.bson 
        ├── github_repositories.metadata.json
        ├── prelude.json
        ├── records.bson
        └── records.metadata.json
```

Bu local backup klasörü repository'ye dahil edilmez. Otomatik EKS backup storage'ı ise Amazon S3'tür.

## 4. Geri yükleme adımları / Restore procedure

Restore işlemi repository içerisindeki script ile çalıştırılabilir:

```powershell
.\scripts\backup-restore.ps1 -Action Restore
```

Mevcut collection'ların üzerine restore edilmesi gerektiğinde:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

Database silindikten sonra kullanılan test backup'ı `mongorestore` ile geri yüklenmiştir. Kullanılan yöntemi açıkça göstermek amacıyla manual command chain aşağıda verilmiştir:

```powershell
& "C:\Program Files\MongoDB\Tools\100\bin\mongorestore.exe" `
  --uri="$atlasUri" `
  ".\backups\sample-training-backup"
```

Restore işlemi sonucunda:

```text
finished restoring `sample_training.github_repositories` (1 document, 0 failures)
finished restoring `sample_training.records` (1 document, 0 failures)

2 document(s) restored successfully. 0 document(s) failed to restore.
```

`github_repositories` collection'ının backup metadata'sındaki index tanımları da restore sürecinde yeniden uygulanmıştır.

## 5. Doğrulama / Verification

Backup ve restore sürecinin başarılı olduğunu doğrulamak için:

1. `mongodb-backup` Job'ının başarıyla tamamlandığı kontrol edilmiştir.
2. Otomatik backup workload'unda oluşturulan archive dosyasının boş olmadığı `test -s` ile doğrulanmıştır.
3. S3 upload işlemi tamamlandıktan sonra `aws s3api head-object` ile ilgili object'in S3 üzerinde erişilebilir olduğu doğrulanmıştır.
4. S3 üzerinde timestamp'li backup object'inin gerçekten oluşturulduğu doğrulanmıştır.
5. 13 Eylül 2026 tarihinde `mongodb-backup` CronJob'ının gerçek scheduler tarafından çalıştırıldığı ve `mongodb-backup-29820900` Job'ının `Complete 1/1` olduğu doğrulanmıştır.
6. Manuel E2E test sırasında `sample_training` database'i tamamen silindikten sonra uygulama ve MongoDB Atlas üzerinden verilerin kaybolduğu doğrulanmıştır.
7. Aynı backup kullanılarak `mongorestore` gerçekleştirilmiş ve her iki collection için `0 document(s) failed to restore` sonucu alınmıştır.
8. Restore sonrasında collection/document count kontrol edilmiş ve beklenen 2 document'ın geri geldiği doğrulanmıştır.
9. Restore edilen verinin web uygulaması ve MongoDB Atlas üzerinden tekrar göründüğü doğrulanmıştır.
10. `scripts/backup-restore.ps1 -Action Backup` ve `scripts/backup-restore.ps1 -Action Restore -DropExisting` senaryoları başarıyla test edilmiştir.

## 6. Uçtan uca test sonucu / End-to-end test result

Temel manuel backup/restore E2E senaryosu 10 Eylül 2026 tarihinde gerçekleştirilmiştir. Otomatik EKS backup senaryosu ise 13 Eylül 2026 tarihinde gerçek scheduler çalışması ile doğrulanmıştır.

| # | Adım / Step                                      | Sonuç / Result                                                                                                                                                   | Kanıt / Evidence                                                                                                                                                                  |
| - | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1 | Kayıt oluşturuldu / Record created               | Başarılı. Atlas database'de kayıt mevcut durumda doğrulandı.                                                                                                     | `docs/screenshots/29-backup-record-created-01.png` ve `docs/screenshots/30-backup-record-created-02.png`                                                                          |
| 2 | E2E test backup'ı alındı / E2E test backup taken | Başarılı. `sample_training` database'inin tamamı `mongodump` ile yedeklendi.                                                                                     | `docs/screenshots/31-backup-taken.png`                                                                                                                                            |
| 3 | Collection/DB silindi / Collection or DB dropped | Başarılı. `sample_training` database'i Atlas üzerinden silindi.                                                                                                  | `docs/screenshots/32-collection-dropped.png`                                                                                                                                      |
| 4 | Verinin kaybolduğu görüldü / Data confirmed gone | Başarılı. Database ve uygulama kayıtlarının kaybolduğu doğrulandı.                                                                                               | `docs/screenshots/33-data-missing-after-drop-ui.png` ve `docs/screenshots/34-data-missing-after-drop-database.png`                                                                |
| 5 | Yedekten geri yüklendi / Restored from backup    | Başarılı. 2 document, 0 failure ile restore tamamlandı.                                                                                                          | `docs/screenshots/35-restore-executed.png`                                                                                                                                        |
| 6 | Veri geri geldi / Data confirmed back            | Başarılı. MongoDB Atlas ve web arayüzünde kayıtların geri geldiği doğrulandı.                                                                                    | `docs/screenshots/36-data-restored-verified-ui.png`, `docs/screenshots/37-data-restored-verified-database-01.png` ve `docs/screenshots/38-data-restored-verified-database-02.png` |
| 7 | Otomatik scheduled backup / Scheduled backup     | Başarılı. `0 2 * * *` / `Avrupa/İstanbul` schedule ile `mongodb-backup-29820900` Job'ı `Complete 1/1` olarak tamamlandı ve timestamp'li S3 object'i oluşturuldu. | `docs/screenshots/53-backup-cronjob-scheduled-success.png`                                                                                                                        |

## 7. Bilinen sınırlamalar / Known limitations

Bu case kapsamında manuel backup/restore E2E testi gerçekleştirilmiş, ayrıca otomatik EKS backup mekanizması gerçek scheduler çalışması ve S3 object doğrulaması ile test edilmiştir.

Mevcut çözümde:

- Backup'lar Amazon S3'te cluster dışı storage olarak tutulmaktadır.
- Backup işlemi her gün 02:00 `Avrupa/İstanbul` timezone'unda otomatik çalışmaktadır.
- Backup object'leri UTC timestamp ile isimlendirilmekte ve her çalışmada yeni bir S3 object oluşturulmaktadır.
- Backup integrity için archive boyutu kontrolü ve S3 `head-object` doğrulaması uygulanmaktadır.
- S3 bucket için otomatik Lifecycle/retention politikası henüz tanımlanmamıştır.
- Formal production RPO/RTO SLA'sı tanımlanmamıştır.
- Restore komutunun yaklaşık 1.3 saniyelik çalışma süresi ölçülmüştür; bu değer uçtan uca production RTO değildir.
- Otomatik restore verification ve düzenli restore/DR tatbikatları bu case kapsamında uygulanmamıştır.
- Point-in-time recovery (PITR) yapılandırılmamıştır.
- Backup object'lerinin encryption, retention ve lifecycle yönetimi gerçek production ortamında iş ve compliance gereksinimlerine göre ayrıca yapılandırılmalıdır.
- Daha düşük RPO gereksinimlerinde daha sık backup veya point-in-time recovery yaklaşımı değerlendirilmelidir.
