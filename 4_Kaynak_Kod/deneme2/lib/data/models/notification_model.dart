// lib/data/models/notification_model.dart

import 'package:flutter/foundation.dart';
import 'user_summary_model.dart'; // Eylemi yapan kullanıcıyı (actor) modellemek için

// Backend'deki NotificationType enum'unun Dart karşılığı
enum NotificationType {
  // Mesajlaşma
  newMessage,
  // Başvurular
  applicationSubmitted,
  applicationAccepted,
  applicationRejected,
  // Proje Teslimat ve Onay Süreci
  projectDelivered,
  deliveryAccepted,
  revisionRequested,
  // Projeler
  projectCompleted,
  projectCancelled,
  // Değerlendirmeler
  newReview,
  // Vitrin (Showcase) Etkileşimleri
  postLiked,
  postCommented,
  commentLiked,
  commentReplied,
  // Sistem ve Yapay Zeka
  welcome,
  skillTestResult,
  newProjectRecommendation,
  // Bilinmeyen bir tür gelirse diye güvenlik önlemi
  unknown;

  // JSON'dan gelen string'i enum'a çeviren factory
  static NotificationType fromJson(String? typeString) {
    if (typeString == null) return NotificationType.unknown;
    // Gelen string'i enum'un adıyla eşleştir
    try {
      // Örnek: "new_message" string'ini NotificationType.newMessage'a çevirir
      return NotificationType.values.firstWhere(
            (e) => e.name.toLowerCase() == typeString.replaceAll('_', '').toLowerCase(),
      );
    } catch (e) {
      debugPrint("Bilinmeyen bildirim türü: $typeString");
      return NotificationType.unknown;
    }
  }
}

class NotificationModel {
  final String id;
  final String content; // Backend'deki 'content' alanına karşılık gelir
  final bool isRead;
  final DateTime createdAt;
  final NotificationType type;
  final UserSummary? actor; // Bildirimi tetikleyen kullanıcı (opsiyonel)
  final String? relatedEntityId; // Tıklayınca gidilecek ID (opsiyonel)

  NotificationModel({
    required this.id,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.type,
    this.actor,
    this.relatedEntityId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      // Backend'deki 'content' alanını kullanıyoruz
      content: json['content'] as String? ?? 'İçerik bulunamadı.',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
      // Gelen string'i güvenli bir şekilde enum'a çeviriyoruz
      type: NotificationType.fromJson(json['type']),
      // 'actor' alanı null olabilir, bu yüzden null kontrolü yapıyoruz
      actor: json['actor'] != null ? UserSummary.fromJson(json['actor']) : null,
      relatedEntityId: json['related_entity_id'],
    );
  }

  // Provider'da okundu durumunu güncellerken işe yarayacak yardımcı fonksiyon
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      type: type,
      actor: actor,
      relatedEntityId: relatedEntityId,
    );
  }
}