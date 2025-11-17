// lib/features/showcase/screens/showcase_feed_screen.dart (GÜNCELLENMİŞ HALİ)

import 'dart:async'; // <-- DEBOUNCER İÇİN EKLENDİ
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../notifications/screens/notification_screen.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class ShowcaseFeedScreen extends StatefulWidget {
  const ShowcaseFeedScreen({super.key});

  @override
  State<ShowcaseFeedScreen> createState() => _ShowcaseFeedScreenState();
}

class _ShowcaseFeedScreenState extends State<ShowcaseFeedScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _searchAnimation;

  bool _showScrollToTop = false;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  // === DEĞİŞİKLİK BURADA (1/4) ===
  // _searchQuery değişkenini kaldırdık, çünkü artık provider'da tutuluyor.
  // String _searchQuery = ''; // <-- BU SATIRI SİLDİK

  // Debouncer (geciktirici) için bir Timer ekledik
  Timer? _debounce;
  // ===============================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialData();
    _scrollController.addListener(_onScroll);
  }

  // ... ( _initializeAnimations() fonksiyonu aynı, değişiklik yok) ...
  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOutCubic,
    );
  }
  // ==============================================================


  void _setupInitialData() {
    Future.microtask(() {
      final provider = Provider.of<ShowcaseProvider>(context, listen: false);

      // === DEĞİŞİKLİK BURADA (2/4) ===
      // Arama çubuğunu, provider'daki mevcut arama terimiyle senkronize et
      _searchController.text = provider.searchQuery;
      // ===============================

      if (provider.state == ShowcaseState.initial) {
        provider.fetchPosts();
      }
      _headerAnimationController.forward();
      _fabAnimationController.forward();
    });
  }

  // ... ( _onScroll() fonksiyonu aynı, değişiklik yok) ...
  void _onScroll() {
    final showButton = _scrollController.offset > 300;
    if (showButton != _showScrollToTop) {
      setState(() => _showScrollToTop = showButton);
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ShowcaseProvider>(context, listen: false);
      if (provider.state != ShowcaseState.loadingMore && provider.hasMorePosts) {
        provider.fetchMorePosts();
      }
    }
  }
  // =======================================================


  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    // === DEĞİŞİKLİK BURADA (3/4) ===
    // Yenileme yaptığımızda arama çubuğunu da temizleyelim
    _searchController.clear();
    // Arama sorgusunu provider'da temizle ve yeniden yükle
    await Provider.of<ShowcaseProvider>(context, listen: false).searchPosts('');
    // ===============================

    await Future.delayed(const Duration(milliseconds: 500)); // Minimum duration for UX

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  // ... ( _scrollToTop() fonksiyonu aynı, değişiklik yok) ...
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutQuart,
    );
  }
  // ======================================================

  void _toggleSearch() {
    setState(() => _isSearchExpanded = !_isSearchExpanded);

    if (_isSearchExpanded) {
      _searchAnimationController.forward();
      // Odaklanmayı daha yumuşak hale getir
      Future.delayed(const Duration(milliseconds: 300), () {
        if(mounted) FocusScope.of(context).requestFocus(FocusNode());
      });
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      // === DEĞİŞİKLİK BURADA (4/4) ===
      // Arama çubuğu kapandığında provider'ı da temizle ve yeniden yükle
      Provider.of<ShowcaseProvider>(context, listen: false).searchPosts('');
      // ===============================
      FocusScope.of(context).unfocus();
    }
  }

  // === DEĞİŞİKLİK BURADA (5/4) ===
  // _onSearchChanged fonksiyonu artık provider'ı tetikliyor (debouncer ile)
  void _onSearchChanged(String query) {
    // Önceki gecikmeli aramayı iptal et
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Kullanıcı yazmayı bıraktıktan 500ms sonra aramayı başlat
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Provider'daki arama fonksiyonunu çağır
      Provider.of<ShowcaseProvider>(context, listen: false).searchPosts(query);
    });
  }
  // ===============================

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _searchAnimationController.dispose();
    _debounce?.cancel(); // <-- Debouncer'ı dispose et
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (build fonksiyonunun geri kalanı aynı, değişiklik yok) ...
    // Sadece _buildSearchBar içindeki _onSearchChanged artık
    // debouncer'lı yeni fonksiyonumuzu kullanacak.

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.primaryColor,
        backgroundColor: theme.cardColor,
        strokeWidth: 2.5,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernAppBar(theme, isDark),
            _buildSearchBar(theme, isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _buildContent(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: isKeyboardVisible ? null : _buildFloatingActionButtons(theme, isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModernAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF0A0A0A),
                  ]
                      : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _buildGlassContainer(
                          theme: theme,
                          isDark: isDark,
                          child: Icon(
                            Icons.auto_awesome,
                            color: theme.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    theme.primaryColor,
                                    theme.primaryColor.withOpacity(0.7),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'Proje Vitrini',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'İlham veren projeler keşfet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: Text(
          '',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 106, bottom: 45),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return badges.Badge(
              showBadge: notificationProvider.unreadCount > 0,
              badgeContent: Text(
                notificationProvider.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              position: badges.BadgePosition.topEnd(top: 4, end: 4),
              badgeAnimation: const badges.BadgeAnimation.scale(),
              child: _buildGlassActionButton(
                icon: Icons.notifications_outlined,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ));
                },
                theme: theme,
                isDark: isDark,
              ),
            );
          },
        ),
        _buildGlassActionButton(
          icon: _isSearchExpanded ? Icons.close : Icons.search,
          onPressed: _toggleSearch,
          theme: theme,
          isDark: isDark,
        ),
        _buildGlassActionButton(
          icon: Icons.tune,
          onPressed: _showFilterBottomSheet,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildGlassContainer({
    required ThemeData theme,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : theme.primaryColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        height: _isSearchExpanded ? 80 : 0,
        child: SizeTransition( // <-- Daha yumuşak bir görünüm için SizeTransition
          sizeFactor: _searchAnimation,
          axisAlignment: -1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged, // <-- Artık debouncer'lı fonksiyonu çağırıyor
              decoration: InputDecoration(
                hintText: 'Proje, kullanıcı veya teknoloji ara...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.primaryColor,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty // <-- _searchQuery yerine controller'ı dinle
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged(''); // <-- Provider'ı temizle
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ShowcaseProvider>(
      builder: (context, provider, child) {
        switch (provider.state) {
          case ShowcaseState.initial:
          case ShowcaseState.loading:
            return SliverFillRemaining(
              child: _buildLoadingState(),
            );

          case ShowcaseState.error:
            return SliverFillRemaining(
              child: _buildErrorState(provider),
            );

          case ShowcaseState.loaded:
          case ShowcaseState.loadingMore:
            if (provider.posts.isEmpty) {

              // === DEĞİŞİKLİK BURADA ===
              // SliverFillRemaining yerine SliverToBoxAdapter kullanarak
              // içeriği ekranın üstüne sabitliyoruz. Bu, hem piksel
              // taşmasını hem de FAB çakışmasını çözer.
              return SliverToBoxAdapter(
                child: Padding(
                  // Ekranın üstünden biraz boşluk bırakıyoruz
                  padding: const EdgeInsets.only(top: 64.0, bottom: 200.0),
                  child: provider.searchQuery.isNotEmpty
                      ? _buildEmptySearchState(provider) // Arama boş durumu
                      : _buildEmptyState(provider),      // Normal boş durum
                ),
              );
              // =========================
            }
            return _buildPostsList(provider);
        }
      },
    );
  }

  // === YENİ WIDGET (6/4) ===
  // Arama sonucu boş geldiğinde gösterilecek widget
  Widget _buildEmptySearchState(ShowcaseProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sonuç Bulunamadı',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Aradığınız terimle ('),
                  TextSpan(
                    text: '"${provider.searchQuery}"',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  const TextSpan(text: ') eşleşen bir proje bulunamadı.'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildModernButton(
              onPressed: () {
                _searchController.clear();
                provider.searchPosts('');
              },
              icon: Icons.clear_all_rounded,
              label: 'Aramayı Temizle',
              isPrimary: true,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
  // =========================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Projeler yükleniyor...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ShowcaseProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Bağlantı Sorunu',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'İnternet bağlantınızı kontrol edip tekrar deneyin',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildModernButton(
              onPressed: () => provider.fetchPosts(),
              icon: Icons.refresh_rounded,
              label: 'Tekrar Dene',
              isPrimary: true,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShowcaseProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 80,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'İlk Adımı Atın!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz paylaşılmış bir proje yok.\nSiz ilk gönderiyi oluşturarak\ntoplulukta iz bırakın!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModernButton(
                  onPressed: _navigateToCreatePost,
                  icon: Icons.add_rounded,
                  label: 'İlk Gönderiyi Oluştur',
                  isPrimary: true,
                  theme: theme,
                ),
                const SizedBox(width: 16),
                _buildModernButton(
                  onPressed: () => provider.fetchPosts(),
                  icon: Icons.refresh_rounded,
                  label: 'Yenile',
                  isPrimary: false,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? theme.primaryColor
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          foregroundColor: isPrimary
              ? Colors.white
              : theme.primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(
              color: theme.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList(ShowcaseProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if (index == provider.posts.length) {
              return _buildLoadMoreIndicator();
            }

            final post = provider.posts[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 16),
              child: PostCard(post: post),
            );
          },
          childCount: provider.posts.length + (provider.hasMorePosts ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Daha fazla proje yükleniyor...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_showScrollToTop)
          ScaleTransition(
            scale: _fabAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                onPressed: _scrollToTop,
                backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                foregroundColor: theme.primaryColor,
                heroTag: "scroll_to_top",
                elevation: 0,
                child: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
            ),
          ),
        ScaleTransition(
          scale: _fabAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _navigateToCreatePost,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              heroTag: "create_post",
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text(
                'Gönderi Oluştur',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const CreatePostScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;

          var slideAnimation = Tween(begin: begin, end: end).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.tune, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Filtreler',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 48,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtreleme Özellikleri',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kategori, teknoloji ve popülerlik filtreleri yakında eklenecek!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _buildModernButton(
              onPressed: () => Navigator.pop(context),
              icon: Icons.close_rounded,
              label: 'Kapat',
              isPrimary: true,
              theme: theme,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}