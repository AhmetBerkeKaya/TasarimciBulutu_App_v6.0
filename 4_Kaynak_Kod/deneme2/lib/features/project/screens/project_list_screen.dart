// lib/features/project/screens/project_list_screen.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
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
    // Ekran açıldığında hem normal projeleri hem de önerilenleri çek
    Future.microtask(() {
      final provider = context.read<ProjectProvider>();
      provider.fetchOpenProjects();
      provider.fetchRecommendedProjects();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Sadece arama sorgusunu uygula, diğer filtreler kalsın
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
    _searchController.removeListener(_onSearchChanged); // removeListener eklemek iyi bir pratiktir
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // project_list_screen.dart - Responsive düzeltmeler

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje İlanları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrele',
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => FilterSheet(currentSearchQuery: _searchController.text),
              isScrollControlled: true,
            ),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await projectProvider.fetchOpenProjects();
              await projectProvider.fetchRecommendedProjects();
            },
            child: CustomScrollView(
              slivers: [
                // Arama kutusu - responsive padding
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        MediaQuery.of(context).size.width * 0.04, // Responsive left padding
                        MediaQuery.of(context).size.width * 0.04, // Responsive top padding
                        MediaQuery.of(context).size.width * 0.04, // Responsive right padding
                        MediaQuery.of(context).size.width * 0.02  // Responsive bottom padding
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Proje başlığı veya açıklaması ara...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive font size
                      ),
                    ),
                  ),
                ),

                // --- ÖNERİLENLER BÖLÜMÜ (GÜNCELLENDİ) ---
                if (projectProvider.isRecommendationsLoading)
                  const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))),

                if (!projectProvider.isRecommendationsLoading && projectProvider.recommendedProjects.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text("Sizin İçin Önerilenler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 190, // Yeni kartın yüksekliğine göre ayarlandı
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            itemCount: projectProvider.recommendedProjects.length,
                            itemBuilder: (context, index) {
                              final project = projectProvider.recommendedProjects[index];
                              // YENİ KART WIDGET'INI KULLANIYORUZ
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
                        const Divider(height: 32, indent: 16, endIndent: 16),
                      ],
                    ),
                  ),
                // TÜM PROJELER BÖLÜMÜ
                if (projectProvider.isLoading && projectProvider.allOpenProjects.isEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.04,
                            vertical: MediaQuery.of(context).size.width * 0.02
                        ),
                        child: const ProjectCardSkeleton(),
                      ),
                      childCount: 5,
                    ),
                  )
                else if (projectProvider.allOpenProjects.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.search_off,
                      message: 'Aktif proje ilanı bulunamadı.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final project = projectProvider.allOpenProjects[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.04,
                              vertical: MediaQuery.of(context).size.width * 0.02
                          ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}