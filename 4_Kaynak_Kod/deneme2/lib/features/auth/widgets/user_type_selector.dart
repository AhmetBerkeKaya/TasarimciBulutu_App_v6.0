// lib/features/auth/widgets/user_type_selector.dart
import 'package:flutter/material.dart';

class UserTypeSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const UserTypeSelectorCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, size: 32, color: isSelected ? theme.primaryColor : theme.colorScheme.secondary),
                const SizedBox(height: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}