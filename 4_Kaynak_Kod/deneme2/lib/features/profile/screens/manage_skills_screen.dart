// lib/features/profile/screens/manage_skills_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'add_skiil_screen.dart';

class ManageSkillsScreen extends StatelessWidget {
  const ManageSkillsScreen({super.key});

  void _removeSkill(BuildContext context, String skillId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.removeSkill(skillId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Yetenek kaldırıldı.' : 'İşlem başarısız oldu.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Değişiklikleri anında görmek için Consumer kullanıyoruz
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final skills = authProvider.user?.skills ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Yetenekleri Yönet'),
            actions: [
              // Yeni yetenek ekleme ekranına yönlendiren buton
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Yeni Yetenek Ekle',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AddSkillScreen()),
                  );
                },
              ),
            ],
          ),
          body: skills.isEmpty
              ? const Center(child: Text('Henüz yetenek eklenmemiş.'))
              : ListView.separated(
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return ListTile(
                title: Text(skill.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeSkill(context, skill.id),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        );
      },
    );
  }
}