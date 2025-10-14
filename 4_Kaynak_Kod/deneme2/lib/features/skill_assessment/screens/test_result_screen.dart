// lib/features/skill_assessment/screens/test_result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/skill_test_provider.dart';

class TestResultScreen extends StatelessWidget {
  final bool isTimeUp;

  const TestResultScreen({super.key, this.isTimeUp = false});

  @override
  Widget build(BuildContext context) {
    const double passingScore = 70.0; // Geçme notunu 70 olarak belirleyelim
    final provider = context.read<SkillTestProvider>();
    final result = provider.finalResult;

    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('Sonuç yüklenirken bir hata oluştu.')),
      );
    }

    final bool passed = result.score != null && result.score! >= passingScore;
    final Color resultColor = passed ? Colors.green : Colors.red;
    final IconData resultIcon = passed ? Icons.check_circle_outline : Icons.highlight_off;

    String title = passed ? 'Tebrikler, Testi Geçtiniz!' : 'Testi Geçemediniz';
    if(isTimeUp) {
      title = 'Süreniz Doldu!';
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonucu'),
        automaticallyImplyLeading: false, // Geri butonunu kaldır
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(isTimeUp ? Icons.timer_off_outlined : resultIcon, size: 100, color: resultColor),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              'Skorunuz',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              '${result.score?.toStringAsFixed(0) ?? 'N/A'}%',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: resultColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (passed)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'KAZANILAN ROZET',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          'ProAEC Onaylı ${provider.activeTest?.software ?? ''} Yetkinliği',
                        ),
                        backgroundColor: Colors.blue.shade100,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bu rozet artık profilinizde görünecek.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),
            ElevatedButton(
              onPressed: () async { // Fonksiyonu 'async' yapıyoruz
                // Önce AuthProvider'daki kullanıcı verisini arkaplanda yenile
                await context.read<AuthProvider>().refreshUserData();

                // Sonra provider'daki mevcut test durumunu temizle
                provider.clearTestState();

                // Ve en son ana sayfaya dön
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}