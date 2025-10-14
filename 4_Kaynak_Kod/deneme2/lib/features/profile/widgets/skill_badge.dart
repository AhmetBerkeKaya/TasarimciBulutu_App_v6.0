import 'package:flutter/material.dart';

class SkillBadge extends StatelessWidget {
  final String softwareName;

  const SkillBadge({super.key, required this.softwareName});

  IconData _getIconForSoftware() {
    // Bu ikonları projenin temasına uygun daha spesifik ikonlarla değiştirebilirsin
    switch (softwareName.toLowerCase()) {
      case 'autocad':
        return Icons.architecture_outlined;
      case 'revit':
        return Icons.business_outlined;
      case 'solidworks':
        return Icons.settings_input_component_outlined;
      default:
        return Icons.verified_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // Şık bir gradyan arka plan
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForSoftware(),
            color: theme.colorScheme.onPrimary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            softwareName,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}