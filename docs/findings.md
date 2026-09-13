## Finding 01

**Önem Derecesi:** Yüksek

**Dosya Yolu 01:** `mern-project\client\src\components\create.js`

**Dosya Yolu 02:** `mern-project\client\src\components\edit.js`

**Dosya Yolu 03:** `mern-project\client\src\components\healthcheck.js`

**Dosya Yolu 04:** `mern-project\client\src\components\recordList.js`

**Sorun:** Backend adresleri hardcode edilmiştir. `localhost:5050` doğrudan bağlantı adreslerine gömülmüştür. Local ortamda çalışsa da frontend container'laştırıldığında veya Kubernetes üzerinde çalıştırıldığında bu adresin her ortamda geçerli olması beklenmez.

**Çözüm:** Frontend'in backend API adresi environment/configuration üzerinden sağlanacak şekilde düzenlenmiştir. Böylece uygulama kodu değiştirilmeden farklı çalışma ortamlarında farklı backend adresleri kullanılabilmektedir.

---

## Finding 02

**Önem Derecesi:** Yüksek

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Record oluşturulurken validation yalnızca frontend tarafındaki kullanıcı arayüzü kontrollerine bırakılmıştır. Frontend'deki radio button veya benzeri kısıtlamalar doğrudan API'ye gönderilen verileri güvence altına almaz. İstemci tarafı kontrolleri atlanarak backend'e doğrudan geçersiz veri gönderilebilir.

**Çözüm:** Backend tarafında gerekli input validation uygulanmıştır. `name` ve `position` alanlarının uygun string değerler olması, boş bırakılmaması ve `level` alanının izin verilen seçeneklerden biri olması server-side olarak kontrol edilmektedir.

---

## Finding 03

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Database erişimi sırasında oluşabilecek hatalar başlangıç kodunda kontrollü ve tutarlı biçimde ele alınmamıştır. Bazı HTTP yöntemlerinde hata durumları eksik veya yetersiz şekilde işlenmiştir.

**Çözüm:** Database işlemleri uygun `try/catch` bloklarıyla ele alınmış, hata durumlarında uygun HTTP status kodları döndürülmüş ve hatalar loglanmıştır. Böylece database erişim hatalarının kontrolsüz şekilde kullanıcıya yansıması veya uygulamanın beklenmeyen davranış göstermesi azaltılmıştır.

---

## Finding 04

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** `res.send("Not found").status(404)` gibi ifadelerde Express response metodlarının sıralaması hatalıdır. `send()` çağrısından sonra response gönderildiği için sonradan yapılan `status()` çağrısı beklenen HTTP status kodunu değiştirmeyebilir.

**Çözüm:** Response önce status kodu ayarlanacak, ardından body gönderilecek şekilde düzenlenmiştir:

```js
res.status(404).send("Not found");
```

---

## Finding 05

**Önem Derecesi:** Orta

**Dosya Yolu:** `mern-project\server\db\conn.mjs`

**Sorun:** MongoDB bağlantısı başarısız olduğunda başlangıç kodu yalnızca hatayı loglamakta, uygulamanın bağlantı olmadan başlatılması ihtimalini yeterince kontrollü biçimde ele almamaktadır. Bu durum uygulamanın daha sonra database nesnesini kullanırken beklenmeyen bir hata ile sonlanmasına neden olabilir.

**Çözüm:** MongoDB bağlantısı başarısız olduğunda hata loglanarak process kontrollü şekilde sonlandırılmıştır. Böylece database bağlantısı olmadan sağlıksız bir backend'in çalışmaya devam etmesi engellenmiştir.

---

## Finding 06

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Create işlemi sonucunda `204 No Content` kullanılmaya çalışılmıştır. `204` response body içermemesi gerektiği için aynı response içerisinde oluşturulan kaydın body olarak gönderilmesi uygun değildir.

**Çözüm:** Oluşturulan kaydın response body içerisinde döndürülebilmesi için `201 Created` status kodu kullanılmıştır.

---

## Finding 07

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Başlangıç kodunda `req.params.id` değeri doğrudan `ObjectId`'ye dönüştürülmektedir:

```js
const query = { _id: new ObjectId(req.params.id) };
```

Geçersiz bir ID gönderilmesi durumunda `ObjectId` oluşturma sırasında exception oluşabilir.

**Çözüm:** ID değeri database sorgusundan önce:

```js
ObjectId.isValid(req.params.id)
```

ile doğrulanmaktadır. Geçersiz değerlerde uygun HTTP response döndürülmektedir.

---

## Finding 08

**Önem Derecesi:** Orta

**Dosya Yolu 01:** `mern-project\client\src\components\create.js`

**Dosya Yolu 02:** `mern-project\client\src\components\edit.js`

**Sorun:** `fetch()` yalnızca network seviyesinde bir hata oluştuğunda Promise'i reject eder. HTTP `4xx` veya `5xx` response'ları otomatik olarak JavaScript exception oluşturmaz. Başlangıç kodunda bu nedenle API'nin hata status'ları frontend tarafından başarılı response gibi işlenebilmektedir.

**Çözüm:** Response işlenmeden önce `response.ok` kontrolü eklenmiştir. `response.ok` değeri başarılı HTTP status'larını kontrol ettiği için yalnızca `200` status'una bağlı kalmadan `2xx` response'ların tamamının doğru şekilde ele alınmasını sağlar.

---

## Finding 09

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\healthcheck.mjs`

**Sorun:** Başlangıç healthcheck endpoint'i yalnızca Node.js process'inin HTTP isteğine cevap verebildiğini göstermektedir. Bu endpoint uygulamanın Kubernetes açısından liveness veya readiness durumunu tam olarak ifade etmemektedir.

**Çözüm:** Healthcheck semantiğinin liveness ve readiness olarak ayrıştırılması production yaklaşımında daha uygun olacaktır. Liveness kontrolü process'in çalıştığını, readiness kontrolü ise uygulamanın trafik almaya hazır olduğunu doğrulamalıdır. Gerekli durumda readiness kontrolünde MongoDB gibi kritik dependency'lerin erişilebilirliği de değerlendirilebilir.

---

## Finding 10

**Önem Derecesi:** Orta

**Dosya Yolu:** `mern-project\server\server.mjs`

**Sorun:** `cors()` başlangıç kodunda herhangi bir origin kısıtlaması olmadan kullanılmaktadır. Bu durumda backend'in cross-origin istekler için gereğinden geniş bir erişim politikası oluşmaktadır.

**Çözüm:** CORS politikası `ALLOWED_ORIGIN` environment variable'ı üzerinden yapılandırılmıştır. Böylece yalnızca izin verilen frontend origin'inden gelen cross-origin isteklerin kabul edilmesi sağlanmaktadır.

---

## Finding 11

**Önem Derecesi:** Orta

**Dosya Yolu:** `mern-project\client\cypress\integration\endToEnd.spec.js`

**Sorun:** Cypress testi başlangıçta yanlış route'u ziyaret etmiştir. Bu nedenle beklenen records ekranına ulaşmadan test akışı başarısız olmuştur.

**Çözüm:** Test başlangıç URL'si uygulamanın mevcut `/records` route'una güncellenmiştir.

```js
cy.visit("http://localhost:3000/records");
```
