// =======================================================================
// DOSYA 1: lib/features/profile/screens/settings_screen.dart (Nihai Hali)
// AÇIKLAMA: Yeni yasal sayfalara yönlendirmeler eklenmiş ayarlar ekranı.
// =======================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/theme_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart'; // <-- Yeni ekran importu
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart'; // <-- Yeni ekran importu
import 'terms_of_service_screen.dart'; // <-- Yeni ekran importu

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SettingsCard(
            title: 'Hesap Yönetimi',
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profili Düzenle'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Şifre Değiştir'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'Uygulama Ayarları',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Görünüm'),
                subtitle: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      String currentTheme;
                      switch (themeProvider.themeMode) {
                        case ThemeMode.light: currentTheme = 'Açık Tema'; break;
                        case ThemeMode.dark: currentTheme = 'Koyu Tema'; break;
                        default: currentTheme = 'Sistem Varsayılanı'; break;
                      }
                      return Text(currentTheme);
                    }
                ),
                onTap: () => _showThemeDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Bildirimler'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'Destek ve Yasal Bilgilendirme',
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Yardım Merkezi & SSS'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Kullanım Koşulları'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik Politikası'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tema Seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<ThemeMode>(
                title: const Text('Açık Tema'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Koyu Tema'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Sistem Varsayılanı'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Ayarlar ekranındaki grupları oluşturan, yeniden kullanılabilir kart widget'ı
class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
