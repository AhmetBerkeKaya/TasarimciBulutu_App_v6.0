// lib/data/models/skill_model.dart

class Skill {
  final String id;
  final String name;
  final String category;

  Skill({required this.id, required this.name, required this.category});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      category: json['category'],
    );
  }

  // DropdownSearch paketinin karşılaştırma yapabilmesi için bu iki metot önemli
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Skill && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}