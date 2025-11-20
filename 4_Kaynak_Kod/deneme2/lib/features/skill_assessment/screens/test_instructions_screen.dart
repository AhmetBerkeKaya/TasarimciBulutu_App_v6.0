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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SkillTestProvider>(context, listen: false);
      provider.clearTestState();
      provider.fetchTestDetails(widget.testId);
    });
  }

  void _startTest() async {
    final provider = Provider.of<SkillTestProvider>(context, listen: false);
    final success = await provider.startTest();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TestTakingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildContent(BuildContext context, SkillTestProvider provider, SkillTest test) {
    final theme = Theme.of(context);

    // --- HESAPLAMALAR ---
    final int questionCount = test.questions?.length ?? 0;
    const int passingScore = 70; // Backend ile uyumlu standart geçme notu

    // Geçmek için gereken minimum doğru sayısı (Yukarı yuvarlama: 5 soru * 0.7 = 3.5 -> 4 doğru)
    final int requiredCorrect = (questionCount * (passingScore / 100)).ceil();

    // Tahmini süre (Soru başı 1.5 dk mantığı, backend'den gelmiyorsa)
    final int durationMinutes = (questionCount * 1.5).ceil();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),

          // İkon (Mor yerine Tema Rengi)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Başlık
          Text(
            test.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Açıklama
          Text(
            test.description ?? "Bu test yetkinliğinizi ölçmek için hazırlanmıştır.",
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // --- DETAYLI BİLGİ KARTI (YENİLENMİŞ) ---
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(child: _buildInfoColumn(context, 'Soru', '$questionCount', Icons.quiz_outlined)),
                  _buildDivider(),
                  Expanded(child: _buildInfoColumn(context, 'Süre', '$durationMinutes dk', Icons.timer_outlined)),
                  _buildDivider(),
                  Expanded(child: _buildInfoColumn(context, 'Geçme', '%$passingScore', Icons.grade_outlined)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- BİLGİLENDİRME METNİ (INFO BOX) ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50, // Hafif turuncu/sarı arka plan
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Rozeti kazanmak için $questionCount sorudan en az $requiredCorrect tanesini doğru cevaplamanız gerekmektedir.",
                    style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                        height: 1.4
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Başlat Butonu
          provider.isLoading
              ? const Center(child: LoadingIndicator())
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: theme.primaryColor.withOpacity(0.4),
            ),
            onPressed: _startTest,
            child: const Text('Teste Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.primaryColor.withOpacity(0.8)),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}