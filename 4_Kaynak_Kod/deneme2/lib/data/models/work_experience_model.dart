// lib/data/models/work_experience_model.dart
class WorkExperience {
  final String id;
  final String title;
  final String companyName;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;

  WorkExperience({
    required this.id,
    required this.title,
    required this.companyName,
    required this.startDate,
    this.endDate,
    this.description,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'],
      title: json['title'],
      companyName: json['company_name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      description: json['description'],
    );
  }
}