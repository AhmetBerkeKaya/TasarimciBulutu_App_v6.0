// lib/data/models/message_model.dart
import 'package:deneme2/data/models/user_summary_model.dart';

class Message {
  final String id;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final UserSummary sender;
  final UserSummary receiver;

  Message({
    required this.id,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.sender,
    required this.receiver,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      sender: UserSummary.fromJson(json['sender']),
      receiver: UserSummary.fromJson(json['receiver']),
    );
  }
}