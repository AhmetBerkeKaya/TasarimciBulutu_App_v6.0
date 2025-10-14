import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/application_model.dart';
import '../../profile/screens/profile_screen.dart';

class ApplicationDetailDialog extends StatelessWidget {
  final Application application;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onSendMessage;

  const ApplicationDetailDialog({
    super.key,
    required this.application,
    required this.onAccept,
    required this.onReject,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.all(0),
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Başvuranın ismi
            Expanded(child: Text(application.freelancer.name, style: theme.textTheme.titleLarge)),
            // Profilini gör butonu
            TextButton(
              child: const Text('Profili Gör'),
              onPressed: () {
                Navigator.of(context).pop(); // Önce diyaloğu kapat
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: application.freelancer.id),
                ));
              },
            )
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Divider(),
            const SizedBox(height: 16),
            Text('Teklif Edilen Bütçe', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(application.proposedBudget ?? 0),
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text('Ön Yazı', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 8),
            Text(
              application.coverLetter?.isNotEmpty ?? false ? application.coverLetter! : 'Ön yazı eklenmemiş.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
      // --- BUTONLARI DÜZENLEYEN KISIM ---
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      actions: <Widget>[
        Row(
          children: [
            // Reddet Butonu
            IconButton(
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 28),
              onPressed: () {
                Navigator.of(context).pop();
                onReject();
              },
            ),
            // Kabul Et Butonu
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.green, size: 28),
              onPressed: () {
                Navigator.of(context).pop();
                onAccept();
              },
            ),
            const SizedBox(width: 8),
            // Mesaj Gönder Butonu
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message_outlined, size: 18),
                label: const Text('Mesaj Gönder'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onSendMessage();
                },
              ),
            ),
          ],
        )
      ],
      // --- BİTTİ ---
    );
  }
}