// lib/features/auth/widgets/social_login_button.dart
import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}