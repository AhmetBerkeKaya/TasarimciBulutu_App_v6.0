// lib/data/models/user_summary_model.dart

class UserSummary {
  final String id;
  final String name;
  final String? profilePictureUrl;

  UserSummary({
    required this.id,
    required this.name,
    this.profilePictureUrl,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String? ?? 'Bilinmeyen ID',
      name: json['name'] as String? ?? 'İsimsiz Kullanıcı',
      // ========================================================
      // ===                 DÜZELTME BURADA                  ===
      // ========================================================
      // 'profile_picture' yerine doğru anahtar olan 'profile_picture_url' kullanılıyor.
      profilePictureUrl: json['profile_picture_url'] as String?,
      // ========================================================
    );
  }
}