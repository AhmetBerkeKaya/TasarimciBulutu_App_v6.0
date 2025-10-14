// lib/features/auth/screens/login_screen.dart

import 'package:deneme2/features/auth/screens/home_screen.dart'; // HomeScreen'i import et
import 'package:deneme2/features/auth/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../widgets/social_login_button.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // --- DEĞİŞİKLİK BURADA ---
    if (mounted) { // Widget'ın hala ekranda olduğundan emin ol
      if (success) {
        // BAŞARILI DURUM: Giriş başarılı olduğunda, AuthWrapper'ı beklemeden
        // proaktif olarak HomeScreen'e yönlendir. Bu, "takılma" bug'ını çözer.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false, // Tüm geçmişi temizle
        );
      } else {
        // BAŞARISIZ DURUM: Hata mesajı göster.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.lastError ?? 'E-posta veya şifre hatalı!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // --- DEĞİŞİMİN SONU ---
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // build metodunun geri kalanı tamamen aynı kalacak...
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryGradient = LinearGradient(
      colors: [
        theme.primaryColor.withOpacity(0.9),
        theme.primaryColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final buttonContent = authProvider.isLoading
        ? const SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    )
        : const Text(
      'GİRİŞ YAP',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/svgs/logo.svg',
                  ),
                ),
                const SizedBox(height: 24),
                Text('TasarımcıBulutu', textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Türkiye’nin Tasarım Platformu',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-Posta', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'E-posta adresinizi girin',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || value.trim().isEmpty || !value.contains('@')) ? 'Geçerli bir e-posta girin.' : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Şifre', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Şifrenizi girin',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (value) => (value == null || value.length < 6) ? 'Şifre en az 6 karakter olmalı.' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        ),
                        const Text('Beni Hatırla'),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      ),
                      child: const Text('Şifremi Unuttum'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: authProvider.isLoading ? null : _login,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(child: buttonContent),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('veya', style: TextStyle(color: theme.colorScheme.secondary)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                SocialLoginButton(
                  text: 'Google ile Giriş',
                  icon: Icon(
                    Icons.g_mobiledata_rounded,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                SocialLoginButton(
                  text: 'Apple ile Giriş',
                  icon: Icon(
                    Icons.apple,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hesabınız yok mu?'),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      ),
                      child: const Text('Kayıt Ol'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
