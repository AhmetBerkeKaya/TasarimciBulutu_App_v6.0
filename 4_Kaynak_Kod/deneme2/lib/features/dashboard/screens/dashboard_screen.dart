// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/project_model.dart';
import '../../project/widgets/project_card.dart';
import '../../project/screens/project_detail_screen.dart';
import '../../project/screens/create_project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      Provider.of<ProjectProvider>(context, listen: false).fetchMyProjects();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = context.watch<AuthProvider>().user?.role;
    final projectProvider = context.watch<ProjectProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
            'Panelim',
            style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground
            )
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 50, // Yüksekliği biraz artırdık, daha rahat görünsün
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4), // Dış çerçeve ile içteki sekmeler arasına boşluk
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16), // Köşeleri yuvarladık
            ),
            child: TabBar(
              controller: _tabController,
              // --- KRİTİK DÜZELTME BURADA ---
              indicatorSize: TabBarIndicatorSize.tab, // İndikatörün tüm sekmeyi kaplamasını sağlar
              // ------------------------------
              indicator: BoxDecoration(
                  color: theme.primaryColor, // Ana renk (Mavi)
                  borderRadius: BorderRadius.circular(12), // İçteki seçili alanın köşeleri
                  boxShadow: [
                    BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2)
                    )
                  ]
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(12),
              tabs: const [
                Tab(text: 'AKTİF'),
                Tab(text: 'İNCELEMEDE'),
                Tab(text: 'BİTENLER'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          if (projectProvider.isLoading && projectProvider.myActiveProjects.isEmpty) {
            return const LoadingIndicator();
          }
          if (projectProvider.errorMessage != null) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(projectProvider.errorMessage!, style: theme.textTheme.bodyLarge),
                  ],
                )
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProjectList(context, projects: projectProvider.myActiveProjects, userRole: userRole, emptyMessage: "Henüz aktif bir projeniz yok."),
              _buildProjectList(context, projects: projectProvider.myPendingReviewProjects, userRole: userRole, emptyMessage: "İnceleme bekleyen proje yok."),
              _buildProjectList(context, projects: projectProvider.myCompletedProjects, userRole: userRole, emptyMessage: "Tamamlanan projeniz bulunmuyor."),
            ],
          );
        },
      ),
      floatingActionButton: (userRole == UserRole.client)
          ? FloatingActionButton.extended(
        onPressed: () async {
          final bool? projectCreated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
          );

          if (projectCreated == true && context.mounted) {
            projectProvider.fetchMyProjects();
          }
        },
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text('Proje Yayınla', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
      )
          : null,
    );
  }

  Widget _buildProjectList(BuildContext context, {
    required List<Project> projects,
    required UserRole? userRole,
    required String emptyMessage,
  }) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: Theme.of(context).disabledColor.withOpacity(0.5)
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () => context.read<ProjectProvider>().fetchMyProjects(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: projects.length,
        separatorBuilder: (ctx, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final project = projects[index];
          return ProjectCard(
            project: project,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ProjectDetailScreen(project: project),
              ));
            },
            actionButton: _buildActionButton(context, project, userRole),
          );
        },
      ),
    );
  }

  Widget? _buildActionButton(BuildContext context, Project project, UserRole? userRole) {
    final projectProvider = context.read<ProjectProvider>();
    final theme = Theme.of(context);

    if (userRole == UserRole.freelancer && project.status == ProjectStatus.in_progress) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('İşi Teslim Et'),
          onPressed: () => projectProvider.deliverProject(project.id),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.primaryColor,
            side: BorderSide(color: theme.primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    if (userRole == UserRole.client && project.status == ProjectStatus.pending_review) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_note, size: 18),
              label: const Text('Revizyon'),
              onPressed: () => _showRevisionDialog(context, project.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Onayla'),
              onPressed: () => projectProvider.acceptDelivery(project.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
    return null;
  }

  void _showRevisionDialog(BuildContext context, String projectId) {
    final reasonController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revizyon Talebi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Düzeltilmesini istediğiniz noktaları açıklayın:',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Örn: Renkler logoyla uyuşmuyor...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context);
                context.read<ProjectProvider>().requestRevision(projectId, reason);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Revizyon talebi iletildi."), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text("Lütfen bir açıklama girin."), backgroundColor: theme.colorScheme.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}