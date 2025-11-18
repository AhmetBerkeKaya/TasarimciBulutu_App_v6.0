// lib/features/project/widgets/project_card.dart (DÜZELTİLMİŞ)

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
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.05),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ÜST KISIM ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded( // Metin alanı esnesin
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: project.status),
                ],
              ),

              const SizedBox(height: 12),

              // --- ORTA KISIM (Taşmayı önlemek için Flexible) ---
              Row(
                children: [
                  Flexible( // Esnek genişlik
                    child: _CompactInfoChip(
                      icon: Icons.account_balance_wallet_outlined,
                      text: budgetText,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible( // Esnek genişlik
                    child: _CompactInfoChip(
                      icon: Icons.category_outlined,
                      text: project.category,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),

              // --- ALT KISIM ---
              if (skillsSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.code, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded( // Metin uzunsa kes
                      child: Text(
                        skillsSummary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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

              if (actionButton != null) ...[
                const Divider(height: 24),
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
        mainAxisSize: MainAxisSize.min, // İçeriği kadar küçül
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible( // Metin taşarsa kes
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