import 'package:flutter/material.dart';
import '../widgets/legal_page_widget.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageView(
      pageTitle: 'Kullanım Koşulları',
      sections: [
        LegalSectionData(
          title: '1. Taraflar ve Tanımlar',
          content:
          'İşbu Kullanım Koşulları ("Sözleşme"), Tasarımcı Bulutu platformunun ("Platform") sahibi olan [Şirket Adı] ile Platform’a üye olan ve hizmetlerden faydalanan kullanıcı ("Kullanıcı") arasındaki şartları ve koşulları düzenlemektedir. Freelancer, hizmet sunan kullanıcıyı; Müşteri ise hizmet alan kullanıcıyı ifade eder.',
        ),
        LegalSectionData(
          title: '2. Platformun Amacı ve Kapsamı',
          content:
          'Platform, Freelancerlar ile Müşterileri bir araya getirerek tasarım ve mühendislik projeleri için bir pazar yeri oluşturmayı amaçlamaktadır. Platform, taraflar arasındaki anlaşma veya projenin içeriği konusunda taraf değildir ve sorumluluk kabul etmez.',
        ),
        LegalSectionData(
          title: '3. Üyelik ve Hesap Güvenliği',
          content:
          'Kullanıcı, platforma üye olurken verdiği bilgilerin doğru ve güncel olduğunu kabul eder. Hesap güvenliğinin sağlanmasından tamamen Kullanıcı sorumludur. Hesabın yetkisiz kullanımından doğacak zararlardan Platform sorumlu tutulamaz.',
        ),
        LegalSectionData(
          title: '4. Yasaklı Faaliyetler',
          content:
          'Kullanıcılar, platformu yasa dışı amaçlarla kullanamaz, yanıltıcı veya sahte bilgilerle profil oluşturamaz, diğer kullanıcıları taciz edemez veya platform dışı ödeme yöntemleri teklif edemez. Bu tür faaliyetlerin tespiti halinde, Platform ilgili hesabı askıya alma veya kalıcı olarak kapatma hakkını saklı tutar.',
        ),
        LegalSectionData(
          title: '5. Fikri Mülkiyet Hakları',
          content:
          'Kullanıcılar tarafından yüklenen tüm içeriklerin (portfolyo, tasarımlar vb.) fikri mülkiyet hakları kendilerine aittir. Ancak Kullanıcı, bu içeriklerin Platform üzerinde profili kapsamında sergilenmesi için Platform\'a münhasır olmayan, dünya çapında geçerli bir lisans verdiğini kabul eder.',
          isLast: true,
        ),
      ],
    );
  }
}