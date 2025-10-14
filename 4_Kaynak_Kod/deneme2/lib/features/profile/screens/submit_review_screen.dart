// lib/features/profile/screens/submit_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/project_provider.dart';
import '../../../data/models/review_model.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String projectId;
  final String revieweeId; // Değerlendirilecek kişinin ID'si
  final String revieweeName; // Değerlendirilecek kişinin adı

  const SubmitReviewScreen({
    super.key,
    required this.projectId,
    required this.revieweeId,
    required this.revieweeName,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  double _rating = 3.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final reviewData = ReviewCreate(
      projectId: widget.projectId,
      revieweeId: widget.revieweeId,
      rating: _rating.toInt(),
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
    );

    // --- DEĞİŞİKLİK: ApiService yerine Provider'ı kullan ---
    final success = await context.read<ProjectProvider>().submitReview(reviewData: reviewData);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Değerlendirmeniz için teşekkürler!' : 'Hata: Yorum gönderilemedi.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.revieweeName} Değerlendir'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Yorumunuz (İsteğe Bağlı)',
              hintText: 'İşbirliği hakkındaki düşüncelerinizi paylaşın...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                : const Text('DEĞERLENDİRMEYİ GÖNDER'),
          ),
        ],
      ),
    );
  }
}