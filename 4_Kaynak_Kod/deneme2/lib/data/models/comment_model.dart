// lib/data/models/comment_model.dart

import 'user_summary_model.dart';

class CommentLike {
  final String userId;
  final String commentId;

  CommentLike({required this.userId, required this.commentId});

  factory CommentLike.fromJson(Map<String, dynamic> json) {
    return CommentLike(
      userId: json['user_id'],
      commentId: json['comment_id'],
    );
  }
}

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final UserSummary author;
  final List<CommentLike> likes;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    required this.likes,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      author: UserSummary.fromJson(json['author']),
      likes: (json['likes'] as List? ?? [])
          .map((likeJson) => CommentLike.fromJson(likeJson))
          .toList(),
      replies: (json['replies'] as List? ?? [])
          .map((replyJson) => Comment.fromJson(replyJson))
          .toList(),
    );
  }
}
