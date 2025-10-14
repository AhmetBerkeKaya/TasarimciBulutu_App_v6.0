// =======================================================================
// DOSYA 3: lib/features/profile/screens/privacy_policy_screen.dart
// =======================================================================
import 'package:flutter/material.dart';
import '../widgets/legal_page_widget.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageView(
      pageTitle: 'Gizlilik Politikası',
      sections: [
        LegalSectionData(
          title: '1. Veri Sorumlusunun Kimliği',
          content:
          '6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) uyarınca, kişisel verileriniz; veri sorumlusu olarak Tasarımcı Bulutu ("Platform") tarafından aşağıda açıklanan kapsamda işlenebilecektir.',
        ),
        LegalSectionData(
          title: '2. Kişisel Verilerin İşlenme Amaçları',
          content:
          'Toplanan kişisel verileriniz, platform hizmetlerinin sunulması, kullanıcı hesaplarının yönetimi, hizmet kalitesinin artırılması, yasal yükümlülüklerin yerine getirilmesi, platform güvenliğinin sağlanması, kullanıcılar arası iletişimin kolaylaştırılması ve size özel proje önerileri sunulması amaçlarıyla KVKK’nın 5. ve 6. maddelerinde belirtilen kişisel veri işleme şartları ve amaçları dahilinde işlenecektir.',
        ),
        LegalSectionData(
          title: '3. İşlenen Kişisel Veri Kategorileri',
          content:
          'Platformumuz, kimlik bilgileriniz (ad, soyad), iletişim bilgileriniz (e-posta adresi, telefon numarası), mesleki deneyim bilgileriniz (portfolyo, yetenekler, iş geçmişi), işlem güvenliği bilgileriniz (IP adresi, log kayıtları) ve platformu kullanımınıza ilişkin diğer verileri işlemektedir.',
        ),
        LegalSectionData(
          title: '4. Kişisel Verilerin Aktarılması',
          content:
          'Kişisel verileriniz, yasal zorunluluklar ve rızanız dışında üçüncü kişilerle paylaşılmaz. Ancak, hizmetlerin sağlanması amacıyla iş ortaklarımızla, tedarikçilerimizle ve yasal olarak yetkili kamu kurum ve kuruluşları ile KVKK’nın 8. ve 9. maddelerinde belirtilen şartlar çerçevesinde paylaşılabilecektir.',
        ),
        LegalSectionData(
          title: '5. Kişisel Veri Sahibinin Hakları',
          content:
          'KVKK’nın 11. maddesi uyarınca veri sahibi olarak; kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, işlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme, yurt içinde veya yurt dışında kişisel verilerin aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmiş olması hâlinde bunların düzeltilmesini isteme ve bu kapsamda yapılan işlemin kişisel verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme, kanuna aykırı olarak işlenmesi sebebiyle zarara uğramanız hâlinde zararın giderilmesini talep etme haklarına sahipsiniz. Bu haklarınızı kullanmak için [destek@tasarimcibulutu.com] adresi üzerinden bizimle iletişime geçebilirsiniz.',
          isLast: true,
        ),
      ],
    );
  }
}