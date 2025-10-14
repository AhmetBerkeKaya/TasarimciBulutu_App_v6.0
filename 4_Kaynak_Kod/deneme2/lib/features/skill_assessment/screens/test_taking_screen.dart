// lib/features/skill_assessment/screens/test_taking_screen.dart
import 'dart:async';
import 'package:deneme2/features/skill_assessment/screens/test_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/skill_test_provider.dart';

class TestTakingScreen extends StatefulWidget {
  const TestTakingScreen({super.key});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SkillTestProvider>(context, listen: false);
    // Backend'den süre bilgisi gelmiyorsa varsayılan 10 dakika
    final durationInMinutes = provider.activeTest?.questions?.length ?? 10;
    _remainingSeconds = durationInMinutes * 60;
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
    final success = await provider.submitTest();
    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TestResultScreen(isTimeUp: isTimeUp)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test gönderilirken bir hata oluştu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SkillTestProvider>(
      builder: (context, provider, child) {
        if (provider.activeTest == null || provider.activeTest!.questions!.isEmpty) {
          return const Scaffold(body: Center(child: Text('Test yüklenemedi.')));
        }

        final questions = provider.activeTest!.questions!;
        final currentQuestion = questions[_currentIndex];
        final totalQuestions = questions.length;
        final selectedChoiceId = provider.userAnswers[currentQuestion.id];

        final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
        final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

        return WillPopScope(
          onWillPop: () async {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Testten Çıkmak İstiyor Musunuz?'),
                content: const Text('Geri dönerseniz testiniz sonlandırılacak ve cevaplarınız kaydedilmeyecektir.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Çık')),
                ],
              ),
            );
            return shouldPop ?? false;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Soru ${_currentIndex + 1} / $totalQuestions'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      '$minutes:$seconds',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _remainingSeconds < 60 ? Colors.red : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentQuestion.questionText,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion.choices.length,
                      itemBuilder: (context, index) {
                        final choice = currentQuestion.choices[index];
                        return Card(
                          color: selectedChoiceId == choice.id ? Theme.of(context).colorScheme.primaryContainer : null,
                          child: ListTile(
                            title: Text(choice.choiceText),
                            onTap: () {
                              provider.selectAnswer(currentQuestion.id, choice.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        ElevatedButton(
                          onPressed: () => setState(() => _currentIndex--),
                          child: const Text('Önceki Soru'),
                        ),
                      if (_currentIndex < totalQuestions - 1)
                        ElevatedButton(
                          onPressed: () => setState(() => _currentIndex++),
                          child: const Text('Sonraki Soru'),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: provider.isLoading ? null : () => _submitTest(),
                          child: provider.isLoading ? const LoadingIndicator() : const Text('Testi Bitir'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}