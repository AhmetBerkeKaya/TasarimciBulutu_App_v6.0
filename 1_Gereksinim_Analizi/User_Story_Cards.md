# TasarımcıBulutu User Story Cards

## 1. Kullanıcı Yönetimi

### Freelancer İş Akışı
| ID     | Kullanıcı Tipi | User Story | Kabul Kriterleri | Öncelik | 
|--------|----------------|------------|------------------|---------|
| US-001 | Freelancer | Bir CAD tasarımcısı olarak, e-posta ve şifreyle kayıt olabilmeliyim ki platforma erişebileyim. | ✔ Kayıt formu çalışıyor. ✔ E-posta doğrulama linki 5 dakika içinde geliyor. | Yüksek |
| US-002 | Freelancer | Bir mühendis olarak, profilime SolidWorks ve AutoCAD yetkinliklerimi ekleyebilmeliyim ki firmalar beni bulabilsin. | ✔ Profil sayfasında "Yetkinlikler" bölümü aktif. ✔ Yazılım listesinden seçim yapılabiliyor. | Yüksek |

### Firma İş Akışı
| ID     | Kullanıcı Tipi | User Story | Kabul Kriterleri | Öncelik |
|--------|----------------|------------|------------------|---------|
| US-003 | Firma | Bir imalat firması olarak, vergi numarası ve şirket logosuyla kayıt olabilmeliyim ki freelancer'lar bize güvensin. | ✔ Firma kayıt formu KVKK uyumlu. ✔ Logo yükleme (max 2MB) çalışıyor. | Yüksek |
| US-004 | Firma | Bir proje yöneticisi olarak, takım üyelerini davet edebilmeliyim ki projeleri birlikte yönetelim. | ✔ "Takım Ekle" butonu çalışıyor. ✔ Davet e-postası gidiyor. | Orta |

---

## 2. Proje Yönetimi

### Proje İlanı
| ID     | Kullanıcı Tipi | User Story | Kabul Kriterleri |
|--------|----------------|------------|------------------|
| US-005 | Firma | Bir satın alma uzmanı olarak, proje ilanına teknik şartname PDF'i ekleyebilmeliyim ki freelancer'lar detayları görsün. | ✔ Dosya yükleme (max 5MB) çalışıyor. ✔ PDF önizleme gösteriliyor. | 
| US-006 | Firma | Bir startup olarak, bütçemi gizli tutabilmeliyim ki rekabet avantajım korunsun. | ✔ "Gizli Bütçe" seçeneği aktif. |

### Teklif Yönetimi
| ID     | Kullanıcı Tipi | User Story | Kabul Kriterleri | 
|--------|----------------|------------|------------------|
| US-007 | Freelancer | Bir mimar olarak, projelere teklif verirken önceki işlerimden örnekler ekleyebilmeliyim ki referanslarım görünsün. | ✔ Portfolyo yükleme alanı çalışıyor. ✔ Max 3 dosya eklenebiliyor. |

---

## 3. Yetkinlik Değerlendirme

| ID     | Kullanıcı Tipi | User Story | Kabul Kriterleri | 
|--------|----------------|------------|------------------|
| US-008 | Freelancer | Bir teknik ressam olarak, AutoCAD testini geçtiğimde profilimde otomatik rozet görünmeli ki yetkinliğim kanıtlansın. | ✔ Test tamamlandığında rozet atanıyor. ✔ Rozet profil sayfasında görünüyor. | 
| US-009 | Sistem | Bir sistem olarak, kullanıcıların test sonuçlarını puanlamalıyım ki objektif değerlendirme yapılabilsin. | ✔ Doğru/yanlış cevaplar otomatik puanlanıyor. ✔ 70+ alanlara rozet veriliyor. |
---

## 4. Ödeme ve Güvenlik

| ID     | Kullanıcı Tipi | User Story | Kabul Kriterleri |
|--------|----------------|------------|------------------|
| US-010 | Freelancer | Bir tasarımcı olarak, proje tamamlandığında ödemenin zamanında yapıldığını görebilmeliyim ki güvenle çalışayım. | ✔ Ödeme durumu dashboard'da görünüyor. ✔ Banka entegrasyonu çalışıyor. |
| US-011 | Sistem | Bir sistem olarak, kullanıcıların şifrelerini güvenli şifreleme ile saklamalıyım ki veri sızıntısı önlensin. | ✔ Şifreler veritabanında hash'lenmiş olarak tutuluyor. |

---

## Öncelik Matrisi

| Öncelik    | User Story ID'leri             | Açıklama                    |
|------------|--------------------------------|-----------------------------|
| **Yüksek** | US-001, US-003, US-005, US-008 | MVP için zorunlu işlevler   |
| **Orta**   | US-004, US-006, US-010         | İkinci fazda geliştirilecek |
| **Düşük**  | US-007 (gelişmiş portfolyo)    | Sonraki sürümler için       |

---



