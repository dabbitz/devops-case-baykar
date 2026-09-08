## Finding 01

**Önem Derecesi:** Yüksek

**Dosya Yolu 01:** `mern-project\client\src\components\create.js`

**Dosya Yolu 02:** `mern-project\client\src\components\edit.js`

**Dosya Yolu 03:** `mern-project\client\src\components\healthcheck.js`

**Dosya Yolu 04:** `mern-project\client\src\components\recordList.js`

**Sorun:** Backend adresleri hardcode'lanmış. `localhost:5050` direkt bağlantı içerisine gömülmüş. Local'de sorun olmaz, fakat ileride frontend konteynırize edildiğinde local machine olmayacağından bu bağlantı çalışmaz.

**Çözüm:** Bu tarz frontend kodunda yer alacak backend bağlantıları environment/configuration ile verilmelidir. Yani, kod sabit kalacak şekilde ayarlanmalı, ve koddaki değişken local'de mi yoksa Docker veya Kubernetes'te mi olduğuna göre davranacaktır.

## Finding 02

**Önem Derecesi:** Yüksek

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Tabloya yeni bir record eklenirken içerik kontrol edilmiyor ve tamamen frontend kodunun sunduğu kısıtlamalara güveniliyor. Fakat frontend'deki radio tuşları gibi özellikler sadece kullanıcı arayüzünü kısıtlar, backend'e kural eklemez. Backend, kural takibi yaparken hiçbir zaman frontend'e güvenmemelidir.

