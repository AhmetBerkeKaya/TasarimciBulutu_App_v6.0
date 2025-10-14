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
  final _formKey = GlobalKey<FormState>(); // Formu doğrulamak için key

  // _isLoading durumunu AuthProvider'dan alacağız
  // bool _isLoading = false;

  void _sendResetLink() async {
    // Formu doğrula
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // isLoading durumunu provider'dan izliyoruz
    final authProvider = context.watch<AuthProvider>();

    final buttonContent = authProvider.isLoading
        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Text(
      'GÖNDER',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form( // Form widget'ı ile sarmalıyoruz
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 80, color: theme.colorScheme.secondary),
                const SizedBox(height: 24),
                Text('Şifremi Unuttum', textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                const SizedBox(height: 16),
                Text(
                  'Şifrenizi sıfırlamak için kayıtlı e-posta adresinizi girin. Size 6 haneli bir sıfırlama kodu göndereceğiz.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'E-posta adresinizi girin', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty || !value.contains('@')) {
                      return 'Lütfen geçerli bir e-posta girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: buttonContent,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Giriş Sayfasına Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
