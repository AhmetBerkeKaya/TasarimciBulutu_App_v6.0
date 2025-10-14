import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../../data/models/review_model.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMMM yyyy', 'tr_TR');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.reviewer.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.reviewer.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('"${review.project.title}" projesi için', style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(formatter.format(review.createdAt), style: theme.textTheme.bodySmall),
              ],
            ),
            const Divider(height: 24),
            RatingBarIndicator(
              rating: review.rating.toDouble(),
              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20.0,
            ),
            const SizedBox(height: 12),
            if (review.comment != null && review.comment!.isNotEmpty)
              Text(
                '"${review.comment!}"',
                style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.black87),
              ),
          ],
        ),
      ),
    );
  }
}