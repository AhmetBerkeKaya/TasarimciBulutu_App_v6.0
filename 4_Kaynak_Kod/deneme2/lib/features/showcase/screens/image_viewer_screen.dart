// lib/features/showcase/screens/image_viewer_screen.dart

import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag; // Animasyon için

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: heroTag, // Karttan bu ekrana yumuşak geçiş animasyonu sağlar
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}