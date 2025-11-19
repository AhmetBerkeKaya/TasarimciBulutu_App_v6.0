import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../data/models/project_model.dart';

class ProjectEditScreen extends StatefulWidget {
  final Project project;
  const ProjectEditScreen({super.key, required this.project});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetMinController;
  late TextEditingController _budgetMaxController;
  late TextEditingController _deadlineController;

  String? _selectedCategory;
  DateTime? _selectedDeadline;

  // Backend Enum ile birebir aynı liste
  final List<String> _categories = [
    "Mimari Tasarım ve Projelendirme",
    "İç Mimarlık ve Dekorasyon",
    "Peyzaj Mimarlığı ve Çevre Düzenleme",
    "İnşaat ve Yapı Mühendisliği",
    "Makine ve Mekanik Tasarım",
    "Elektrik ve Elektronik Mühendisliği",
    "MEP (Mekanik, Elektrik, Tesisat)",
    "Endüstriyel Tasarım ve Ürün Geliştirme",
    "Kalıp Tasarımı ve İmalat",
    "Otomotiv ve Taşıt Tasarımı",
    "Havacılık ve Uzay Sanayi",
    "Gemi İnşaatı ve Denizcilik",
    "Borulama ve Tesisat Tasarımı",
    "BIM (Yapı Bilgi Modellemesi)",
    "3D Görselleştirme ve Render",
    "Animasyon ve Hareketli Grafik",
    "Yazılım Geliştirme (Web/Mobil/Masaüstü)",
    "Gömülü Sistemler ve IoT",
    "Yapay Zeka ve Makine Öğrenmesi",
    "Oyun Tasarımı ve Geliştirme",
    "Kullanıcı Arayüzü ve Deneyimi (UI/UX)",
    "Grafik Tasarım ve Markalama",
    "Harita ve Kadastro Mühendisliği",
    "Enerji Sistemleri Mühendisliği"
  ];

  @override
  void initState() {
    super.initState();
    // Mevcut verileri controller'lara yükle
    _titleController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(text: widget.project.description);
    _budgetMinController = TextEditingController(text: widget.project.budgetMin?.toString() ?? '');
    _budgetMaxController = TextEditingController(text: widget.project.budgetMax?.toString() ?? '');

    // Kategori kontrolü (Eğer listede varsa seç, yoksa null)
    if (_categories.contains(widget.project.category)) {
      _selectedCategory = widget.project.category;
    }

    // Tarih kontrolü
    if (widget.project.deadline != null) {
      _selectedDeadline = widget.project.deadline;
      _deadlineController = TextEditingController(
          text: DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.project.deadline!));
    } else {
      _deadlineController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => DatePickerDialog(
        initialDate: _selectedDeadline ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
      ),
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('dd MMMM yyyy', 'tr_TR').format(picked);
      });
    }
  }

  Future<void> _submitChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir kategori seçin.'), backgroundColor: Colors.red),
        );
        return;
      }

      final success = await Provider.of<ProjectProvider>(context, listen: false).updateProject(
        projectId: widget.project.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        budgetMin: int.tryParse(_budgetMinController.text),
        budgetMax: int.tryParse(_budgetMaxController.text),
        deadline: _selectedDeadline,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proje başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Başarılı olduğunu belirtmek için true dön
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncelleme sırasında hata oluştu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProjectProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Projeyi Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Proje Başlığı', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Başlık boş olamaz' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder(), alignLabelWithHint: true),
                validator: (value) => value!.isEmpty ? 'Açıklama boş olamaz' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Bütçe (₺)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Bütçe (₺)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Son Başvuru Tarihi',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isLoading ? null : _submitChanges,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('DEĞİŞİKLİKLERİ KAYDET'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}