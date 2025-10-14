// lib/common_widgets/project_card_skeleton.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProjectCardSkeleton extends StatelessWidget {
  final bool isHorizontal; // <-- YENİ ÖZELLİK

  const ProjectCardSkeleton({super.key, this.isHorizontal = false}); // <-- CONSTRUCTOR GÜNCELLENDİ

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;

    Widget skeletonContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Container(
          width: double.infinity,
          height: 20.0,
          color: Colors.white,
        ),
        const SizedBox(height: 8.0),
        // Owner name
        Container(
          width: 120.0,
          height: 16.0,
          color: Colors.white,
        ),
        const SizedBox(height: 16.0),
        // Description line 1
        Container(
          width: double.infinity,
          height: 14.0,
          color: Colors.white,
        ),
        const SizedBox(height: 6.0),
        // Description line 2
        Container(
          width: double.infinity,
          height: 14.0,
          color: Colors.white,
        ),
        const SizedBox(height: 6.0),
        // Description line 3
        Container(
          width: 180.0,
          height: 14.0,
          color: Colors.white,
        ),
        const Spacer(),
        // Budget
        Container(
          width: 150.0,
          height: 18.0,
          color: Colors.white,
        ),
      ],
    );

    // Ana widget'ı isHorizontal değerine göre ayarla
    Widget finalWidget = Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            // isHorizontal değilse Expanded kullan, aksi halde SizedBox
            child: isHorizontal ? SizedBox(height: 180, child: skeletonContent) : AspectRatio(aspectRatio: 16/9, child: skeletonContent)
        ),
      ),
    );

    // Eğer yatay ise, genişliğini ayarla
    if (isHorizontal) {
      return SizedBox(
        width: 280,
        child: finalWidget,
      );
    }

    return finalWidget;
  }
}