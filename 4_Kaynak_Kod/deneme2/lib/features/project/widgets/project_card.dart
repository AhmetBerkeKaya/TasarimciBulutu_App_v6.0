// lib/common_widgets/project_card.dart (YENİ, PROFESYONEL VE RESPONSIVE TASARIM)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../common_widgets/status_chip.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/skill_model.dart'; // Skill modelini import ediyoruz

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

    return Card(
      elevation: isDark ? 1 : 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ÜST KISIM: Firma ve Zaman ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    // Profil resmi varsa NetworkImage ile göster, yoksa baş harfi göster
                    backgroundImage: project.owner.profilePictureUrl != null && project.owner.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(project.owner.profilePictureUrl!)
                        : null,
                    child: project.owner.profilePictureUrl == null || project.owner.profilePictureUrl!.isEmpty
                        ? Text(
                      project.owner.name.isNotEmpty ? project.owner.name.substring(0, 1).toUpperCase() : 'F',
                      style: TextStyle(
                          fontSize: 14, // Boyutu ayarlayalım
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.owner.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeago.format(project.createdAt, locale: 'tr'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
              const Divider(height: 24),

              // --- ORTA KISIM: Başlık, Durum ve Açıklama ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible( // Başlığın taşmasını önler
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 8),
              if (project.description != null && project.description!.isNotEmpty)
                Text(
                  project.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),

              // --- ALT KISIM: Bütçe ve Yetenek Etiketleri (Responsive) ---
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InfoChip(
                    icon: Icons.account_balance_wallet_outlined,
                    text: budgetText,
                    color: theme.colorScheme.primary,
                  ),
                  _InfoChip(
                    icon: Icons.category_outlined,
                    text: project.category,
                    color: theme.colorScheme.secondary,
                  ),
                  // Gerekli yetenekleri göster
                  ...project.requiredSkills.map((skill) => _InfoChip(
                    icon: Icons.code, // Veya başka bir ikon
                    text: skill.name,
                    color: Colors.teal, // Farklı bir renk
                  )),
                ],
              ),

              // --- AKSİYON BUTONU BÖLÜMÜ ---
              if (actionButton != null) ...[
                const Divider(height: 32),
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

// --- YENİ YARDIMCI WIDGET: Şık bilgi etiketleri için ---
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible( // Etiket içindeki metnin de taşmasını önler
            child: Text(
              text,
              style:
              TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}