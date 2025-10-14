// lib/features/auth/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';
import '../widgets/user_type_selector.dart';

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
          const SnackBar(
            content: Text('Lütfen geçerli bir telefon numarası girin.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Role göre doğru ismi alıyoruz.
      final String nameForApi = _selectedRole == UserRole.freelancer
          ? '${_nameController.text} ${_surnameController.text}'
          : _companyNameController.text;

      final success = await authProvider.signup(
        name: nameForApi,
        email: _emailController.text,
        phoneNumber: _fullPhoneNumber, // Widget'tan gelen tam numarayı kullan
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Lütfen giriş yapın.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt oluşturulamadı. E-posta zaten kullanımda olabilir.'),
            backgroundColor: Colors.red,
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
    _phoneController.dispose(); // <-- dispose etmeyi unutma
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isFreelancer = _selectedRole == UserRole.freelancer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kullanıcı Tipini Seçin',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  UserTypeSelectorCard(
                    title: 'Freelancer',
                    subtitle: 'Tasarımcı, Mühendis',
                    icon: Icons.person_outline,
                    isSelected: isFreelancer,
                    onTap: () => setState(() => _selectedRole = UserRole.freelancer),
                  ),
                  const SizedBox(width: 16),
                  UserTypeSelectorCard(
                    title: 'Firma',
                    subtitle: 'İşveren, Firma',
                    icon: Icons.business_outlined,
                    isSelected: !isFreelancer,
                    onTap: () => setState(() => _selectedRole = UserRole.client),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- Sadeleştirilmiş Form Alanları ---
              if (isFreelancer)
              // Eğer Freelancer seçiliyse Ad/Soyad göster
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ad', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(hintText: "Adınız"),
                            validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Soyad', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _surnameController,
                            decoration: const InputDecoration(hintText: "Soyadınız"),
                            validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
              // Eğer Firma seçiliyse sadece Firma Adı göster
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Firma Adı', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(hintText: "Firma Adı"),
                      validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz' : null,
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              Text('E-Posta', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: "E-posta adresiniz"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
              ),

              const SizedBox(height: 16),
              Text('Telefon Numarası', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              IntlPhoneField(
                decoration: const InputDecoration(
                  hintText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'TR', // Varsayılan Türkiye
                onChanged: (phone) {
                  // Numara her değiştiğinde tam numarayı (+90...) state'e kaydet
                  _fullPhoneNumber = phone.completeNumber;
                },
              ),

              const SizedBox(height: 16),
              Text('Şifre', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Şifre oluşturun",
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Şifre en az 6 karakter olmalı' : null,
              ),

              const SizedBox(height: 16),
              Text('Şifreyi Onayla', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Şifrenizi tekrar girin",
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                validator: (v) => (v != _passwordController.text) ? 'Şifreler eşleşmiyor' : null,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: authProvider.isLoading ? null : _signup,
                child: authProvider.isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('KAYIT OL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