Örneğin, bu durumdayken herhangi bir kullanıcı siteye "İncele" diyerek (DevTools'u açarak) konsola girebilir ve orada istediği özelliklerle bir ekleme yapabilir.

**Çözüm:** Yaşanmasını istemediğimiz durumları özellikle backend'de ayarlamalıyız. Örneğin, input'un null olamayacağı, en az bir karakter içermesi gerektiği, sayı içermemesi, belli seçenekler arasında seçim yapılacaksa bunların dışına çıkılmayacağı gibi durumları backend'de sınırlamalıyız. Bunun üzerine, ne olur ne olmaz database üzerinde de belli kurallar ile ekstra önlemler almalıyız (bu satır sadece bu değerleri alabilir, veri türü şu olmalıdır, gibi).

## Finding 03

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Veritabanına olan erişimin olumsuz sonuçlandığı bir durumda izlenecek alternatif bir yol bulunmuyor ve bu durum kontrollü bir şekilde ele alınmıyor. Bazı HTTPS yöntemlerinde else bloğu koyulmuş fakat onlarda da başka bir sorun var (Finding 04).

**Çözüm:** Oluşan hatanın düzgünce bildirilmesi ve ilgili sistemlerin (Kubernetes gibi) bu sorun hakkında uyarılması gerekir. En basitinden, hatalı ile alakalı doğru HTTPS status kodu döndürülmelidir ve log üretmelidir.

## Finding 04

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** *res.send("Not found").status(404)* gibi kodların syntax'i doğru kullanılmamış (direkt yazılışı yanlış değil, fakat kullanımı yanlış). Önce .status ile hata kodu gönderilir, daha sonra .send ile gönderilmek istenen mesaj verilir. Çünkü *.send*'den sonra append edilen fonksiyonlar çağrılmaz.

**Çözüm:** Benzer hataya sahip kod parçaları, örneğin, *res.status(404).send("Not found")* şeklinde düzeltilir.

## Finding 05

**Önem Derecesi:** Orta

**Dosya Yolu:** `mern-project\server\db\conn.mjs`

**Sorun:** Veritabanına bağlanmak başarısız olduğunda konsola hata mesajı yazılıyor fakat kodun kalan kısmı sanki hiç hata olamayacakmış gibi yazılmış, dolasıyla hata olsa bile olmamış gibi devam ediyor ve hata varsa çöküyor.

*conn = await client.connect();* ile *conn* değeri belirleniyor, fakat veritabanına bağlanılamazsa bu değer undefined oluyor ve ileride *let db = conn.db("sample_training");* çalıştığında aslında *let db = undefined.db("sample_training");* çalışmış oluyor.

**Çözüm:** Hata alındığı durumda kod kontrollü bir şekilde durdurulmalı ve hata log'lanmalı, hata olmamışçasına çalışmasına izin verilmemelidir.

## Finding 06

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** Status kodu olarak 204 döndürülmeye çalışılmıştır fakat 204 kodu özellikle boş bir body cevabı döndürür, yani bu durumda *send(result)* yapılsa bile body boş olur.

**Çözüm:** 201 Status kodu kullanılır.

## Finding 07

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\record.mjs`

**Sorun:** *const query = { _id: new ObjectId(req.params.id) };* kodunda *ObjectId*, input'u validate etmiyor. Burada konsol gibi bir araç üzerinden geçersiz bir Id ile sorgu yapılırsa hata oluşur.

**Çözüm:** *ObjectId.isValid(req.params.id)* ile kontrol yapılır.

## Finding 08

**Önem Derecesi:** Orta

**Dosya Yolu 01:** `mern-project\client\src\components\create.js`

**Dosya Yolu 02:** `mern-project\client\src\components\edit.js`

**Sorun:** *fetch* isteği, veritabanından response.ok mesajı almasa bile yine de bu bir hata değilmiş gibi ve dönebilecek herhangi bir mesajmış gibi davranır (çünkü *fetch*'e göre gerçek hata, hiç cevap alınamamasıdır). Dolayısıyla, veritabanından aldığı herhangi bir cevapta her şey normalmiş gibi davranır (catch bloğuna girilmez).

**Çözüm:** Sadece başarılı bir şekilde isteğin gerçekleştirildiği durumlarda sorun olmadığı belirtilmelidir, alınabilecek her türlü yanıtta değil. Dolayısıyla, status code 200'ün döndürüldüğünden emin olunmalıdır.

## Finding 09

**Önem Derecesi:** Düşük

**Dosya Yolu:** `mern-project\server\routes\healthcheck.mjs`

**Sorun:** Health check yeterli değil ve çok basit kalıyor. An itibariyle sadece node.js process'inin HTTP isteğine cevap verip veremediğine bakıyor. Process hala yaşıyor mu, readiness durumu nedir, gibi sorulara yanıt vermiyor.

**Çözüm:** Daha kapsamlı bir health check semantiği hazırlanmalıdır ve uygun sağlık kontrolleri sağlanmalıdır.

## Finding 10

**Önem Derecesi:** Orta

**Dosya Yolu:** `mern-project\server\server.mjs`

**Sorun:** *cors()* boş bırakılmış, yani herhangi bir origin kısıtlaması verilmemiştir. Bu, backend'in herhangi bir origin'den gelen istekleri kabul etmesine olanak verir. Cross-origin isteklerde bulunuyor olsak bile (frontend ve backend arası) bunu sınırsız bırakmak gereksiz bir güvenlik açığıdır.

**Çözüm:** cors() içerisine frontend'in bağlantı adresi yazılır ve böylece cross-origin request'lerin watchlist'inde sadece ilgili origin'ler bulunur.

## Finding 11

**Önem Derecesi:** Yüksek

**Dosya Yolu:** `mern-project\client\cypress\integration\endToEnd.spec.js`

**Sorun:** *cy.contains("Employee1").should("exist");* testi başarısız oluyor, çünkü `http://localhost:3000` bağlantısında tabloyu göremiyoruz, dolayısıyla Employee1 var mı diye test edemiyoruz.

**Çözüm:** *cy.visit("http://localhost:3000/records");* bağlantısına gidersek orada tabloyu ve dolayısıyla testte eklenen Employee1'in olduğu görülecektir.