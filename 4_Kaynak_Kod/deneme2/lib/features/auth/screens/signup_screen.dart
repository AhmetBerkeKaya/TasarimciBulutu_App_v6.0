// lib/features/auth/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';
// import '../widgets/user_type_selector.dart'; // Bunu kullanmıyoruz, sayfa içine modern halini gömdük.

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.freelancer;

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _fullPhoneNumber = '';

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_fullPhoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.warning_amber, color: Colors.white), SizedBox(width: 8), Text('Geçerli bir telefon numarası girin.')]),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final String nameForApi = _selectedRole == UserRole.freelancer
          ? '${_nameController.text} ${_surnameController.text}'
          : _companyNameController.text;

      final success = await authProvider.signup(
        name: nameForApi,
        email: _emailController.text,
        phoneNumber: _fullPhoneNumber,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Kayıt başarılı! Lütfen giriş yapın.')]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 8), Text('Kayıt başarısız. E-posta kullanımda olabilir.')]),
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
    _nameController.dispose();
    _surnameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final bool isFreelancer = _selectedRole == UserRole.freelancer;

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
      // Arkaplan rengi (Ice Cloud)
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
        centerTitle: true,
        title: Text(
          'Hesap Oluştur',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: primaryText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kullanıcı Tipini Seçin',
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // --- MODERN KULLANICI SEÇİCİ ---
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelectorItem(
                        title: 'Freelancer',
                        icon: Icons.person_outline_rounded,
                        isSelected: isFreelancer,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedRole = UserRole.freelancer),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildRoleSelectorItem(
                        title: 'Firma',
                        icon: Icons.business_rounded,
                        isSelected: !isFreelancer,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedRole = UserRole.client),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- FORM ALANLARI ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isFreelancer
                    ? Row(
                  key: const ValueKey('freelancer_name_row'),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('AD', inputLabelColor),
                          const SizedBox(height: 8),
                          _buildModernInput(
                            controller: _nameController,
                            hint: 'Adınız',
                            isDark: isDark,
                            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('SOYAD', inputLabelColor),
                          const SizedBox(height: 8),
                          _buildModernInput(
                            controller: _surnameController,
                            hint: 'Soyadınız',
                            isDark: isDark,
                            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                    : Column(
                  key: const ValueKey('company_name_col'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('FİRMA ADI', inputLabelColor),
                    const SizedBox(height: 8),
                    _buildModernInput(
                      controller: _companyNameController,
                      hint: 'Şirketinizin tam adı',
                      icon: Icons.domain_rounded,
                      isDark: isDark,
                      validator: (v) => v!.isEmpty ? 'Firma adı gereklidir' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildInputLabel('E-POSTA ADRESİ', inputLabelColor),
              const SizedBox(height: 8),
              _buildModernInput(
                controller: _emailController,
                hint: 'ornek@email.com',
                icon: Icons.alternate_email_rounded,
                isDark: isDark,
                inputType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
              ),

              const SizedBox(height: 20),
              _buildInputLabel('TELEFON NUMARASI', inputLabelColor),
              const SizedBox(height: 8),
              // --- TELEFON ALANI (Özel Tasarım) ---
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: '5XX XXX XX XX',
                    hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white : const Color(0xFF0F172A), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    counterText: '', // Karakter sayacını gizle
                  ),
                  style: TextStyle(fontWeight: FontWeight.w600, color: primaryText),
                  initialCountryCode: 'TR',
                  dropdownIcon: Icon(Icons.keyboard_arrow_down_rounded, color: secondaryText),
                  dropdownTextStyle: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),
              ),

              const SizedBox(height: 20),
              _buildInputLabel('ŞİFRE', inputLabelColor),
              const SizedBox(height: 8),
              _buildModernInput(
                controller: _passwordController,
                hint: 'En az 6 karakter',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: (v) => (v == null || v.length < 6) ? 'Şifre en az 6 karakter olmalı' : null,
              ),

              const SizedBox(height: 20),
              _buildInputLabel('ŞİFREYİ ONAYLA', inputLabelColor),
              const SizedBox(height: 8),
              _buildModernInput(
                controller: _confirmPasswordController,
                hint: 'Şifrenizi tekrar girin',
                icon: Icons.lock_reset_rounded,
                isDark: isDark,
                isPassword: true,
                isVisible: _isConfirmPasswordVisible,
                onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                validator: (v) => (v != _passwordController.text) ? 'Şifreler eşleşmiyor' : null,
              ),

              const SizedBox(height: 40),

              // --- KAYIT OL BUTONU (MONOKROM GRADIENT) ---
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
                  onPressed: authProvider.isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: authProvider.isLoading
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: buttonTextColor, strokeWidth: 2.5),
                  )
                      : Text(
                    'KAYIT OL',
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
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: secondaryText, fontFamily: 'Manrope'),
                      children: [
                        const TextSpan(text: 'Zaten hesabınız var mı? '),
                        TextSpan(
                          text: 'Giriş Yap',
                          style: TextStyle(color: primaryText, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI METOTLAR ---

  Widget _buildRoleSelectorItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.grey : Colors.grey[600]),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.grey : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    required bool isDark,
    IconData? icon,
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
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