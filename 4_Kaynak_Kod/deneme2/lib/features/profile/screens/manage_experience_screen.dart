import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'add_experience_screen.dart';

class ManageExperienceScreen extends StatelessWidget {
  const ManageExperienceScreen({super.key});

  // --- YENİ: Onay dialogu ile güvenli silme ---
  Future<void> _deleteExperience(BuildContext context, String experienceId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silmeyi Onayla'),
        content: Text('"$title" pozisyonunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteWorkExperience(experienceId);
      if (!context.mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız oldu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final experiences = authProvider.user?.workExperiences ?? [];
        final formatter = DateFormat('MM/yyyy');

        return Scaffold(
          appBar: AppBar(
            title: const Text('İş Deneyimini Yönet'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Yeni Deneyim Ekle',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AddExperienceScreen(),
                )),
              ),
            ],
          ),
          body: experiences.isEmpty
              ? const Center(child: Text('Henüz iş deneyimi eklenmemiş.'))
              : ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: experiences.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final exp = experiences[index];
              final period =
                  '${formatter.format(exp.startDate)} - ${exp.endDate != null ? formatter.format(exp.endDate!) : 'Devam Ediyor'}';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.work_history_outlined, size: 40),
                  title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${exp.companyName}\n$period'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AddExperienceScreen(experienceToEdit: exp),
                        )),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteExperience(context, exp.id, exp.title),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}