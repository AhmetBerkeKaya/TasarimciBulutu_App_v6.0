// lib/data/models/project_model.dart

import 'package:collection/collection.dart';
import 'review_model.dart';
import 'application_model.dart';
import 'user_summary_model.dart';
import 'enums.dart';
import 'skill_model.dart'; // <-- YENİ: Skill modelini import ediyoruz

class Project {
  final String id;
  final String title;
  final String? description;
  final int? budgetMin;
  final int? budgetMax;
  final DateTime? deadline;
  final ProjectStatus status;
  final UserSummary owner;
  final List<Application> applications;
  final List<Review> reviews;
  final String category;
  final DateTime createdAt;
  final List<Skill> requiredSkills; // <-- YENİ: Gerekli yetenekler listesi

  // === YENİ ALAN: REVIZYON GEÇMİŞİ ===
  final List<ProjectRevision> revisions;
  // ===================================

  Project({
    required this.id,
    required this.title,
    this.description,
    this.budgetMin,
    this.budgetMax,
    this.deadline,
    required this.status,
    required this.owner,
    required this.applications,
    required this.reviews,
    required this.category,
    required this.createdAt,
    required this.requiredSkills,

    // === YENİ PARAMETRE ===
    this.revisions = const [], // Varsayılan olarak boş liste
    // ======================
  });

  Application? get acceptedApplication => applications.firstWhereOrNull(
        (app) => app.status == ApplicationStatus.accepted,
  );

  factory Project.fromJson(Map<String, dynamic> json) {
    // Status alanını çökmeden, güvenli bir şekilde oku
    ProjectStatus status;
    try {
      final statusString = json['status']?.toString();
      if (statusString == null) {
        status = ProjectStatus.open;
      } else {
        status = ProjectStatus.values.firstWhere(
              (e) => e.name == statusString,
          orElse: () => ProjectStatus.open,
        );
      }
    } catch (e) {
      status = ProjectStatus.open;
    }

    // Tarih alanlarını çökmeden, güvenli bir şekilde oku
    DateTime? deadline = json['deadline'] != null
        ? DateTime.tryParse(json['deadline'].toString())
        : null;
    DateTime createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'].toString())
        : DateTime.now();

    return Project(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Başlıksız Proje',
      description: json['description']?.toString(),
      budgetMin: (json['budget_min'] as num?)?.toInt(),
      budgetMax: (json['budget_max'] as num?)?.toInt(),
      deadline: deadline,
      owner: json['owner'] != null
          ? UserSummary.fromJson(json['owner'])
          : UserSummary(id: '', name: 'Bilinmeyen Firma'),
      applications: (json['applications'] as List<dynamic>?)
          ?.map((appJson) => Application.fromJson(appJson))
          .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((reviewJson) => Review.fromJson(reviewJson))
          .toList() ??
          [],
      status: status,
      category: json['category']?.toString() ?? 'Genel',
      createdAt: createdAt,
      // <-- YENİ: Gelen JSON'daki 'required_skills' listesini parse ediyoruz
      requiredSkills: (json['required_skills'] as List<dynamic>?)
          ?.map((skillJson) => Skill.fromJson(skillJson))
          .toList() ??
          [],

      // === YENİ: REVIZYONLARI PARSE ET ===
      revisions: (json['revisions'] as List<dynamic>?)
          ?.map((e) => ProjectRevision.fromJson(e))
          .toList() ??
          [],
      // ===================================
    );
  }
}

// === YENİ MODEL SINIFI: PROJE REVIZYONU ===
class ProjectRevision {
  final String id;
  final String requestReason;
  final DateTime requestedAt;

  ProjectRevision({
    required this.id,
    required this.requestReason,
    required this.requestedAt
  });

  factory ProjectRevision.fromJson(Map<String, dynamic> json) {
    return ProjectRevision(
      id: json['id'],
      requestReason: json['request_reason'],
      requestedAt: DateTime.parse(json['requested_at']),
    );
  }
}