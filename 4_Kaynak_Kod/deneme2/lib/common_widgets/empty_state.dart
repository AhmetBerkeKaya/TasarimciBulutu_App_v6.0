// lib/common_widgets/empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? suggestion;
  final Widget? actionButton; // <-- YENİ

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.suggestion,
    this.actionButton, // <-- YENİ

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 8),
              Text(
                suggestion!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton!,
            ]
          ],
        ),
      ),
    );
  }
}