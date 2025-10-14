// lib/data/models/test_result_model.dart
import 'package:deneme2/data/models/skill_test.dart';

class TestResult {
  final String id;
  final String userId;
  final String testId;
  final double? score;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SkillTest skillTest;

  TestResult({
    required this.id,
    required this.userId,
    required this.testId,
    this.score,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.skillTest,

  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      userId: json['user_id'],
      testId: json['test_id'],
      score: json['score'] != null ? double.tryParse(json['score'].toString()) : null,
      status: json['status'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      skillTest: SkillTest.fromJson(json['skill_test']),
    );
  }
}