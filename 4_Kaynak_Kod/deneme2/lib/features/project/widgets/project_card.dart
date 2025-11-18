// lib/features/project/widgets/project_card.dart (KOMPAKT VE AKSİYON ODAKLI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../common_widgets/status_chip.dart';
import '../../../data/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final Widget? actionButton;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final isDark = theme.brightness == Brightness.dark;

    String budgetText;
    if (project.budgetMin != null && project.budgetMax != null) {
      if (project.budgetMin == project.budgetMax) {
        budgetText = currencyFormat.format(project.budgetMin);
      } else {
        budgetText =
        '${currencyFormat.format(project.budgetMin)} - ${currencyFormat.format(project.budgetMax)}';
      }
    } else {
      budgetText = 'Teklife Açık';
    }

    // Yetenekleri özetlemek için metin oluştur
    // Örn: "AutoCAD, Revit +3 diğer"
    String skillsSummary = "";
    if (project.requiredSkills.isNotEmpty) {
      final firstTwo = project.requiredSkills.take(2).map((s) => s.name).join(", ");
      final remainingCount = project.requiredSkills.length - 2;
      if (remainingCount > 0) {
        skillsSummary = "$firstTwo +$remainingCount diğer";
      } else {
        skillsSummary = firstTwo;
      }
    }

    return Card(
      elevation: isDark ? 0 : 2, // Daha az gölge, daha modern
      shadowColor: Colors.black.withOpacity(0.05),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12.0), // Margin azaltıldı
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding azaltıldı
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ÜST KISIM: Başlık ve Durum ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.owner.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: project.status), // StatusChip'e small parametresi eklenebilir veya varsayılan kalsın
                ],
              ),

              const SizedBox(height: 12),

              // --- ORTA KISIM: Bütçe ve Kategori (Yan Yana) ---
              Row(
                children: [
                  _CompactInfoChip(
                    icon: Icons.account_balance_wallet_outlined,
                    text: budgetText,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _CompactInfoChip(
                    icon: Icons.category_outlined,
                    text: project.category,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),

              // --- ALT KISIM: Yetenek Özeti (Varsa) ---
              if (skillsSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.code, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        skillsSummary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Zaman bilgisi en sağa
                    Text(
                      timeago.format(project.createdAt, locale: 'tr'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],

              // --- AKSİYON BUTONU (Varsa Göster) ---
              if (actionButton != null) ...[
                const Divider(height: 24), // Çizgi ile ayır
                SizedBox(
                  width: double.infinity,
                  child: actionButton,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- KOMPAKT BİLGİ ETİKETİ ---
class _CompactInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CompactInfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}