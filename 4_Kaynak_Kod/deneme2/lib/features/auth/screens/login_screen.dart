// lib/features/auth/screens/login_screen.dart

import 'package:deneme2/features/auth/screens/home_screen.dart';
import 'package:deneme2/features/auth/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart'; // Temayı import ettik
import '../widgets/social_login_button.dart'; // Varsa kullanılır
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

    if (mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.lastError ?? 'E-posta veya şifre hatalı!'),
            backgroundColor: Theme.of(context).colorScheme.error, // Temadan hata rengi
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // AppTheme'deki merkezi gradienti kullanıyoruz
    final primaryGradient = isDarkMode
        ? AppTheme.darkPrimaryGradient
        : AppTheme.lightPrimaryGradient;

    final buttonContent = authProvider.isLoading
        ? const SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    )
        : Text(
      'GİRİŞ YAP',
      // Fontu temadan alıp, rengini beyaz yapıyoruz (buton üzeri olduğu için)
      style: theme.textTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 16,
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
                // --- LOGO ALANI ---
                Center(
                  child: Container(
                    width: 140, // Biraz daha kompakt yaptım (160 -> 140)
                    height: 140,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: primaryGradient, // Merkezi gradient
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/svgs/logo.svg',
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- BAŞLIKLAR ---
                Text(
                    'TasarımcıBulutu',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground
                    )
                ),
                const SizedBox(height: 8),
                Text(
                  'Türkiye’nin Tasarım Platformu',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 48),

                // --- FORM ---
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-Posta', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        // Stil AppTheme'den otomatik geliyor
                        decoration: const InputDecoration(
                          hintText: 'ornek@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || value.trim().isEmpty || !value.contains('@')) ? 'Geçerli bir e-posta girin.' : null,
                      ),
                      const SizedBox(height: 20),
                      Text('Şifre', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        // Stil AppTheme'den otomatik geliyor
                        decoration: InputDecoration(
                          hintText: '••••••••',
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

                const SizedBox(height: 12),

                // --- ALT AKSİYONLAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Beni Hatırla', style: theme.textTheme.bodyMedium),
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
                const SizedBox(height: 32),

                // --- GİRİŞ BUTONU ---
                InkWell(
                  onTap: authProvider.isLoading ? null : _login,
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(12.0), // Biraz daha yumuşak köşe
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(child: buttonContent),
                  ),
                ),

                const SizedBox(height: 32),

                // --- KAYIT OL ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hesabınız yok mu?', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      ),
                      child: const Text('Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold)),
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