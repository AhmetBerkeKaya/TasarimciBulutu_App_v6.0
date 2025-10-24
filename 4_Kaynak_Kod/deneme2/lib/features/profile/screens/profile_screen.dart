// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Gerekli tüm ekran ve widget'ları import ettiğimizden emin olalım
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_model.dart';
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
  // YENİ: Dışarıdan bu ekranın belirli bir bölüme kaydırılıp kaydırılmayacağını kontrol eden parametre.
  final bool scrollToReviews;

  const ProfileScreen({
    super.key,
    this.userId,
    this.scrollToReviews = false, // Varsayılan olarak kapalı.
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
    if (_isMyProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profilim'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Ayarlar',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
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
                    icon: const Icon(Icons.edit_outlined),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 16),
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
                            Text(widget.user.avgRating.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
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
                                Text('(${widget.user.reviewCount} değerlendirme)', style: Theme.of(context).textTheme.bodySmall),
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
                    actionButton: widget.isMyProfile ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageSkillsScreen()))) : null,
                    child: widget.user.skills.isEmpty
                        ? const Text('Henüz yetenek eklenmemiş.')
                        : Wrap(spacing: 8.0, runSpacing: 8.0, children: widget.user.skills.map((skill) => Chip(label: Text(skill.name))).toList()),
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
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const SkillTestListScreen(),
                              ));
                            },
                            child: const Text('Testleri Görüntüle'),
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
                    actionButton: widget.isMyProfile ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageExperienceScreen()))) : null,
                    child: widget.user.workExperiences.isEmpty
                        ? const Text('Henüz iş deneyimi eklenmemiş.')
                        : Column(
                      children: widget.user.workExperiences.map((exp) {
                        final formatter = DateFormat('yyyy');
                        final period = '${formatter.format(exp.startDate)} - ${exp.endDate != null ? formatter.format(exp.endDate!) : 'Devam Ediyor'}';
                        return ListTile(contentPadding: EdgeInsets.zero, title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${exp.companyName} • $period'));
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    icon: Icons.photo_library_outlined,
                    title: 'Portfolyo',
                    actionButton: widget.isMyProfile ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManagePortfolioScreen()))) : null,
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
                                    Expanded(flex: 3, child: Container(color: Colors.grey.shade200, child: _buildFilePreview(item.imageUrl))),
                                    Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(8.0), child: Center(child: Text(item.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))))),
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

  Widget _buildFilePreview(String fileUrl) {
    final extension = fileUrl.split('.').last.toLowerCase();
    if (['png', 'jpg', 'jpeg', 'gif'].contains(extension)) {
      return Image.network(
        fileUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (extension == 'pdf') {
      return const Center(child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 40));
    } else {
      return const Center(child: Icon(Icons.insert_drive_file_outlined, color: Colors.grey, size: 40));
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
            backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty ? NetworkImage(user.profilePictureUrl!) : null,
            child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary) : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              if (actionButton != null) actionButton,
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          child,
        ],
      ),
    );
  }
}