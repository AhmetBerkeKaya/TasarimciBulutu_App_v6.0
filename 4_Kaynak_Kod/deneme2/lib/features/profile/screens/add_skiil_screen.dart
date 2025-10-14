// lib/features/profile/screens/add_skill_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/skill_model.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  late Future<List<Skill>> _skillsFuture;
  final ApiService _apiService = ApiService();
  // Yüklenme durumunu yönetmek için
  final Set<String> _loadingSkills = {};

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _skillsFuture = _apiService.getAvailableSkills();
  }

  Future<void> _addSkill(String skillId) async {
    setState(() => _loadingSkills.add(skillId)); // Yükleniyor durumunu başlat

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.addSkillToUser(skillId);

    if (!mounted) return;

    // Yükleniyor durumunu bitir
    setState(() => _loadingSkills.remove(skillId));

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hata oluştu.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yetenek Ekle')),
      body: FutureBuilder<List<Skill>>(
        future: _skillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Eklenecek yetenek bulunamadı.'));
          }
          final allSkills = snapshot.data!;
          // Anlık güncellemeyi görmek için Consumer kullanıyoruz
          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final mySkillIds = authProvider.user?.skills.map((s) => s.id).toSet() ?? {};
              return ListView.builder(
                itemCount: allSkills.length,
                itemBuilder: (context, index) {
                  final skill = allSkills[index];
                  final bool alreadyAdded = mySkillIds.contains(skill.id);
                  final bool isLoading = _loadingSkills.contains(skill.id);

                  return ListTile(
                    title: Text(skill.name),
                    trailing: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                      icon: Icon(
                        alreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                        color: alreadyAdded ? Colors.green : null,
                      ),
                      onPressed: alreadyAdded ? null : () => _addSkill(skill.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}