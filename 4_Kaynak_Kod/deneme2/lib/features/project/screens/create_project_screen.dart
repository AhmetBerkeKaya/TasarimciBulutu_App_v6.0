// lib/features/projects/screens/create_project_screen.dart
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/skill_model.dart'; // ApiService'i import et

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _deadlineController = TextEditingController();

  DateTime? _selectedDeadline;

  List<Skill> _allSkills = [];
  final List<Skill> _selectedSkills = [];
  bool _skillsLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchSkills();
  }
  Future<void> _fetchSkills() async {
    try {
      final skills = await _apiService.getSkills();
      if (mounted) {
        setState(() {
          _allSkills = skills;
          _skillsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _skillsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetenekler yüklenemedi.')),
        );
      }
    }
  }
  Future<void> _submitProject() async {
    if (_formKey.currentState!.validate()) {
      final selectedSkillIds = _selectedSkills.map((skill) => skill.id).toList();

      // DİKKAT: Artık ApiService yerine Provider'ı çağırıyoruz.
      final success = await Provider.of<ProjectProvider>(context, listen: false).createProject(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        budgetMin: int.tryParse(_budgetMinController.text),
        budgetMax: int.tryParse(_budgetMaxController.text),
        deadline: _selectedDeadline,
        skillIds: selectedSkillIds,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Proje başarıyla yayınlandı!' : 'Proje oluşturulurken bir hata oluştu.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        // Başarılı olursa bir önceki sayfaya (proje listesine) dön
        Navigator.of(context).pop();
      }
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      // Tarih seçiciyi de Türkçeleştirebiliriz
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        // 'tr_TR' parametresinin burada olması kritik
        _deadlineController.text = DateFormat('dd MMMM yyyy', 'tr_TR').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Proje Yayınla')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Proje Başlığı'),
                validator: (value) => value!.isEmpty ? 'Lütfen bir başlık girin.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (value) => value!.isEmpty ? 'Lütfen bir kategori belirtin.' : null,
              ),
              const SizedBox(height: 16),
              // --- YENİ YETENEK SEÇİM ALANI ---
              DropdownSearch<Skill>.multiSelection(
                items: _allSkills,
                itemAsString: (Skill s) => s.name, // Listede nasıl görünecek
                selectedItems: _selectedSkills,
                onChanged: (List<Skill> skills) {
                  setState(() {
                    _selectedSkills.clear();
                    _selectedSkills.addAll(skills);
                  });
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Gerekli Yetenekler",
                    hintText: "Proje için gerekli yetenekleri seçin",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                popupProps: PopupPropsMultiSelection.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: "Yetenek ara...",
                    ),
                  ),
                ),
                validator: (List<Skill>? items) {
                  if (items == null || items.isEmpty) {
                    return "En az bir yetenek seçmelisiniz.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Proje Açıklaması', alignLabelWithHint: true),
                maxLines: 6,
                validator: (value) => value!.isEmpty ? 'Lütfen proje detaylarını açıklayın.' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMinController,
                      decoration: const InputDecoration(labelText: 'Minimum Bütçe (₺)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMaxController,
                      decoration: const InputDecoration(labelText: 'Maksimum Bütçe (₺)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Son Başvuru Tarihi (İsteğe Bağlı)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                // Yüklenme durumunu artık provider'dan dinliyoruz
                onPressed: projectProvider.isLoading ? null : _submitProject,
                child: projectProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PROJEYİ YAYINLA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}