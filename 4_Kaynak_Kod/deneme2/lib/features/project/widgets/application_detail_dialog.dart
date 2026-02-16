// lib/features/project/widgets/application_detail_dialog.dart

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
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    // Modern Renkler
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F7FA);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: bgColor,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. BAŞLIK & PROFİL ---
              Row(
                children: [
                  // Avatar (İsim baş harfi)
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Text(
                      application.freelancer.name.isNotEmpty ? application.freelancer.name[0].toUpperCase() : 'U',
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // İsim ve Profil Linki
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.freelancer.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ProfileScreen(userId: application.freelancer.id),
                            ));
                          },
                          child: Row(
                            children: [
                              Text('Profili Görüntüle', style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: theme.primaryColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- 2. TEKLİF EDİLEN BÜTÇE KARTI ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Teklif Edilen Bütçe',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(application.proposedBudget ?? 0),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.primaryColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. ÖN YAZI ---
              Text("Ön Yazı", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 200), // Çok uzunsa scroll olsun
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    application.coverLetter?.isNotEmpty == true ? application.coverLetter! : 'Ön yazı eklenmemiş.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: textColor.withOpacity(0.9)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- 4. AKSİYON BUTONLARI ---

              // Mesaj Gönder (İkincil Aksiyon)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSendMessage();
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text("Mesaj Gönder"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 12),

              // Reddet / Kabul Et (Ana Aksiyonlar)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onReject();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text("Reddet"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAccept();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text("Kabul Et"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        shadowColor: Colors.green.withOpacity(0.4),
                      ),
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
}