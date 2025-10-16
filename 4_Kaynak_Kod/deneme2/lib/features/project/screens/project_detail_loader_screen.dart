// lib/features/project/screens/project_detail_loader_screen.dart

import 'package:flutter/material.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/project_model.dart';
import 'project_detail_screen.dart';

class ProjectDetailLoaderScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailLoaderScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailLoaderScreen> createState() => _ProjectDetailLoaderScreenState();
}

class _ProjectDetailLoaderScreenState extends State<ProjectDetailLoaderScreen> {
  late Future<Project?> _projectFuture;

  @override
  void initState() {
    super.initState();
    // ApiService'ten proje detaylarını çekmek için Future'ı başlat
    _projectFuture = ApiService().getProjectById(projectId: widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Project?>(
      future: _projectFuture,
      builder: (context, snapshot) {
        // Veri yüklenirken
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingIndicator());
        }

        // Hata oluştuğunda veya veri gelmediğinde
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.error_outline,
              message: 'Proje Yüklenemedi',
              suggestion: 'Aradığınız proje bulunamadı veya bir hata oluştu.',
            ),
          );
        }

        // Veri başarıyla geldiğinde, asıl ekranı bu veriyle oluştur
        final project = snapshot.data!;
        return ProjectDetailScreen(project: project);
      },
    );
  }
}