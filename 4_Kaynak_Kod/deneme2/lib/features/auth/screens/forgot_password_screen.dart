// lib/features/auth/screens/forgot_password_screen.dart

import 'package:deneme2/features/auth/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _sendResetLink() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestPasswordReset(_emailController.text);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.mark_email_read_rounded, color: Colors.white), SizedBox(width: 8), Expanded(child: Text('Sıfırlama kodu gönderildi.'))]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ResetPasswordScreen(email: _emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(authProvider.lastError ?? 'Bir hata oluştu.'))]),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    // --- RENK PALETİ ---
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
    final inputLabelColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF334155);

    // Buton Gradiyeni
    final buttonGradient = isDark
        ? const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)])
        : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF020617)]);

    final buttonTextColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: primaryText),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- İKON ALANI ---
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                        Icons.lock_open_rounded,
                        size: 56,
                        color: isDark ? Colors.white : const Color(0xFF0F172A)
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                    'Şifrenizi mi unuttunuz?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                        letterSpacing: -0.5
                    )
                ),
                const SizedBox(height: 12),

                Text(
                  'Endişelenmeyin! Kayıtlı e-posta adresinizi girin,\nsize şifre sıfırlama kodunu gönderelim.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: secondaryText,
                      height: 1.5,
                      fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 48),

                // --- E-POSTA INPUT ---
                _buildInputLabel('E-POSTA ADRESİ', inputLabelColor),
                const SizedBox(height: 8),
                _buildModernInput(
                  controller: _emailController,
                  hint: 'ornek@email.com',
                  icon: Icons.alternate_email_rounded,
                  isDark: isDark,
                  inputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty || !value.contains('@')) {
                      return 'Geçerli bir e-posta girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // --- GÖNDER BUTONU ---
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF0F172A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authProvider.isLoading
                        ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: buttonTextColor, strokeWidth: 2.5)
                    )
                        : Text(
                      'KOD GÖNDER',
                      style: TextStyle(
                        color: buttonTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- GERİ DÖN ---
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: secondaryText, fontFamily: 'Manrope'),
                      children: [
                        const TextSpan(text: 'Hatırladınız mı? '),
                        TextSpan(
                          text: 'Giriş Yap',
                          style: TextStyle(color: primaryText, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI METOTLAR ---
  Widget _buildInputLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
      ),
    );
  }
}