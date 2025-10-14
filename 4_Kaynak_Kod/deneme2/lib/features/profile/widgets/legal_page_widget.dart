import 'package:flutter/material.dart';

class LegalSectionData {
  final String title;
  final String content;
  final bool isLast;

  const LegalSectionData({
    required this.title,
    required this.content,
    this.isLast = false,
  });
}

class LegalPageView extends StatelessWidget {
  final String pageTitle;
  final List<LegalSectionData> sections;

  const LegalPageView({
    super.key,
    required this.pageTitle,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pageTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Son Güncelleme: 3 Ağustos 2025', // Tarihi dinamik yapabilirsin
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ...sections.map((section) => _buildSection(context, section)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, LegalSectionData section) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          section.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: Colors.grey[800],
          ),
        ),
        if (!section.isLast) const SizedBox(height: 28),
      ],
    );
  }
}