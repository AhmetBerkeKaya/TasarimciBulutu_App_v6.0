// lib/features/applications/screens/my_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/application_provider.dart';
import '../../../data/models/enums.dart';
import '../../messages/screens/chat_screen.dart';
import '../widgets/application_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açıldığında verilerin güncel olduğundan emin olmak için
    // Provider'ı tetikleyebiliriz. Provider zaten token varsa kendi yüklüyor
    // ama yine de güvence olarak eklenebilir.
    Future.microtask(() {
      Provider.of<ApplicationProvider>(context, listen: false).fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başvurularım'),
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, appProvider, child) {
          // Önce yüklenme durumunu kontrol et
          if (appProvider.isLoading && appProvider.myApplications.isEmpty) {
            return const LoadingIndicator();
          }

          // Sonra hata durumunu kontrol et
          if (appProvider.errorMessage != null) {
            return Center(child: Text(appProvider.errorMessage!));
          }

          // Sonra listenin boş olup olmadığını kontrol et
          if (appProvider.myApplications.isEmpty) {
            return const EmptyState(
              icon: Icons.file_copy_outlined,
              message: 'Henüz Başvurunuz Yok',
              suggestion: 'Projelere başvurduğunuzda burada listelenecektir.',
            );
          }

          // Her şey yolundaysa listeyi göster
          return RefreshIndicator(
            onRefresh: () => appProvider.fetchMyApplications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appProvider.myApplications.length,
              itemBuilder: (context, index) {
                final app = appProvider.myApplications[index];
                final bool isAccepted = app.status == ApplicationStatus.accepted;

                return ApplicationCard(
                  projectTitle: app.project.title,
                  companyName: app.project.owner.name,
                  status: app.status,
                  appliedDate: app.createdAt,
                  onTap: isAccepted
                      ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(otherUser: app.project.owner),
                      ),
                    );
                  }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}