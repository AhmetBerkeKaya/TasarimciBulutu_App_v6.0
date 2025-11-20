// lib/features/skill_assessment/screens/test_taking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/skill_test_provider.dart';
import 'test_result_screen.dart';

class TestTakingScreen extends StatefulWidget {
  const TestTakingScreen({super.key});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalDuration = 0; // İlerleme çubuğu için toplam süre

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SkillTestProvider>(context, listen: false);
    final questionCount = provider.activeTest?.questions?.length ?? 0;
    final durationInMinutes = questionCount > 0 ? (questionCount * 1.5).ceil() : 10;
    _remainingSeconds = durationInMinutes * 60;
    _totalDuration = _remainingSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitTest(isTimeUp: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitTest({bool isTimeUp = false}) async {
    final provider = Provider.of<SkillTestProvider>(context, listen: false);

    // Yükleme göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.submitTest();

    if (mounted) {
      Navigator.pop(context); // Loading dialog kapat

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TestResultScreen(isTimeUp: isTimeUp)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test gönderilirken bir hata oluştu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Testten Çıkmak İstiyor Musunuz?'),
        content: const Text('Geri dönerseniz testiniz sonlandırılacak ve cevaplarınız kaydedilmeyecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Çık', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<SkillTestProvider>(
      builder: (context, provider, child) {
        if (provider.activeTest == null || provider.activeTest!.questions!.isEmpty) {
          return const Scaffold(body: Center(child: Text('Test verisi yüklenemedi.')));
        }

        final questions = provider.activeTest!.questions!;
        final currentQuestion = questions[_currentIndex];
        final totalQuestions = questions.length;
        final selectedChoiceId = provider.userAnswers[currentQuestion.id];

        // Süre Formatı
        final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
        final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
        final isLowTime = _remainingSeconds < 60; // Son 1 dakika uyarısı

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false, // Geri butonunu gizle (WillPopScope yönetiyor)
              backgroundColor: theme.cardColor,
              elevation: 1,
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      color: isLowTime ? Colors.red : theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLowTime ? Colors.red : theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()], // Rakamlar titremesin diye
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _onWillPop,
                  child: Text("Çıkış", style: TextStyle(color: theme.colorScheme.error)),
                )
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / totalQuestions,
                  backgroundColor: theme.disabledColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Soru Sayacı
                        Text(
                          'Soru ${_currentIndex + 1} / $totalQuestions',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Soru Metni
                        Text(
                          currentQuestion.questionText,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: theme.colorScheme.onBackground
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Seçenekler
                        ...currentQuestion.choices.map((choice) {
                          final isSelected = selectedChoiceId == choice.id;
                          return _buildOptionCard(
                            context: context,
                            text: choice.choiceText,
                            isSelected: isSelected,
                            onTap: () => provider.selectAnswer(currentQuestion.id, choice.id),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

                // Alt Navigasyon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        )
                      ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _currentIndex--),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                          label: const Text('Önceki'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else
                        const SizedBox(width: 100), // Boşluk tutucu

                      if (_currentIndex < totalQuestions - 1)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _currentIndex++),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                            label: const Text('Sonraki'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : () => _submitTest(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Testi Bitir'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : theme.dividerColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Radyo Düğmesi Görünümü
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? theme.primaryColor : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? theme.primaryColor : Colors.grey.shade400,
                      width: 2
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}