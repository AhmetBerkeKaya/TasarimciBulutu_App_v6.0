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
    final isDark = theme.brightness == Brightness.dark;

    // Premium Renkler
    final bgColor = isDark ? const Color(0xFF181A20) : const Color(0xFFF0F2F5);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Panelim',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            height: 50,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Manrope'),
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
            return const Center(child: LoadingIndicator());
          }
          if (projectProvider.errorMessage != null) {
            return _buildErrorState(projectProvider.errorMessage!, isDark);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProjectList(context, projects: projectProvider.myActiveProjects, userRole: userRole, emptyMessage: "Henüz aktif bir projeniz yok.", isDark: isDark),
              _buildProjectList(context, projects: projectProvider.myPendingReviewProjects, userRole: userRole, emptyMessage: "İnceleme bekleyen proje yok.", isDark: isDark),
              _buildProjectList(context, projects: projectProvider.myCompletedProjects, userRole: userRole, emptyMessage: "Tamamlanan projeniz bulunmuyor.", isDark: isDark),
            ],
          );
        },
      ),

      // --- FAB (BUTON) DÜZELTİLDİ ---
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (userRole == UserRole.client)
          ? Padding(
        padding: const EdgeInsets.only(bottom: 110.0), // <-- BARIN ÜSTÜNE ALDIK
        child: FloatingActionButton.extended(
          onPressed: () async {
            final bool? projectCreated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
            );

            if (projectCreated == true && context.mounted) {
              context.read<ProjectProvider>().fetchMyProjects();
            }
          },
          backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A), // Premium Siyah/Beyaz
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 8,
          label: const Text('Proje Yayınla', style: TextStyle(fontWeight: FontWeight.w800)),
          icon: const Icon(Icons.add_rounded),
        ),
      )
          : null,
    );
  }

  Widget _buildProjectList(BuildContext context, {
    required List<Project> projects,
    required UserRole? userRole,
    required String emptyMessage,
    required bool isDark,
  }) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 100), // Alt boşluk
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: isDark ? Colors.white : Colors.black,
      backgroundColor: isDark ? const Color(0xFF262A35) : Colors.white,
      onRefresh: () => context.read<ProjectProvider>().fetchMyProjects(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 150), // Alttan ekstra boşluk (Liste sonu için)
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    if (userRole == UserRole.client && project.status == ProjectStatus.pending_review) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Revizyon'),
              onPressed: () => _showRevisionDialog(context, project.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Onayla'),
              onPressed: () => projectProvider.acceptDelivery(project.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRevisionDialog(BuildContext context, String projectId) {
    final reasonController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Revizyon Talebi', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Düzeltilmesini istediğiniz noktaları açıklayın:',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Örn: Renkler logoyla uyuşmuyor...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context);
                context.read<ProjectProvider>().requestRevision(projectId, reason);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Revizyon talebi iletildi."), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen bir açıklama girin."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}