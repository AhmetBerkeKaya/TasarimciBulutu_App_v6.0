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
    // Klavye açıksa kapat
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestPasswordReset(_emailController.text);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta adresiniz kayıtlıysa, sıfırlama kodu gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
        // Başarılı olunca yeni şifre belirleme ekranına yönlendir
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ResetPasswordScreen(email: _emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.lastError ?? 'Bir hata oluştu, lütfen tekrar deneyin.'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    final authProvider = context.watch<AuthProvider>();

    final buttonContent = authProvider.isLoading
        ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
    )
        : const Text(
      'KOD GÖNDER',
      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- İKON VE BAŞLIK ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: theme.primaryColor
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                    'Şifrenizi mi unuttunuz?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold
                    )
                ),
                const SizedBox(height: 12),

                Text(
                  'Endişelenmeyin! Kayıtlı e-posta adresinizi girin, size şifre sıfırlama kodunu gönderelim.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5
                  ),
                ),
                const SizedBox(height: 40),

                // --- INPUT ---
                TextFormField(
                  controller: _emailController,
                  // AppTheme inputDecorationTheme kullandığı için burayı sade tutuyoruz
                  decoration: const InputDecoration(
                    labelText: 'E-Posta',
                    hintText: 'ornek@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty || !value.contains('@')) {
                      return 'Lütfen geçerli bir e-posta girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // --- BUTON ---
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: buttonContent,
                ),

                const SizedBox(height: 24),

                // --- GERİ DÖN ---
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Giriş Sayfasına Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}