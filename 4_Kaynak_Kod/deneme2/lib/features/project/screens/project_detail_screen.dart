// lib/features/project/screens/project_detail_screen.dart (TAM GÜNCEL HALİ)

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
    // Provider'ları dinle
    final authProvider = context.watch<AuthProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();

    final currentUser = authProvider.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Oturum bulunamadı.")));
    }

    // Durumları hesapla
    final bool isOwner = currentUser.id == project.owner.id;
    final bool isAcceptedFreelancer =
        project.acceptedApplication?.freelancer.id == currentUser.id;
    final bool canReview =
        project.status == ProjectStatus.completed && (isOwner || isAcceptedFreelancer);
    final bool hasAlreadyReviewed =
    project.reviews.any((review) => review.reviewer.id == currentUser.id);
    final bool isFreelancer = currentUser.role == UserRole.freelancer;
    final bool isProjectOpen = project.status == ProjectStatus.open;

    // Başvuru kontrolü (Canlı veriden)
    final bool hasAlreadyApplied = applicationProvider.myApplications
        .any((app) => app.project.id == project.id);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.5),
            child: BackButton(color: theme.colorScheme.onSurface),
          ),
        ),
        actions: [
          if (isOwner)
            _buildOwnerMenu(context, project.id),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // --- BAŞLIK VE FİRMA ---
          SliverToBoxAdapter(
            child: _buildHeader(context, project),
          ),

          // --- DETAY KUTUCUKLARI ---
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

          // Alt barın içeriği kapatmaması için boşluk
          if (project.revisions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32), // Ayırıcı çizgi
                    _buildSectionTitle(context, 'Revizyon Geçmişi'),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true, // Scroll içinde scroll olmaması için
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: project.revisions.length,
                      itemBuilder: (context, index) {
                        final revision = project.revisions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isDark ? Colors.grey[900] : Colors.orange[50],
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.history, size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Revizyon Talebi',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeago.format(revision.requestedAt, locale: 'tr'),
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  revision.requestReason,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 120), // Rahatça kaydırmak için boşluk
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
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

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
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

  // --- GÜNCELLENMİŞ YETENEK LİSTESİ ---
  Widget _buildSkillsWrap(BuildContext context, List<Skill> skills) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40, // Sabit yükseklik verip yatay kaydırma sağlıyoruz
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: skills.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final skill = skills[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.secondaryContainer.withOpacity(0.2)
                  : theme.colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    Icons.code,
                    size: 16,
                    color: theme.colorScheme.secondary
                ),
                const SizedBox(width: 6),
                Text(
                  skill.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  // ------------------------------------
  Widget _buildOwnerMenu(BuildContext context, String projectId) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        child: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          // Düzenleme ekranına git
          // NOT: Buraya özel bir ProjectEditScreen yapısı gerekecek.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Düzenleme Ekranı entegre edilecek.")),
          );
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(context, projectId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Projeyi Düzenle'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Projeyi Sil', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

/// lib/features/project/screens/project_detail_screen.dart dosyasının en altındaki fonksiyonu güncelle:

  void _showDeleteConfirmationDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proje Silme Onayı'),
        content: const Text(
            'Bu projeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm başvurular silinecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // 1. Önce Diyaloğu kapat
              Navigator.pop(context);

              // 2. Silme işlemini başlat
              final success = await context.read<ProjectProvider>().deleteProject(projectId);

              if (context.mounted) {
                if (success) {
                  // === KRİTİK EKLEME ===
                  // 3. İşlem başarılıysa DETAY EKRANINI DA KAPAT (Geri Dön)
                  Navigator.of(context).pop();
                  // =====================

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proje başarıyla silindi!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silme işlemi başarısız oldu.')),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

    String? buttonText;
    IconData? buttonIcon;
    VoidCallback? onPressed;
    Color? buttonColor;
    Color? foregroundColor;

    // 1. Firma: Başvuruları Gör
    if (isOwner && project.status == ProjectStatus.open) {
      buttonText = 'Gelen Başvuruları Görüntüle (${project.applications.length})';
      buttonIcon = Icons.people_outline;
      onPressed = () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProjectApplicantsScreen(
            projectId: project.id, projectTitle: project.title),
      ));
    }
    // --- YENİ EKLENEN KISIM: REVIZYON / ONAY MANTIĞI ---
    // 2. Firma: İnceleme Bekleniyor (Teslim Edilmiş)
    else if (isOwner && project.status == ProjectStatus.pending_review) {
      buttonText = 'Teslimatı Değerlendir';
      buttonIcon = Icons.rate_review_outlined;
      buttonColor = Colors.orange.shade700;
      onPressed = () {
        // Onaylama veya Revizyon seçeneği sunan BottomSheet aç
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Teslimatı Değerlendir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Freelancer projeyi teslim etti. İnceleyip onaylayabilir veya revizyon isteyebilirsiniz.'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Teslimatı Onayla ve Tamamla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Sheet'i kapat
                    context.read<ProjectProvider>().acceptDelivery(project.id);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Revizyon Talep Et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.orange.shade800),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Önce Sheet'i kapat
                    _showRevisionDialog(context, project.id); // Sonra Dialog aç
                  },
                ),
              ],
            ),
          ),
        );
      };
    }
    // -------------------------------------------------

    // 3. Freelancer: Teslim Et (Devam Ediyor)
    else if (isFreelancer && project.status == ProjectStatus.in_progress) {
      buttonText = 'Projeyi Teslim Et';
      buttonIcon = Icons.upload_file;
      buttonColor = Colors.blue;
      onPressed = () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Teslimatı Onayla"),
            content: const Text("Projeyi tamamladığınızı ve teslim etmek istediğinizi onaylıyor musunuz?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Evet, Teslim Et")),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.read<ProjectProvider>().deliverProject(project.id);
        }
      };
    }

    // 4. Freelancer: Başvur
    else if (isFreelancer && isProjectOpen && !hasAlreadyApplied) {
      buttonText = 'Projeye Başvur';
      buttonIcon = Icons.send_outlined;
      onPressed = () => showDialog(
        context: context,
        builder: (context) => ApplicationDialog(projectId: project.id),
      );
    }

    // 5. Herkes: Değerlendir (Tamamlandı)
    else if (canReview && !hasAlreadyReviewed) {
      buttonText = 'Değerlendirme Yap';
      buttonIcon = Icons.rate_review_outlined;
      buttonColor = Colors.amber.shade800;
      onPressed = () async {
        final reviewee = isOwner
            ? project.acceptedApplication!.freelancer
            : project.owner;

        final reviewSubmitted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => SubmitReviewScreen(
              projectId: project.id,
              revieweeId: reviewee.id,
              revieweeName: reviewee.name,
            ),
          ),
        );

        if (reviewSubmitted == true && context.mounted) {
          context.read<ProjectProvider>().fetchMyProjects();
        }
      };
    }

    // 6. Pasif Durumlar (Başvuruldu, Bekleniyor vs.)
    else if (isFreelancer && isProjectOpen && hasAlreadyApplied) {
      buttonText = 'Başvurunuz Gönderildi';
      buttonIcon = Icons.check_circle_outline;
      onPressed = null; // Pasif
    } else if (project.status == ProjectStatus.pending_review && isFreelancer) {
      buttonText = 'Onay Bekleniyor';
      buttonIcon = Icons.hourglass_empty;
      onPressed = null;
    } else if (project.status == ProjectStatus.completed) {
      buttonText = 'Proje Tamamlandı';
      buttonIcon = Icons.check_circle;
      buttonColor = Colors.grey;
      onPressed = null;
    }

    if (buttonText != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(buttonIcon),
          label: Text(buttonText),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor ?? Theme.of(context).primaryColor,
            foregroundColor: foregroundColor ?? Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // === YENİ FONKSİYON: REVIZYON DİYALOĞU ===
  void _showRevisionDialog(BuildContext context, String projectId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revizyon Talebi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lütfen revizyon sebebini ve düzeltilmesi gereken yerleri açıklayın:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: Renkler uyuşmamış, logo daha büyük olmalı...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context); // Dialog'u kapat
                // Provider üzerinden API çağrısı (reason parametresiyle)
                // NOT: requestRevision fonksiyonunu reason alacak şekilde güncellemeliyiz.
                context.read<ProjectProvider>().requestRevision(projectId, reason);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen bir açıklama girin.")),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

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

    // --- DÜZELTME: Expanded KALDIRILDI ---
    // Wrap içinde Expanded kullanılamaz. Bunun yerine Container'a
    // esnek bir genişlik verebiliriz veya içeriği kadar yer kaplamasını sağlarız.
    // En temizi, ekranın yarısını kaplayacak şekilde ayarlamak.

    final width = (MediaQuery.of(context).size.width - 48) / 2; // 2 sütunlu yapı için

    return Container(
      width: width, // Sabit genişlik
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // İçeriği kadar yükseklik
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 2, // Çok uzun metinleri sınırla
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
    // -------------------------------------
  }
}