// lib/features/showcase/screens/showcase_feed_screen.dart

import 'dart:async';
import 'dart:ui'; // Glass effect için gerekli
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';

// Modeller ve Enumlar
import '../../../data/models/enums.dart';

// Providerlar
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../core/providers/notification_provider.dart';

// Ekranlar ve Widgetlar
import '../../notifications/screens/notification_screen.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class ShowcaseFeedScreen extends StatefulWidget {
  const ShowcaseFeedScreen({super.key});

  @override
  State<ShowcaseFeedScreen> createState() => _ShowcaseFeedScreenState();
}

class _ShowcaseFeedScreenState extends State<ShowcaseFeedScreen>
    with TickerProviderStateMixin {
  // Controllerlar
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Animasyon Controllerları
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _searchAnimationController;

  // Animasyon Değerleri
  late Animation<double> _fabAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _searchAnimation;

  // State Değişkenleri
  bool _showScrollToTop = false;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  Timer? _debounce;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialData();
    _scrollController.addListener(_onScroll);

    // --- BİLDİRİM SİSTEMİ ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationsSafe();
    });

    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkNotificationsSafe();
      }
    });
  }

  void _checkNotificationsSafe() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
    }
  }

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

  void _setupInitialData() {
    Future.microtask(() {
      final provider = Provider.of<ShowcaseProvider>(context, listen: false);
      _searchController.text = provider.searchQuery;

      if (provider.state == ShowcaseState.initial) {
        provider.fetchPosts();
      }
      _headerAnimationController.forward();
      _fabAnimationController.forward();
    });
  }

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

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    _searchController.clear();
    await Provider.of<ShowcaseProvider>(context, listen: false).searchPosts('');
    _checkNotificationsSafe();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutQuart,
    );
  }

  void _toggleSearch() {
    setState(() => _isSearchExpanded = !_isSearchExpanded);

    if (_isSearchExpanded) {
      _searchAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) FocusScope.of(context).requestFocus(FocusNode());
      });
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      Provider.of<ShowcaseProvider>(context, listen: false).searchPosts('');
      FocusScope.of(context).unfocus();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<ShowcaseProvider>(context, listen: false).searchPosts(query);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _searchAnimationController.dispose();
    _debounce?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- YENİ RENK PALETİ ---
    final backgroundColor = isDark ? const Color(0xFF181A20) : const Color(0xFFF0F2F5);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: isDark ? Colors.white : Colors.black, // Monokrom loader
        backgroundColor: isDark ? const Color(0xFF262A35) : Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernAppBar(theme, isDark, backgroundColor),
            _buildSearchBar(theme, isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _buildContent(),
            const SliverToBoxAdapter(child: SizedBox(height: 150)), // Alttan daha fazla boşluk
          ],
        ),
      ),
      floatingActionButton: isKeyboardVisible ? null : _buildFloatingActionButtons(theme, isDark),
      // Butonu ekranın sağına yasla
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // --- MODERN APP BAR ---
  Widget _buildModernAppBar(ThemeData theme, bool isDark, Color bgColor) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 10),
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.auto_awesome, color: primaryColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proje Vitrini',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'İlham veren tasarımlar',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: secondaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
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
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return badges.Badge(
              showBadge: notificationProvider.unreadCount > 0,
              badgeContent: Text(
                notificationProvider.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: badges.BadgeStyle(
                badgeColor: isDark ? const Color(0xFFFF5252) : const Color(0xFFEF4444),
              ),
              child: _buildGlassActionButton(
                icon: Icons.notifications_none_rounded,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ));
                },
                isDark: isDark,
              ),
            );
          },
        ),

        _buildGlassActionButton(
          icon: _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
          onPressed: _toggleSearch,
          isDark: isDark,
        ),

        _buildGlassActionButton(
          icon: Icons.tune_rounded,
          onPressed: _showFilterBottomSheet,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 22),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  // --- MODERN SEARCH BAR ---
  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        height: _isSearchExpanded ? 80 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: SizeTransition(
          sizeFactor: _searchAnimation,
          axisAlignment: -1.0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262A35) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Proje veya tasarımcı ara...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontWeight: FontWeight.w500
                ),
                prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.grey[400] : const Color(0xFF0F172A)
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            return SliverFillRemaining(child: _buildLoadingState());

          case ShowcaseState.error:
            return SliverFillRemaining(child: _buildErrorState(provider));

          case ShowcaseState.loaded:
          case ShowcaseState.loadingMore:
            if (provider.posts.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: provider.searchQuery.isNotEmpty
                      ? _buildEmptySearchState(provider)
                      : _buildEmptyState(provider),
                ),
              );
            }
            return _buildPostsList(provider);
        }
      },
    );
  }

  Widget _buildEmptySearchState(ShowcaseProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '"${provider.searchQuery}" bulunamadı',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              provider.searchPosts('');
            },
            child: const Text('Aramayı Temizle'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ShowcaseProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_mosaic_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'Henüz hiç proje yok',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk paylaşan sen olabilirsin!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add),
            label: const Text('Proje Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
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
              duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
              curve: Curves.easeOut,
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
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }

  Widget _buildErrorState(ShowcaseProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(provider.errorMessage ?? 'Bir hata oluştu'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => provider.fetchPosts(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  // --- DÜZELTİLEN KISIM: FAB PADDING ---
  Widget? _buildFloatingActionButtons(ThemeData theme, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user?.role == UserRole.client || authProvider.user == null) {
      return null;
    }

    final fabBgColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final fabTextColor = isDark ? Colors.black : Colors.white;

    // BURAYA PADDING EKLEDİM (BOTTOM 110PX)
    return Padding(
      padding: const EdgeInsets.only(bottom: 110.0), // Barı kurtarmak için yukarı ittik
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showScrollToTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton.small(
                onPressed: _scrollToTop,
                backgroundColor: isDark ? const Color(0xFF262A35) : Colors.white,
                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                heroTag: "scroll_top",
                elevation: 4,
                child: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
            ),

          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: _navigateToCreatePost,
              backgroundColor: fabBgColor,
              foregroundColor: fabTextColor,
              elevation: 8,
              heroTag: "create_post",
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Gönderi Oluştur',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ShowcaseFilterSheet(),
    );
  }
}