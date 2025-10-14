# TasarımcıBulutu Kullanıcı Senaryoları

## 1. Freelancer (Tasarımcı/Mühendis) Senaryoları

### Senaryo 1: Kayıt Olma ve Profil Oluşturma
**Amaç:** Freelancer'ın platforma kaydolup yetkinliklerini tanıtabilmesi.  
**Akış:**  
1. Kullanıcı, ana sayfadan "Tasarımcı Olarak Kayıt Ol" butonuna tıklar.  
2. E-posta, şifre ve temel bilgileri (ad, soyad, uzmanlık alanı) girer.  
3. E-posta doğrulama linki gönderilir. Hesap aktif edilir.  
4. Profil sayfasına yönlendirilir:  
   - **CAD Yazılım Bilgisi:** Autodesk Inventor, SolidWorks gibi araçlardan seçim yapar.  
   - **Yetkinlik Testi:** "AutoCAD Temel Testi"ni tamamlar ve 85 puan alır.  
   - **Portfolyo:** Önceki projelerinden 3 adet .dwg dosyası yükler.  

**MVP'de Kritik:** ✔ E-posta doğrulama ✔ Yetkinlik testi ✔ Dosya yükleme (max 10MB).

---

### Senaryo 2: Proje Bulma ve Teklif Verme
**Amaç:** Freelancer'ın ilanları görüntüleyip teklif göndermesi.  
**Akış:**  
1. "Projeler" sekmesinde filtreler:  
   - **Yazılım:** SolidWorks  
   - **Bütçe:** 5.000-10.000 TL  
2. "Endüstriyel Makine Tasarımı" ilanına teklif verir:  
   - **Teklif:** 8.000 TL, 7 günde teslim.  
   - **Portfolyo:** Profilindeki örnekleri ekler.  

---

## 2. Firma Sahibi Senaryoları

### Senaryo 3: Firma Profilini Oluşturma
**Amaç:** Firma bilgilerini ekleyip takım üyesi davet etme.  
**Akış:**  
1. "Firma Olarak Kayıt Ol" seçeneğiyle:  
   - **Şirket Adı:** ABC Makine Sanayi  
   - **Vergi No:** 1234567890  
2. Dashboard'dan logo yükler ve satın alma sorumlusunu ekler.  

**MVP'de Gerekli:** ✔ Çoklu kullanıcı desteği ✔ Firma profili.

---

### Senaryo 4: Proje İlanı Yayınlama
**Amaç:** Karmaşık proje için freelancer bulma.  
**Akış:**  
1. "Yeni Proje Yayınla" butonuna basar:  
   - **Bütçe:** 50.000-70.000 TL (gizli)  
   - **Zorunlu Yetkinlik:** "İleri Seviye SolidWorks"  
2. Teknik şartname PDF'i yükler.  

---

### Senaryo 5: Teklif Değerlendirme
**Amaç:** En uygun freelancer'ı seçme.  
**Akış:**  
1. 8 teklifi karşılaştırır:  
   - **Filtre:** 4.5+ puan, 30 günden kısa süre.  
2. Freelancer X'i seçer ve sözleşme imzalar.  

---

## 3. Sistem Senaryoları

### Senaryo 6: Yetkinlik Testi Otomasyonu
**Amaç:** CAD test sonuçlarını otomatik değerlendirme.  
**Akış:**  
1. Freelancer SolidWorks testini tamamlar (80/100).  
2. Sistem otomatik rozet atar.  

**MVP'de Kritik:** ✔ Otomatik puanlama.

---

### Senaryo 7: KVKK Uyumlu Veri Silme
**Amaç:** Kullanıcı hesabını kalıcı silme.  
**Akış:**  
1. "Hesabı Sil" butonuna basar.  
2. 7 gün içinde onaylarsa veriler silinir.  

---

## Öncelik Tablosu

| Senaryo No | MVP'de Var? | Öncelik |  
|------------|-------------|---------|  
| 1, 3, 4   | ✅ Evet     | Yüksek  |  
| 2, 5      | ⚠️ Kısmen  | Orta    |  
| 6, 7      | ✅ Evet     | Yüksek  |  

---