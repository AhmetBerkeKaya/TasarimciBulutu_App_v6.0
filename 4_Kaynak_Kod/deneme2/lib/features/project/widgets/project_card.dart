// lib/features/project/widgets/project_card.dart

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
    final isDark = theme.brightness == Brightness.dark;

    // Para birimi formatı
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    // Bütçe Metni Oluşturma
    String budgetText;
    if (project.budgetMin != null && project.budgetMax != null) {
      if (project.budgetMin == project.budgetMax) {
        budgetText = currencyFormat.format(project.budgetMin);
      } else {
        budgetText = '${currencyFormat.format(project.budgetMin)} - ${currencyFormat.format(project.budgetMax)}';
      }
    } else {
      budgetText = 'Teklife Açık';
    }

    // Yetenek Özeti Oluşturma
    String skillsSummary = "";
    if (project.requiredSkills.isNotEmpty) {
      final firstTwo = project.requiredSkills.take(2).map((s) => s.name).join(", ");
      final remainingCount = project.requiredSkills.length - 2;
      if (remainingCount > 0) {
        skillsSummary = "$firstTwo +$remainingCount";
      } else {
        skillsSummary = firstTwo;
      }
    }

    // --- MODERN KART TASARIMI ---
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20), // Daha yuvarlak köşeler
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          if (!isDark) // Sadece aydınlık modda gölge
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ÜST KISIM (BAŞLIK & DURUM)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İkon Kutusu
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.work_outline_rounded, color: theme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 16),

                    // Başlık ve İsim
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800, // Daha kalın font
                              height: 1.2,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.owner.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Durum Çipi (Status Chip)
                    if (project.status != null) ...[
                      const SizedBox(width: 8),
                      StatusChip(status: project.status),
                    ]
                  ],
                ),

                const SizedBox(height: 20),

                // 2. ORTA KISIM (BİLGİ ÇİPLERİ)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ModernInfoChip(
                      icon: Icons.account_balance_wallet_rounded,
                      text: budgetText,
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    _ModernInfoChip(
                      icon: Icons.category_rounded,
                      text: project.category,
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. ALT KISIM (YETENEKLER & TARİH)
                Row(
                  children: [
                    if (skillsSummary.isNotEmpty) ...[
                      Icon(Icons.layers_outlined, size: 16, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          skillsSummary,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    // Tarih (Timeago)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeago.format(project.createdAt, locale: 'tr'),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // 4. AKSİYON BUTONU (VARSA)
                if (actionButton != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: actionButton,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- YARDIMCI MODERN ÇİP WIDGET'I ---
class _ModernInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _ModernInfoChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08), // Arka plan rengi
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2), // Hafif kenarlık
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
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