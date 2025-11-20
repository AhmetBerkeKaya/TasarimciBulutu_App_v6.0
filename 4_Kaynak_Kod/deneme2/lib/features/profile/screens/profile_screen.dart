// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/skill_model.dart'; // Skill modeli için import
import '../../../data/models/test_result_model.dart';
import '../../../common_widgets/pdf_viewer_screen.dart';
import '../../skill_assessment/screens/skill_test_list_screen.dart';
import '../widgets/review_card.dart';
import '../widgets/skill_badge.dart';
import 'all_reviews_screen.dart';
import 'edit_profile_screen.dart';
import 'manage_experience_screen.dart';
import 'manage_portfolio_screen.dart';
import 'manage_skills_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool scrollToReviews;

  const ProfileScreen({
    super.key,
    this.userId,
    this.scrollToReviews = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<User?>? _userFuture;
  bool _isMyProfile = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.id;

    if (widget.userId == null || widget.userId == myId) {
      _isMyProfile = true;
    } else {
      _isMyProfile = false;
      _userFuture = ApiService().getUserProfileById(userId: widget.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isMyProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profilim'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
              tooltip: 'Ayarlar',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              tooltip: 'Çıkış Yap',
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.user == null) return const LoadingIndicator();
            return _ProfileBody(user: auth.user!, isMyProfile: true, scrollToReviews: widget.scrollToReviews);
          },
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Kullanıcı Profili')),
        body: FutureBuilder<User?>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
            if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text('Kullanıcı bulunamadı.'));
            return _ProfileBody(user: snapshot.data!, isMyProfile: false, scrollToReviews: widget.scrollToReviews);
          },
        ),
      );
    }
  }
}

class _ProfileBody extends StatefulWidget {
  final User user;
  final bool isMyProfile;
  final bool scrollToReviews;

