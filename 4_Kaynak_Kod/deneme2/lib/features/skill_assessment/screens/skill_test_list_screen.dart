// lib/features/skill_assessment/screens/skill_test_list_screen.dart

import 'package:deneme2/features/skill_assessment/screens/test_instructions_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/skill_test_provider.dart';
import '../../../common_widgets/loading_indicator.dart'; // Mevcut loading widget'ınız
import '../../../common_widgets/empty_state.dart';   // Mevcut empty state widget'ınız
import 'package:collection/collection.dart'; // <-- BU SATIRI EKLEYİN

class SkillTestListScreen extends StatefulWidget {
  const SkillTestListScreen({super.key});

  @override
  State<SkillTestListScreen> createState() => _SkillTestListScreenState();
}

class _SkillTestListScreenState extends State<SkillTestListScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz testleri çekmek için provider'ı tetikliyoruz.
    // 'listen: false' initState içinde provider çağırmak için önemlidir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillTestProvider>(context, listen: false).fetchSkillTests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetkinlik Testleri'),
      ),
      body: Consumer<SkillTestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          if (provider.tests.isEmpty) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              message: 'Şu anda mevcut bir yetkinlik testi bulunmuyor.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchSkillTests(),
            child: ListView.builder(
              itemCount: provider.tests.length,
              itemBuilder: (context, index) {
                final test = provider.tests[index];
                // Kullanıcının tamamladığı test sonuçlarını al
                final authProvider = context.read<AuthProvider>();
                final completedTestResult = authProvider.user?.testResults.firstWhereOrNull(
                      (result) => result.testId == test.id && result.status == 'completed',
                );

                final bool isCompleted = completedTestResult != null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      isCompleted ? Icons.check_circle : Icons.quiz_outlined,
                      color: isCompleted ? Colors.green : null,
                    ),
                    title: Text(test.title),
                    subtitle: Text('Yazılım: ${test.software}'),
                    trailing: isCompleted
                        ? Text(
                      '%${completedTestResult.score?.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    )
                        : const Icon(Icons.chevron_right),
                    onTap: isCompleted
                        ? null // Test tamamlandıysa tıklanamaz yap
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestInstructionsScreen(testId: test.id),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          );
        },
      ),
    );
  }
}