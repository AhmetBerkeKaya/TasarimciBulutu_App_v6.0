// lib/features/profile/screens/settings_screen.dart (HATA DÜZELTİLDİ)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/theme_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Gri metin stili (Trailing text için)
    final trailingStyle = theme.textTheme.bodyMedium?.copyWith(color: Colors.grey);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _SettingsSection(
            title: 'Hesap Yönetimi',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Profili Düzenle',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen())),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Şifre Değiştir',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChangePasswordScreen())),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SettingsSection(
            title: 'Uygulama Ayarları',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.palette_outlined,
                title: 'Görünüm',
                // --- DÜZELTME BURADA: String yerine Widget (Text) döndürüyoruz ---
                trailing: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      String text;
                      switch (themeProvider.themeMode) {
                        case ThemeMode.light: text = 'Açık'; break;
                        case ThemeMode.dark: text = 'Koyu'; break;
                        default: text = 'Sistem'; break;
                      }
                      // String değil, Text Widget döndürüyoruz
                      return Text(text, style: trailingStyle);
                    }
                ),
                // ----------------------------------------------------------------
                onTap: () => _showThemeDialog(context),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SettingsSection(
            title: 'Destek ve Yasal',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Yardım Merkezi & SSS',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpCenterScreen())),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.description_outlined,
                title: 'Kullanım Koşulları',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TermsOfServiceScreen())),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
              ),
            ],
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // --- DÜZELTİLEN YARDIMCI WIDGET ---
  // String? trailingText yerine Widget? trailing alıyor
  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing, // <-- DEĞİŞİKLİK: Artık Widget alıyor
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 22),
      ),
      title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            trailing, // Widget'ı direkt koyuyoruz
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
  // -----------------------------------

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tema Seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildRadioTile(context, 'Açık Tema', ThemeMode.light, themeProvider),
              _buildRadioTile(context, 'Koyu Tema', ThemeMode.dark, themeProvider),
              _buildRadioTile(context, 'Sistem Varsayılanı', ThemeMode.system, themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioTile(BuildContext context, String title, ThemeMode mode, ThemeProvider provider) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: mode,
      groupValue: provider.themeMode,
      activeColor: Theme.of(context).primaryColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (ThemeMode? value) {
        if (value != null) provider.setThemeMode(value);
        Navigator.of(context).pop();
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}