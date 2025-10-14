import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../common_widgets/status_chip.dart';
import '../../../core/providers/application_provider.dart' show ApplicationProvider;
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_summary_model.dart';
import '../../messages/screens/chat_screen.dart';
import '../widgets/application_detail_dialog.dart';
class ProjectApplicantsScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ProjectApplicantsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectApplicantsScreen> createState() => _ProjectApplicantsScreenState();
}

class _ProjectApplicantsScreenState extends State<ProjectApplicantsScreen> {
  // Future'ı nullable yapıp initState içinde dolduruyoruz
  Future<List<Application>>? _applicantsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // initState içinde sadece Future'ı başlatıyoruz, setState yok.
    _loadApplicants();
  }

  void _loadApplicants() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _applicantsFuture = _apiService.getApplicationsForProject(
        projectId: widget.projectId,
      );
    } else {
      _applicantsFuture = Future.value([]);
    }
  }

  void _onStatusUpdate() {
    // Bir başvurunun durumu güncellendiğinde, listeyi yenilemek için
    // Future'ı yeniden oluşturup setState çağırıyoruz.
    setState(() {
      _loadApplicants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('"${widget.projectTitle}" Gelen Başvurular'),
      ),
      body: FutureBuilder<List<Application>>(
        future: _applicantsFuture,
        builder: (context, snapshot) {
          // Yükleniyor durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          // Hata durumu
          if (snapshot.hasError) {
            return const Center(child: Text('Başvurular yüklenirken bir hata oluştu.'));
          }
          // Boş liste durumu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.person_search_sharp,
              message: 'Bu Projeye Henüz Başvuru Yok',
            );
          }

          // Başarılı durum
          final applicants = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(child: Text(applicant.freelancer.name.substring(0, 1))),
                  title: Text(applicant.freelancer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Teklifi: ${applicant.proposedBudget?.toStringAsFixed(0) ?? 'N/A'} ₺'),
                  trailing: StatusChip(status: applicant.status),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ApplicationDetailDialog(
                          application: applicant,
                          onAccept: () => _updateStatus(applicant.id, ApplicationStatus.accepted),
                          onReject: () => _updateStatus(applicant.id, ApplicationStatus.rejected),
                          onSendMessage: () => _openChat(applicant.freelancer),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // update ve openChat fonksiyonları _ProjectApplicantsScreenState içinde olmalı
  void _updateStatus(String applicationId, ApplicationStatus status) async {
    // Arayüzde anlık bir yüklenme göstergesi göster
    showDialog(context: context, barrierDismissible: false, builder: (_) => const PopScope(canPop: false, child: LoadingIndicator()));

    // --- DEĞİŞİKLİK: Doğrudan ApiService yerine Provider'ı kullan ---
    final success = await context.read<ApplicationProvider>().updateApplicationStatus(
        applicationId: applicationId,
        newStatus: status
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Yüklenme göstergesini kapat

    if (success) {
      // --- ÖNEMLİ DEĞİŞİKLİK ---
      // Proje durumunu da yenilemek için ProjectProvider'ı tetikle
      context.read<ProjectProvider>().fetchMyProjects();

      // Başvuru listesini de yenile
      _onStatusUpdate();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Durum güncellenirken bir hata oluştu.')));
    }
  }

  void _openChat(UserSummary otherUser) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(otherUser: otherUser)));
  }
}