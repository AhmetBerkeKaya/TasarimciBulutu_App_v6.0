// lib/features/auth/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.resetPassword(
      token: _codeController.text,
      newPassword: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Şifreniz başarıyla yenilendi!')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Başarılı olunca giriş ekranına yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(authProvider.lastError ?? 'Bir hata oluştu.')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: 24,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon with gradient background
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title
                          Text(
                            'Yeni Şifre Oluştur',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtitle with better formatting
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.email,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'adresine gönderilen 6 haneli kodu ve yeni şifrenizi girin.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Kod alanı - Modern design
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'Sıfırlama Kodu',
                                hintText: '123456',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.pin_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: (value) {
                                if (value == null || value.length != 6) {
                                  return 'Lütfen 6 haneli kodu girin.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Yeni şifre alanı - Modern design
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Yeni Şifre',
                                hintText: 'Güçlü bir şifre oluşturun',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    color: theme.colorScheme.secondary,
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalıdır.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Modern gradient button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: authProvider.isLoading
                                  ? null
                                  : LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: authProvider.isLoading
                                  ? null
                                  : [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _submitResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: authProvider.isLoading
                                    ? theme.disabledColor
                                    : Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'İşleniyor...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                                  : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_reset_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'ŞİFREYİ SIFIRLA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Help text
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Kodu alamadınız mı? Spam klasörünü kontrol edin',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}