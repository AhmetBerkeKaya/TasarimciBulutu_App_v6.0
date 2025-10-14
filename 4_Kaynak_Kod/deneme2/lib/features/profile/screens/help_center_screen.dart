// =======================================================================
// DOSYA 2: lib/features/profile/screens/help_center_screen.dart (Eski faq_screen.dart)
// =======================================================================
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  final List<Map<String, String>> faqData = const [
    {
      'question': 'Tasarımcı Bulutu nedir?',
      'answer': 'Tasarımcı Bulutu, Türkiye\'deki freelance tasarım ve mühendislik profesyonelleri ile bu yeteneklere ihtiyaç duyan firmaları bir araya getiren bir proje pazar yeridir.'
    },
    {
      'question': 'Platforma üyelik ücretli mi?',
      'answer': 'Platforma kaydolmak ve profil oluşturmak hem freelancerlar hem de müşteriler için tamamen ücretsizdir. Sadece tamamlanan projeler üzerinden belirli bir hizmet bedeli alınmaktadır.'
    },
    {
      'question': 'Yetenek testleri ne işe yarıyor?',
      'answer': 'Yetenek testleri, freelancerların belirli yazılım ve tasarım disiplinlerindeki yetkinliklerini objektif bir şekilde kanıtlamalarını sağlar. Başarıyla tamamlanan testler, profilinizde bir rozet olarak sergilenir ve müşterilerin size olan güvenini artırır.'
    },
    {
      'question': 'Ödemeler nasıl güvence altına alınıyor?',
      'answer': 'Müşteri bir projeyi başlattığında, proje bedeli güvenli bir emanet hesabına (escrow) aktarılır. Freelancer projeyi teslim edip müşteri onayladığında, ödeme freelancerın hesabına transfer edilir. Bu sistem her iki tarafı da korur.'
    },
    {
      'question': 'Bir proje ile ilgili anlaşmazlık yaşarsam ne yapmalıyım?',
      'answer': 'Platformumuz, taraflar arasında yaşanabilecek anlaşmazlıklar için bir çözüm merkezi sunmaktadır. Destek ekibimizle iletişime geçerek sorunun çözümü için yardım talep edebilirsiniz.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım Merkezi & SSS'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqData.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                faqData[index]['question']!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Text(
                    faqData[index]['answer']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}