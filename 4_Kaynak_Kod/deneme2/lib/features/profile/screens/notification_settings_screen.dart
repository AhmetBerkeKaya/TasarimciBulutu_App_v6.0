import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Bu değerler şimdilik yerel (local) tutuluyor.
  // Faz 5'te bunları Backend'e kaydedeceğiz.
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _marketingEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Anlık Bildirimler'),
            subtitle: const Text('Uygulama içi ve push bildirimleri al'),
            value: _pushEnabled,
            onChanged: (val) => setState(() => _pushEnabled = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('E-posta Bildirimleri'),
            subtitle: const Text('Önemli güncellemeleri e-posta ile al'),
            value: _emailEnabled,
            onChanged: (val) => setState(() => _emailEnabled = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Pazarlama ve Duyurular'),
            subtitle: const Text('Kampanyalardan haberdar ol'),
            value: _marketingEnabled,
            onChanged: (val) => setState(() => _marketingEnabled = val),
          ),
        ],
      ),
    );
  }
}