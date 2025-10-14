// lib/data/models/portfolio_item_model.dart
class PortfolioItem {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;

  PortfolioItem({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }
}