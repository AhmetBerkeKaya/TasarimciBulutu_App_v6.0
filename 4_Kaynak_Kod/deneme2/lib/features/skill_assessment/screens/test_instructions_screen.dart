// lib/features/skill_assessment/screens/test_instructions_screen.dart

import 'package:deneme2/features/skill_assessment/screens/test_taking_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/skill_test_provider.dart';
import '../../../data/models/skill_test.dart';

class TestInstructionsScreen extends StatefulWidget {
  final String testId;

  const TestInstructionsScreen({super.key, required this.testId});

  @override
  State<TestInstructionsScreen> createState() => _TestInstructionsScreenState();
}

class _TestInstructionsScreenState extends State<TestInstructionsScreen> {
  @override
  void initState() {
    super.initState();
    // GÜNCELLENDİ: Ekran açılır açılmaz test detaylarını çekiyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SkillTestProvider>(context, listen: false);
      provider.clearTestState();
      provider.fetchTestDetails(widget.testId);
    });
  }

  // GÜNCELLENDİ: Bu metod artık sadece provider'daki testi başlatır.
  void _startTest() async {
    final provider = Provider.of<SkillTestProvider>(context, listen: false);

    final success = await provider.startTest();

    if (success && mounted) {
      // Yönlendirme yapılıyor...
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TestTakingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Artık Consumer/watch kullanarak provider'daki durumu dinliyoruz.
    return Consumer<SkillTestProvider>(
      builder: (context, provider, child) {
        final test = provider.activeTest;

        return Scaffold(
          appBar: AppBar(
            title: Text(test?.title ?? 'Test Yükleniyor...'),
          ),
          body: provider.isLoading && test == null
              ? const LoadingIndicator()
              : test == null
              ? const Center(child: Text('Test detayları yüklenemedi.'))
              : _buildContent(context, provider, test),
        );
      },
    );
  }

  // Arayüzü daha okunaklı kılmak için içeriği ayrı bir metoda taşıdık.
  Widget _buildContent(BuildContext context, SkillTestProvider provider, SkillTest test) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            test.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            test.description ?? "Bu test için bir açıklama bulunmamaktadır.",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn('Soru Sayısı', test.questions?.length.toString() ?? '0'),
                  _buildInfoColumn('Yazılım', test.software),
                ],
              ),
            ),
          ),
          const Spacer(flex: 2),
          // Testi başlatma işlemi sürüyorsa butonu devre dışı bırak
          provider.isLoading
              ? const Center(child: LoadingIndicator())
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: Theme.of(context).textTheme.titleLarge,
            ),
            onPressed: _startTest,
            child: const Text('Teste Başla'),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}