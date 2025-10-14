import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/project_model.dart';
import '../../project/widgets/project_card.dart';
import '../../project/screens/project_detail_screen.dart';
import '../../project/screens/create_project_screen.dart'; // <-- Proje oluşturma ekranını import et

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProjectProvider>(context, listen: false).fetchMyProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthProvider>().user?.role;
    final projectProvider = context.watch<ProjectProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Projelerim Paneli'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'AKTİF'),
              Tab(text: 'İNCELEMEDE'),
              Tab(text: 'TAMAMLANMIŞ'),
            ],
          ),
        ),
        body: Consumer<ProjectProvider>(
          builder: (context, projectProvider, child) {
            // ... (builder'ın içi aynı)
            if (projectProvider.isLoading && projectProvider.myActiveProjects.isEmpty) {
              return const LoadingIndicator();
            }
            if (projectProvider.errorMessage != null) {
              return Center(child: Text(projectProvider.errorMessage!));
            }

            return TabBarView(
              children: [
                _buildProjectList(context, projects: projectProvider.myActiveProjects, userRole: userRole),
                _buildProjectList(context, projects: projectProvider.myPendingReviewProjects, userRole: userRole),
                _buildProjectList(context, projects: projectProvider.myCompletedProjects, userRole: userRole),
              ],
            );
          },
        ),
        // --- YENİ EKLENEN BUTON ---
        floatingActionButton: (userRole == UserRole.client)
            ? FloatingActionButton.extended(
          onPressed: () async {
            // Proje oluşturma ekranına git
            final bool? projectCreated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
            );

            // Eğer proje oluşturma ekranından 'true' değeriyle dönülürse
            // (yani proje başarıyla oluşturulduysa), paneldeki proje listesini yenile.
            if (projectCreated == true && context.mounted) {
              projectProvider.fetchMyProjects();
            }
          },
          label: const Text('Proje Yayınla'),
          icon: const Icon(Icons.add),
        )
            : null, // Eğer kullanıcı firma değilse, butonu gösterme
        // --- BİTTİ ---
      ),
    );
  }

  // _buildProjectList ve _buildActionButton fonksiyonları aynı kalacak
  // ...
  Widget _buildProjectList(BuildContext context, {
    required List<Project> projects,
    required UserRole? userRole,
  }) {
    if (projects.isEmpty) {
      return const Center(child: Text('Bu kategoride projeniz bulunmuyor.'));
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ProjectProvider>().fetchMyProjects(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: projects.length,
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

    if (userRole == UserRole.freelancer && project.status == ProjectStatus.in_progress) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.send_and_archive_outlined),
        label: const Text('İşi Teslim Et'),
        onPressed: () => projectProvider.deliverProject(project.id),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent),
      );
    }
    if (userRole == UserRole.client && project.status == ProjectStatus.pending_review) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Revizyon İste'),
            onPressed: () => projectProvider.requestRevision(project.id),
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
          ),
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Onayla'),
            onPressed: () => projectProvider.acceptDelivery(project.id),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      );
    }
    return null;
  }
}