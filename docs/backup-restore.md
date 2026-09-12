# Backup & Restore Runbook

Bu runbook, MongoDB Atlas üzerinde kullanılan `sample_training` database'inin yedeklenmesi ve geri yüklenmesi için kullanılan yöntemi ve gerçekleştirilen detaylı doğrulama senaryosunu açıklamaktadır.

---

## 1. Yaklaşım / Approach

|                                                                        |                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yedekleme yöntemi / Backup method                                      | MongoDB Database Tools `mongodump` kullanılarak `sample_training` database'inin tamamı yedeklenmiştir.                                                                                                                                                                                                                                               |
| Nasıl çalıştırılıyor / Execution method (script, Job, CronJob, manuel) | Bu case kapsamında gerçek E2E backup testi manuel olarak gerçekleştirilmiştir. Backup ve restore işlemleri ayrıca `scripts/backup-restore.ps1` PowerShell script'i üzerinden tekrarlanabilir şekilde çalıştırılabilir. Production ortamında zamanlanmış ve otomatik bir backup mekanizması tercih edilmelidir.                                                                                                                                                                                            |
| Yedeğin saklandığı konum / Backup storage location                     | Case çalışma ortamında proje kökü altındaki `backups/sample-training-backup/` klasörü.                                                                                                                                                                                                                                                               |
| Yedek formatı / Backup format                       | MongoDB BSON dump formatı ve collection metadata dosyaları kullanılmıştır. Backup içerisinde `records.bson`, `github_repositories.bson` ve ilgili metadata dosyaları bulunmaktadır.                                                                                                                                                                  |
| Sıklık / Frequency                                                     | Bu case kapsamında manuel olarak alınmıştır. Repository'de tekrarlanabilir backup/restore script'i bulunmaktadır, ancak otomatik backup schedule ve retention mekanizması uygulanmamıştır. Production ortamı için zamanlanmış günlük veya daha sık backup önerilmektedir.                                                                                                                                                                                                                          |
| Retention süresi / Retention period                                    | Case ortamında otomatik retention mekanizması bulunmamaktadır. Production retention süresi iş ve compliance gereksinimlerine göre belirlenmelidir.                                                                                                                                                 |
| Erişim ve güvenlik / Access and security           | MongoDB bağlantı bilgileri backup komutuna repository içerisinden sabit olarak yazılmamış, yerel `.env` değişkeninden okunmuştur. Backup dosyaları repository'ye eklenmemekte ve `backups/` `.gitignore` tarafından hariç tutulmaktadır. Production ortamında backup dosyaları erişim kontrollü ve şifreli bir harici storage üzerinde tutulmalıdır. |

## 2. Hedefler / Targets

|     | Hedef / Target                                                                                                               | Ölçülen / Measured                                                                                              |
| --- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| RPO | Production hedefi: Case ortamı için formal bir RPO tanımlanmamıştır. Mevcut manuel backup yaklaşımı belirli bir RPO'yu garanti etmez. | Otomatik backup olmadığı için ölçülmüş/garanti edilen bir RPO yoktur.             |
| RTO | Production hedefi: Case ortamı için formal bir production RTO SLA'sı tanımlanmamıştır.                             | `mongorestore` komutunun ölçülen çalışma süresi yaklaşık 1.3 saniyedir. Bu değer uçtan uca production RTO değildir. |

## 3. Yedek alma adımları / Backup procedure

MongoDB Database Tools `mongodump` kullanılmıştır. Backup işlemi doğrudan aşağıdaki repository script'i ile de çalıştırılabilir:

```powershell
.\scripts\backup-restore.ps1 -Action Backup
```

Script, `mongodump` komutunu gerekli parametrelerle çalıştırmaktadır. Aşağıdaki manual command chain yalnızca kullanılan yöntemi açıkça dokümante etmek amacıyla verilmiştir.

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
sample_training.records              → 1 document
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

Restore işlemi repository içerisindeki script ile de çalıştırılabilir:

```powershell
.\scripts\backup-restore.ps1 -Action Restore
```

Mevcut collection'ların üzerine restore edilmesi gerektiğinde:

