// lib/features/auth/screens/login_screen.dart

import 'package:deneme2/features/auth/screens/home_screen.dart';
import 'package:deneme2/features/auth/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(authProvider.lastError ?? 'Giriş yapılamadı.')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444), // Modern Kırmızı
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    // --- MODERN RENK TANIMLARI ---
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    // Null safety hatasını önlemek için '!' ekledik veya sabit renk kullandık
    final secondaryText = isDark ? Colors.grey[400]! : const Color(0xFF64748B);

    // HATA VEREN KISIM DÜZELTİLDİ: [300] yerine sabit renk veya '!' kullanımı
    final Color inputLabelColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF334155);

    // Buton Gradiyeni (Monokrom Premium)
    final buttonGradient = isDark
        ? const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF020617)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final buttonShadow = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFF0F172A).withOpacity(0.3);

    return Scaffold(
      // Arka plan AppTheme'den geliyor (Ice Cloud: #F0F2F5)
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOGO & BAŞLIK ALANI
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/svgs/logo.svg',
                    // Logoyu temaya uygun renklendiriyoruz
                    colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : const Color(0xFF0F172A),
                        BlendMode.srcIn
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Hoş Geldiniz',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tasarımcı Bulutu hesabınıza giriş yapın',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 48),

              // 2. FORM ALANI
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Alanı
                    _buildInputLabel('E-POSTA ADRESİ', inputLabelColor),
                    const SizedBox(height: 8),
                    _buildModernInput(
                      controller: _emailController,
                      hint: 'ornek@email.com',
                      icon: Icons.alternate_email_rounded,
                      isDark: isDark,
                      inputType: TextInputType.emailAddress,
                      validator: (val) => (val == null || !val.contains('@')) ? 'Geçersiz e-posta' : null,
                    ),

                    const SizedBox(height: 24),

                    // Şifre Alanı
                    _buildInputLabel('ŞİFRE', inputLabelColor),
                    const SizedBox(height: 8),
                    _buildModernInput(
                      controller: _passwordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      validator: (val) => (val == null || val.length < 6) ? 'En az 6 karakter' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. AKSİYONLAR (Beni Hatırla / Şifremi Unuttum)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _rememberMe
                                  ? Colors.transparent
                                  : secondaryText,
                              width: 2,
                            ),
                          ),
                          child: _rememberMe
                              ? Icon(
                              Icons.check,
                              size: 16,
                              color: isDark ? Colors.black : Colors.white
                          )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Beni Hatırla',
                            style: TextStyle(
                                color: secondaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 13
                            )
                        ),
                      ],
                    ),
                  ),

                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryText,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Şifremi Unuttum?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 4. GİRİŞ BUTONU (HERO)
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: buttonShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: authProvider.isLoading
                      ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: isDark ? Colors.black : Colors.white,
                          strokeWidth: 2.5
                      )
                  )
                      : Text(
                    'GİRİŞ YAP',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 5. FOOTER (Kayıt Ol)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'Hesabınız yok mu?',
                      style: TextStyle(color: secondaryText, fontWeight: FontWeight.w500)
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    ),
                    child: Text(
                        'Hemen Kayıt Ol',
                        style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.w800
                        )
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // YARDIMCI WIDGETLAR
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
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[400]),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.grey[400],
            ),
            onPressed: onVisibilityToggle,
          )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                width: 1.5
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