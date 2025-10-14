// lib/features/project/screens/project_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../common_widgets/status_chip.dart';
import '../../../core/providers/application_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/skill_model.dart';
import '../widgets/application_dialog.dart';
import '../../profile/screens/submit_review_screen.dart';
import 'project_aplicants_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---

    // Artık hem AuthProvider'ı hem de ApplicationProvider'ı dinliyoruz.
    final authProvider = context.watch<AuthProvider>();
    final applicationProvider = context.watch<ApplicationProvider>(); // <-- YENİ EKLENDİ

    final currentUser = authProvider.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Oturum bulunamadı.")));
    }

    // Gerekli tüm koşulları en başta hesaplayalım
    final bool isOwner = currentUser.id == project.owner.id;
    final bool isAcceptedFreelancer =
        project.acceptedApplication?.freelancer.id == currentUser.id;
    final bool canReview =
        project.status == ProjectStatus.completed && (isOwner || isAcceptedFreelancer);
    final bool hasAlreadyReviewed =
    project.reviews.any((review) => review.reviewer.id == currentUser.id);
    final bool isFreelancer = currentUser.role == UserRole.freelancer;
    final bool isProjectOpen = project.status == ProjectStatus.open;

    // 'hasAlreadyApplied' mantığını canlı veriyle güncelliyoruz.
    // Provider'daki `myApplications` listesinde bu projenin ID'si var mı diye kontrol et.
    final bool hasAlreadyApplied = applicationProvider.myApplications
        .any((app) => app.project.id == project.id); // <-- MANTIK DEĞİŞTİ

    // --- DEĞİŞİKLİK BURADA BİTİYOR ---

    return Scaffold(
      // Body'nin AppBar'ın arkasına uzanmasını sağlayarak modern bir görünüm elde ediyoruz
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Geri butonunun arka planını daha görünür yapıyoruz
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.5),
            child: BackButton(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // --- PROJE BAŞLIĞI VE FİRMA BİLGİSİ ---
          SliverToBoxAdapter(
            child: _buildHeader(context, project),
          ),

          // --- DETAYLAR BÖLÜMÜ (RESPONSIVE) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildInfoSection(context, project),
            ),
          ),

          // --- AÇIKLAMA VE YETENEKLER ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Proje Açıklaması'),
                  const SizedBox(height: 8),
                  Text(
                    project.description ?? 'Açıklama bulunmuyor.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 24),
                  if (project.requiredSkills.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Gerekli Yetenekler'),
                    const SizedBox(height: 12),
                    _buildSkillsWrap(context, project.requiredSkills),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
      // --- ALT KISIMDA SABİT DURAN AKSİYON BUTONU ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildActionButtons(
          context,
          isOwner: isOwner,
          isFreelancer: isFreelancer,
          isProjectOpen: isProjectOpen,
          hasAlreadyApplied: hasAlreadyApplied,
          canReview: canReview,
          hasAlreadyReviewed: hasAlreadyReviewed,
          project: project,
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildHeader(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(status: project.status),
          const SizedBox(height: 12),
          Text(
            project.title,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(project.owner.name.substring(0, 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firma',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    Text(
                      project.owner.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Project project) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    String budgetText;
    if (project.budgetMin != null && project.budgetMax != null) {
      budgetText =
      '${currencyFormat.format(project.budgetMin)} - ${currencyFormat.format(project.budgetMax)}';
    } else {
      budgetText = 'Teklife Açık';
    }

    // Wrap widget'ı, elemanlar sığmadığında otomatik olarak alt satıra geçer.
    // Bu, ekranın her boyutta düzgün görünmesini sağlar.
    return Wrap(
      spacing: 12.0, // Yatay boşluk
      runSpacing: 12.0, // Dikey boşluk
      children: [
        _InfoTile(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: project.category),
        _InfoTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Bütçe',
            value: budgetText),
        _InfoTile(
            icon: Icons.timer_outlined,
            label: 'Yayınlanma',
            value: timeago.format(project.createdAt, locale: 'tr')),
        if (project.deadline != null)
          _InfoTile(
              icon: Icons.event_busy_outlined,
              label: 'Son Başvuru',
              value: DateFormat('dd MMMM yyyy', 'tr_TR').format(project.deadline!)),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSkillsWrap(BuildContext context, List<Skill> skills) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: skills.map((skill) {
        return Chip(
          avatar: Icon(Icons.code, size: 16, color: theme.colorScheme.secondary),
          label: Text(skill.name),
          backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.5),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, {
        required bool isOwner,
        required bool isFreelancer,
        required bool isProjectOpen,
        required bool hasAlreadyApplied,
        required bool canReview,
        required bool hasAlreadyReviewed,
        required Project project,
      }) {
    // ... (Bu fonksiyonun iç mantığı aynı, sadece stil değişikliği yapıldı)
    // ... Sadece bir tane ElevatedButton döndürecek şekilde refactor edildi.

    String? buttonText;
    IconData? buttonIcon;
    VoidCallback? onPressed;
    Color? buttonColor;

    // Firma için Başvuru Yönetim Butonu
    if (isOwner && project.status != ProjectStatus.completed) {
      buttonText = 'Gelen Başvuruları Görüntüle (${project.applications.length})';
      buttonIcon = Icons.people_outline;
      onPressed = () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProjectApplicantsScreen(
            projectId: project.id, projectTitle: project.title),
      ));
    }
    // Freelancer için Başvuru Butonu
    else if (isFreelancer && isProjectOpen && !hasAlreadyApplied) {
      buttonText = 'Projeye Başvur';
      buttonIcon = Icons.send_outlined;
      onPressed = () => showDialog(
        context: context,
        builder: (context) => ApplicationDialog(projectId: project.id),
      );
    }
    // Değerlendirme Butonu
    else if (canReview && !hasAlreadyReviewed) {
      buttonText = 'Değerlendirme Yap';
      buttonIcon = Icons.rate_review_outlined;
      buttonColor = Colors.amber.shade800;
      onPressed = () async {
        // Değerlendirilecek kişiyi (reviewee) dinamik olarak belirle:
        // Eğer ben proje sahibiysem (isOwner), kabul edilen freelancer'ı değerlendiririm.
        // Eğer ben freelancer'sam, proje sahibini değerlendiririm.
        final reviewee = isOwner
            ? project.acceptedApplication!.freelancer
            : project.owner;

        // Değerlendirme ekranına yönlendir ve geri dönüldüğünde sonucu bekle
        final reviewSubmitted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => SubmitReviewScreen(
              projectId: project.id,
              revieweeId: reviewee.id,
              revieweeName: reviewee.name,
            ),
          ),
        );

        // Eğer submit_review_screen'den `true` değeriyle dönüldüyse (yani başarılıysa),
        // `hasAlreadyReviewed` durumunu güncellemek için proje verilerini yeniden çek.
        // Bu, butonun anında kaybolmasını sağlar.
        if (reviewSubmitted == true && context.mounted) {
          context.read<ProjectProvider>().fetchMyProjects();
        }
      };
    }
    // Freelancer başvurduysa ama proje hala açıksa
    else if (isFreelancer && isProjectOpen && hasAlreadyApplied) {
      buttonText = 'Başvurunuz Gönderildi';
      buttonIcon = Icons.check_circle_outline;
      onPressed = null; // Buton pasif
    }

    if (buttonText != null && onPressed != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(buttonIcon),
          label: Text(buttonText),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Hiçbir koşul sağlanmazsa boş bir widget döndür
    return const SizedBox.shrink();
  }
}

/// Detay kartı içindeki küçük bilgi kutucukları için bir widget.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}