```powershell
.\scripts\backup-restore.ps1 -Action Restore -DropExisting
```

Database silindikten sonra aynı backup kullanılarak `mongorestore` ile geri yükleme gerçekleştirilmiştir. Aşağıdaki manual command chain kullanılan yöntemi açıkça göstermek amacıyla verilmiştir.

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

Backup'ın eksik veya bozuk olmadığını doğrulamak için:

1. `mongodump` çıktısında backup'a alınan collection ve document sayıları kontrol edilmiştir.
2. Backup klasöründeki BSON ve metadata dosyalarının oluşturulduğu doğrulanmıştır.
3. `sample_training` database'i tamamen silindikten sonra uygulama ve MongoDB Atlas üzerinden verilerin kaybolduğu doğrulanmıştır.
4. Aynı backup kullanılarak `mongorestore` gerçekleştirilmiş ve her iki collection için `0 document(s) failed to restore` sonucu alınmıştır.
5. Restore sonrasında collection/document count kontrol edilmiş ve beklenen 2 document'ın geri geldiği doğrulanmıştır.
6. Restore edilen verinin web uygulaması ve MongoDB Atlas üzerinden tekrar göründüğü doğrulanmıştır.
7. `scripts/backup-restore.ps1 -Action Backup` ve `scripts/backup-restore.ps1 -Action Restore -DropExisting` senaryoları başarıyla test edilmiştir.

## 6. Uçtan uca test sonucu / End-to-end test result

Senaryo 9 Eylül 2026 tarihinde gerçekleştirilmiştir.

| # | Adım / Step                                      | Sonuç / Result                                                                | Kanıt / Evidence                              |
| - | ------------------------------------------------ | ----------------------------------------------------------------------------- | --------------------------------------------- |
| 1 | Kayıt oluşturuldu / Record created               | Başarılı. Atlas database'de kayıt mevcut durumda doğrulandı.                 | `docs/screenshots/29-backup-record-created-01.png` ve `docs/screenshots/30-backup-record-created-02.png`      |
| 2 | Yedek alındı / Backup taken                      | Başarılı. `sample_training` database'inin tamamı `mongodump` ile yedeklendi.  | `docs/screenshots/31-backup-taken.png`         |
| 3 | Collection/DB silindi / Collection or DB dropped | Başarılı. `sample_training` database'i Atlas üzerinden silindi.               | `docs/screenshots/32-collection-dropped.png`      |
| 4 | Verinin kaybolduğu görüldü / Data confirmed gone | Başarılı. Database ve uygulama kayıtlarının kaybolduğu doğrulandı.            | `docs/screenshots/33-data-missing-after-drop-ui.png` ve `docs/screenshots/34-data-missing-after-drop-database.png` |
| 5 | Yedekten geri yüklendi / Restored from backup    | Başarılı. 2 document, 0 failure ile restore tamamlandı.                       | `docs/screenshots/35-restore-executed.png`      |
| 6 | Veri geri geldi / Data confirmed back            | Başarılı. MongoDB Atlas ve web arayüzünde kayıtların geri geldiği doğrulandı. | `docs/screenshots/36-data-restored-verified-ui.png`, `docs/screenshots/37-data-restored-verified-database-01.png` ve `docs/screenshots/38-data-restored-verified-database-02.png`      |

## 7. Bilinen sınırlamalar / Known limitations

Bu case kapsamında backup/restore E2E testi manuel olarak gerçekleştirilmiştir. `scripts/backup-restore.ps1` işlemleri tekrarlanabilir hale getirmektedir, ancak otomatik scheduling ve retention uygulanmamıştır.

Production ortamında:

- Backup'lar bağımsız ve dayanıklı bir object storage üzerinde tutulmalıdır.
- Retention politikası otomatik uygulanmalıdır.
- Backup'lar şifrelenmeli ve erişim yetkileri sınırlandırılmalıdır.
- Düzenli backup integrity ve restore testleri yapılmalıdır.
- Daha düşük RPO gereksinimlerinde daha sık backup veya point-in-time recovery değerlendirilmelidir.
- Restore süreci periyodik olarak test edilerek gerçek uçtan uca RTO ölçülmelidir.
