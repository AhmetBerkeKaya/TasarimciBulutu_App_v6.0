// lib/data/models/notification_model.dart
class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}