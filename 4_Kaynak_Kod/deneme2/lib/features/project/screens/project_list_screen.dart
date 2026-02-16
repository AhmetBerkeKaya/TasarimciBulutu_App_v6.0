// lib/features/project/screens/project_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Bileşenler
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/project_card_skeleton.dart';
import '../../../core/providers/project_provider.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/project_card.dart';
import '../widgets/recommended_project_card.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<ProjectProvider>();
      provider.clearFiltersAndFetch();
      provider.fetchRecommendedProjects();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final provider = context.read<ProjectProvider>();
      provider.applyFiltersAndFetch(
        searchQuery: _searchController.text,
        category: provider.activeCategory,
        minBudget: provider.activeMinBudget,
        maxBudget: provider.activeMaxBudget,
        sortBy: provider.activeSortBy,
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Modern Renkler
    final bgColor = isDark ? const Color(0xFF181A20) : const Color(0xFFF0F2F5);
    final searchBgColor = isDark ? const Color(0xFF262A35) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          return RefreshIndicator(
            color: isDark ? Colors.white : Colors.black,
            backgroundColor: isDark ? const Color(0xFF262A35) : Colors.white,
            onRefresh: () async {
              await projectProvider.fetchOpenProjects();
              await projectProvider.fetchRecommendedProjects();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. MODERN APP BAR (SLIVER)
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: bgColor,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                    centerTitle: false,
                    title: Text(
                      'Proje İlanları',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.tune_rounded, color: primaryTextColor),
                        tooltip: 'Filtrele',
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FilterSheet(currentSearchQuery: _searchController.text),
                          isScrollControlled: true,
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. ARAMA ÇUBUĞU (YÜZEN)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: searchBgColor,
                        borderRadius: BorderRadius.circular(16),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Proje başlığı veya açıklama...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark ? Colors.grey[400] : const Color(0xFF0F172A)
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. ÖNERİLENLER BÖLÜMÜ
                if (projectProvider.isRecommendationsLoading)
                  const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))),

                if (!projectProvider.isRecommendationsLoading && projectProvider.recommendedProjects.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 18, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                "Sizin İçin Önerilenler",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200, // Kart yüksekliği
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            itemCount: projectProvider.recommendedProjects.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final project = projectProvider.recommendedProjects[index];
                              return RecommendedProjectCard(
                                project: project,
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ProjectDetailScreen(project: project),
                                  ));
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Divider(height: 1, indent: 24, endIndent: 24, color: isDark ? Colors.white10 : Colors.grey[200]),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                // 4. TÜM PROJELER BAŞLIĞI
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      "Tüm İlanlar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ),

                // 5. PROJE LİSTESİ
                if (projectProvider.isLoading && projectProvider.allOpenProjects.isEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: const ProjectCardSkeleton(),
                      ),
                      childCount: 5,
                    ),
                  )
                else if (projectProvider.allOpenProjects.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      message: 'Aradığınız kriterlere uygun proje bulunamadı.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final project = projectProvider.allOpenProjects[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: ProjectCard(
                            project: project,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProjectDetailScreen(project: project),
                              ));
                            },
                          ),
                        );
                      },
                      childCount: projectProvider.allOpenProjects.length,
                    ),
                  ),

                // 6. ALT BOŞLUK (Nav Bar için)
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}