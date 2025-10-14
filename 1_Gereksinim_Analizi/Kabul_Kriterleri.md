# 📋 TasarımcıBulutu - Kabul Kriterleri Dokümantasyonu

## 1️⃣ KULLANICI YÖNETİMİ

### 🔐 US-001: Freelancer Kayıt Akışı
**✅ Kabul Kriterleri:**
1. **Form Validasyonu**
   - [ ] E-posta alanı RFC 5322 standardına uygun
   - [ ] Şifre alanı en az 1 büyük harf, 1 sayı ve 1 özel karakter zorunlu
   
2. **E-posta Doğrulama**
   ```mermaid
   sequenceDiagram
       Kullanıcı->>Sunucu: Kayıt isteği gönder
       Sunucu->>SMTP: Doğrulama e-postası ilet
       SMTP-->>Kullanıcı: E-posta ulaşır (max 5 dk)
       Kullanıcı->>Sunucu: Linke tıklama
       Sunucu-->>Kullanıcı: Profil oluşturma sayfası

### 🏢 US-002: Firma Profil Onayı
**✅ Kabul Kriterleri:**

1. **Veri Doğrulama**
    - Vergi numarası 10 haneli ve geçerli formatta
    - Logo boyutu max 2MB (PNG/JPG)

    **Örnek Geçerli Veri:**
    '''bash
        {
        "firma_adi": "ABC Makine",
        "vergi_no": "1234567890",
        "logo": "abc-logo.png"
        }

## 2️⃣ PROJE YÖNETİMİ MODÜLÜ

### 📌 US-003: Proje İlanı Oluşturma
**✅ Temel Kriterler:**
1. **Zorunlu Alanlar:**
   - [ ] Başlık (min. 10 karakter)
   - [ ] Açıklama (min. 50 karakter)
   - [ ] Bütçe aralığı (1.000-50.000 TL)
   - [ ] Teslim süresi (7-90 gün)

2. **Dosya Yükleme:**
   ```mermaid
   flowchart TD
       A[Kullanıcı dosya seçer] --> B{Dosya geçerli mi?}
       B -->|Evet| C[Sunucuya yükle]
       B -->|Hayır| D[Uyarı göster]

## 📌 US-004: Teklif Yönetimi Sistemi

### ✅ Temel Kabul Kriterleri
1. **Teklif Verme Akışı**
   - [ ] Freelancer'lar proje başına en fazla 3 teklif gönderebilmeli
   - [ ] Minimum teklif tutarı: Proje bütçesinin %60'ı
   - [ ] Zorunlu alanlar:
     ```mermaid
     graph LR
         A[Teklif Formu] --> B[Tutar]
         A --> C[Teslim Süresi]
         A --> D[Ön Çalışma Örneği]
     ```

2. **Portfolyo Entegrasyonu**
   | Öğe | Şartlar |
   |------|---------|
   | Dosya Tipi | PDF/DWG/IPT |
   | Max Boyut | 10MB |
   | Max Dosya | 3 adet |
