import 'package:deneme2/data/models/project_model.dart';
import 'package:deneme2/data/models/user_summary_model.dart';

import 'enums.dart';

class Application {
  final String id;
  final String? coverLetter;
  final int? proposedBudget;
  final ApplicationStatus status;
  final DateTime createdAt;
  final UserSummary freelancer;
  final Project project; // Artık tam proje nesnesi

  Application({
    required this.id,
    this.coverLetter,
    this.proposedBudget,
    required this.status,
    required this.createdAt,
    required this.freelancer,
    required this.project,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] ?? '',
      coverLetter: json['cover_letter'],
      proposedBudget: (json['proposed_budget'] as num?)?.toInt(),
      status: ApplicationStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      freelancer: UserSummary.fromJson(json['freelancer'] ?? {}),
      project: Project.fromJson(json['project'] ?? {}),
    );
  }
}