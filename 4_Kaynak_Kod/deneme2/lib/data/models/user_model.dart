// lib/data/models/user_model.dart

import 'enums.dart';
import 'portfolio_item_model.dart';
import 'review_model.dart'; // Review modelini import et
import 'skill_model.dart';
import 'test_result_model.dart';
import 'work_experience_model.dart';

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? bio;
  final String? profilePictureUrl;
  final List<Skill> skills;
  final List<WorkExperience> workExperiences;
  final List<PortfolioItem> portfolioItems;
  final List<TestResult> testResults;
  final List<Review> reviewsReceived; // --- EN ÖNEMLİ ALAN ---

  // Değerlendirmeler için hesaplanmış alanlar
  final double avgRating;
  final int reviewCount;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.bio,
    this.profilePictureUrl,
    this.skills = const [],
    this.workExperiences = const [],
    this.portfolioItems = const [],
    this.testResults = const [],
    this.reviewsReceived = const [], // Constructor'a ekle
  }) : // Hesaplanan alanları burada initialize et
        avgRating = reviewsReceived.isEmpty
            ? 0.0
            : reviewsReceived.map((r) => r.rating).reduce((a, b) => a + b) / reviewsReceived.length,
        reviewCount = reviewsReceived.length;

  factory User.fromJson(Map<String, dynamic> json) {
    // Gelen "reviews_received" listesini güvenli bir şekilde parse et
    var reviewsList = <Review>[];
    if (json['reviews_received'] != null && json['reviews_received'] is List) {
      reviewsList = (json['reviews_received'] as List)
          .map((reviewJson) => Review.fromJson(reviewJson))
          .toList();
    }

    // Diğer listeleri de aynı şekilde güvenle parse et
    var skillsList = <Skill>[];
    if (json['skills'] != null && json['skills'] is List) {
      skillsList = (json['skills'] as List).map((s) => Skill.fromJson(s)).toList();
    }

    var portfolioList = <PortfolioItem>[];
    if (json['portfolio_items'] != null && json['portfolio_items'] is List) {
      portfolioList = (json['portfolio_items'] as List).map((p) => PortfolioItem.fromJson(p)).toList();
    }

    var experienceList = <WorkExperience>[];
    if (json['work_experiences'] != null && json['work_experiences'] is List) {
      experienceList = (json['work_experiences'] as List).map((e) => WorkExperience.fromJson(e)).toList();
    }

    var testResultList = <TestResult>[];
    if (json['test_results'] != null && json['test_results'] is List) {
      testResultList = (json['test_results'] as List).map((t) => TestResult.fromJson(t)).toList();
    }


    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
            (e) => e.name == json['role'],
        orElse: () => UserRole.freelancer,
      ),
      bio: json['bio'],
      profilePictureUrl: json['profile_picture_url'],
      reviewsReceived: reviewsList, // Parse edilen listeyi ata
      skills: skillsList,
      portfolioItems: portfolioList,
      workExperiences: experienceList,
      testResults: testResultList,
    );
  }
}