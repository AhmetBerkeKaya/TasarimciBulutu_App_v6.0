// lib/data/models/review_model.dart
import 'user_summary_model.dart';

// Backend'e yeni bir review göndermek için kullanılacak model
class ReviewCreate {
  final String projectId;
  final String revieweeId;
  final int rating;
  final String? comment;

  ReviewCreate({
    required this.projectId,
    required this.revieweeId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
    };
  }
}
class ProjectSummary {
  final String id;
  final String title;

  ProjectSummary({required this.id, required this.title});

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['id'],
      title: json['title'],
    );
  }
}
// --- BİTTİ ---
// Backend'den gelen tam bir review verisini temsil eden model
class Review {
  final String id;
  final int rating;
  final String? comment;
  final UserSummary reviewer; // Değerlendirmeyi yapan kişi
  final DateTime createdAt;
  final ProjectSummary project;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.reviewer,
    required this.createdAt,
    required this.project, // <-- CONSTRUCTOR'A EKLE

  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      // Her alanı null kontrolü yaparak güvenli bir şekilde ata
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),

      // reviewer null ise hata verme, boş bir UserSummary ata
      reviewer: json['reviewer'] != null
          ? UserSummary.fromJson(json['reviewer'])
          : UserSummary(id: '', name: 'Bilinmeyen Kullanıcı'),

      // createdAt null veya yanlış formatta ise hata verme, şimdiki zamanı ata
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),

      // project null ise hata verme, boş bir ProjectSummary ata
      project: json['project'] != null
          ? ProjectSummary.fromJson(json['project'])
          : ProjectSummary(id: '', title: 'Bilinmeyen Proje'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'reviewer': reviewer,
      'created_at': createdAt.toIso8601String(),
    };
  }
}