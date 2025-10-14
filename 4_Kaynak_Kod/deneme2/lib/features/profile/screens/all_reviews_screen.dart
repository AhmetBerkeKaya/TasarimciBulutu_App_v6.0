import 'package:flutter/material.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/review_model.dart';
import '../widgets/review_card.dart'; // Birazdan oluşturacağımız widget

class AllReviewsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AllReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    // Ekran açılırken API'den yorumları çek
    _reviewsFuture = ApiService().getReviewsForUser(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName}'ın Değerlendirmeleri"),
      ),
      body: FutureBuilder<List<Review>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Yorumlar yüklenemedi.'));
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu kullanıcı henüz hiç değerlendirme almamış.'));
          }

          final reviews = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return ReviewCard(review: reviews[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 16),
          );
        },
      ),
    );
  }
}