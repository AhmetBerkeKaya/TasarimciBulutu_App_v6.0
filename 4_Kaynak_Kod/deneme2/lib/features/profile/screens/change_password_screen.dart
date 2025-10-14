// lib/features/profile/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Haptic feedback for better UX
      HapticFeedback.lightImpact();

      final token = Provider.of<AuthProvider>(context, listen: false).token;

      final success = await ApiService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      // Show modern snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Şifreniz başarıyla güncellendi!'
                      : 'İşlem başarısız! Mevcut şifrenizi kontrol edin.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      if (success) {
        // Add a small delay for better UX
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            prefixIcon,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
              size: 22,
            ),
            onPressed: onToggleVisibility,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE53E3E),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE53E3E),
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFE53E3E),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Şifre Değiştir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.security,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Güvenliğiniz İçin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Şifrenizi düzenli olarak değiştirerek hesabınızı güvende tutun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Current Password Field
                  Text(
                    'Mevcut Şifre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Mevcut Şifre',
                    hint: 'Şu anki şifrenizi girin',
                    obscureText: !_showCurrentPassword,
                    onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                    validator: (v) => v!.isEmpty ? 'Lütfen mevcut şifrenizi girin.' : null,
                    prefixIcon: Icons.lock_outline,
                  ),

                  const SizedBox(height: 24),

                  // New Password Field
                  Text(
                    'Yeni Şifre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'Yeni Şifre',
                    hint: 'En az 6 karakter',
                    obscureText: !_showNewPassword,
                    onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                    validator: (v) => (v == null || v.length < 6) ? 'Yeni şifre en az 6 karakter olmalı.' : null,
                    prefixIcon: Icons.lock_reset,
                  ),

                  const SizedBox(height: 24),

                  // Confirm Password Field
                  Text(
                    'Şifre Tekrarı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Yeni Şifre (Tekrar)',
                    hint: 'Yeni şifrenizi tekrar girin',
                    obscureText: !_showConfirmPassword,
                    onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    validator: (v) => v != _newPasswordController.text ? 'Şifreler eşleşmiyor.' : null,
                    prefixIcon: Icons.verified_user,
                  ),

                  const SizedBox(height: 40),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ).copyWith(
                        elevation: MaterialStateProperty.resolveWith<double>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) return 8;
                            if (states.contains(MaterialState.hovered)) return 4;
                            return 2;
                          },
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Güncelleniyor...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                          : const Text(
                        'Şifreyi Güncelle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Tips
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Güvenlik İpucu',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Güçlü bir şifre için büyük-küçük harf, rakam ve özel karakter kullanın.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}