  const _ProfileBody({
    required this.user,
    required this.isMyProfile,
    required this.scrollToReviews,
  });

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  final GlobalKey _reviewsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToReviews) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _reviewsKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          _buildProfileHeader(context, widget.user),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSection(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Hakkımda',
                  actionButton: widget.isMyProfile
                      ? IconButton(
                    icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
                    onPressed: () async {
                      final bool? result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      if (result == true && context.mounted) {
                        Provider.of<AuthProvider>(context, listen: false).refreshUserData();
                      }
                    },
                  )
                      : null,
                  child: Text(
                    widget.user.bio?.isNotEmpty ?? false ? widget.user.bio! : 'Henüz bir biyografi eklenmemiş.',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),

                // ... Değerlendirmeler Bölümü (Aynı kalacak) ...
                KeyedSubtree(
                  key: _reviewsKey,
                  child: _buildSection(
                    context,
                    icon: Icons.star_outline_rounded,
                    title: 'Değerlendirmeler',
                    child: widget.user.reviewsReceived.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Henüz değerlendirme almamış.')))
                        : Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(widget.user.avgRating.toStringAsFixed(1), style: theme.textTheme.headlineMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RatingBarIndicator(
                                  rating: widget.user.avgRating,
                                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                ),
                                Text('(${widget.user.reviewCount} değerlendirme)', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        ReviewCard(review: widget.user.reviewsReceived.first),
                        if (widget.user.reviewsReceived.length > 1) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AllReviewsScreen(userId: widget.user.id, userName: widget.user.name))),
                              style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                              child: Text('Tüm ${widget.user.reviewCount} Değerlendirmeyi Gör'),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),

                if (widget.user.role == UserRole.freelancer) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Yetenekler',
                    actionButton: widget.isMyProfile
                        ? IconButton(icon: Icon(Icons.edit_outlined, color: theme.primaryColor), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageSkillsScreen())))
                        : null,
                    // --- DEĞİŞİKLİK BURADA: Genişletilebilir Widget Kullanıyoruz ---
                    child: widget.user.skills.isEmpty
                        ? const Text('Henüz yetenek eklenmemiş.')
                        : _ExpandableSkillWrap(skills: widget.user.skills),
                    // -------------------------------------------------------------
                  ),
                  if (widget.isMyProfile) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.checklist_rtl_rounded,
                      title: 'Yetkinlik Testleri',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Yetkinliklerinizi platform onaylı testler ile kanıtlayarak profilinizi güçlendirin ve projelerde bir adım öne çıkın.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const SkillTestListScreen(),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Testleri Görüntüle', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    icon: Icons.work_history_outlined,
                    title: 'İş Deneyimi',
                    actionButton: widget.isMyProfile ? IconButton(icon: Icon(Icons.edit_outlined, color: theme.primaryColor), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageExperienceScreen()))) : null,
                    child: widget.user.workExperiences.isEmpty
                        ? const Text('Henüz iş deneyimi eklenmemiş.')
                        : Column(
                      children: widget.user.workExperiences.map((exp) {
                        final formatter = DateFormat('yyyy');
                        final period = '${formatter.format(exp.startDate)} - ${exp.endDate != null ? formatter.format(exp.endDate!) : 'Devam Ediyor'}';
                        return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${exp.companyName} • $period')
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    icon: Icons.photo_library_outlined,
                    title: 'Portfolyo',
                    actionButton: widget.isMyProfile ? IconButton(icon: Icon(Icons.edit_outlined, color: theme.primaryColor), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManagePortfolioScreen()))) : null,
                    child: widget.user.portfolioItems.isEmpty
                        ? const Text('Henüz portfolyo öğesi eklenmemiş.')
                        : SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.user.portfolioItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.user.portfolioItems[index];
                          final extension = item.imageUrl.split('.').last.toLowerCase();
                          return SizedBox(
                            width: 160,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: 2,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                onTap: () {
                                  if (extension == 'pdf') {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(fileUrl: item.imageUrl, title: item.title),
                                    ));
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: Container(
                                            color: Colors.grey.shade100,
                                            child: _buildFilePreview(item.imageUrl, theme)
                                        )
                                    ),
                                    Expanded(
                                        flex: 1,
                                        child: Container(
                                            color: theme.cardColor,
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                                child: Text(
                                                    item.title,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)
                                                )
                                            )
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (Yardımcı fonksiyonlar aynı: _buildFilePreview, _buildProfileHeader, _buildSection) ...
  // Bu fonksiyonları zaten önceki dosyada vardı, aynen kalacaklar.
  Widget _buildFilePreview(String fileUrl, ThemeData theme) {
    final extension = fileUrl.split('.').last.toLowerCase();
    if (['png', 'jpg', 'jpeg', 'gif'].contains(extension)) {
      return Image.network(
        fileUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor))),
      );
    } else if (extension == 'pdf') {
      return const Center(child: Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 40));
    } else {
      return Center(child: Icon(Icons.insert_drive_file_outlined, color: theme.primaryColor, size: 40));
    }
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                ? NetworkImage("${user.profilePictureUrl!}?v=${DateTime.now().millisecondsSinceEpoch}")
                : null,
            child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(height: 16),

          // Rozetler
          if (user.testResults.where((r) => r.score != null && r.score! >= 70).isNotEmpty)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: user.testResults
                  .where((result) => result.score != null && result.score! >= 70)
                  .map((result) => SkillBadge(softwareName: result.skillTest.software))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, Widget? actionButton, required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: theme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              if (actionButton != null) actionButton,
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 1),
          ),
          child,
        ],
      ),
    );
  }
}

// === YENİ: GENİŞLETİLEBİLİR YETENEK WRAP WIDGET'I ===
class _ExpandableSkillWrap extends StatefulWidget {
  final List<Skill> skills;
  const _ExpandableSkillWrap({required this.skills});

  @override
  State<_ExpandableSkillWrap> createState() => _ExpandableSkillWrapState();
}

class _ExpandableSkillWrapState extends State<_ExpandableSkillWrap> {
  bool _isExpanded = false;
  static const int _initialCount = 5; // İlk başta kaç tane görünsün

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Gösterilecek yetenek listesi (Genişletilmişse hepsi, değilse ilk 5'i)
    final skillsToShow = _isExpanded || widget.skills.length <= _initialCount
        ? widget.skills
        : widget.skills.take(_initialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: skillsToShow.map((skill) => Chip(
            label: Text(skill.name, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          )).toList(),
        ),

        // Eğer yetenek sayısı 5'ten fazlaysa "Daha Fazla / Daha Az" butonunu göster
        if (widget.skills.length > _initialCount)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Daha Az Göster' : 'Daha Fazla Göster (${widget.skills.length - _initialCount})',
                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.primaryColor,
                  )
                ],
              ),
            ),
          )
      ],
    );
  }
}