// lib/features/projects/screens/create_project_screen.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/skill_model.dart';

// Kategoriler Listesi (Sabit)
const List<String> _categories = [
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

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _deadlineController = TextEditingController();

  DateTime? _selectedDeadline;
  List<Skill> _allSkills = [];
  List<Skill> _selectedSkills = [];
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
      if (mounted) setState(() => _skillsLoading = false);
    }
  }

  Future<void> _submitProject() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        _showSnackBar('Lütfen bir kategori seçin.', isError: true);
        return;
      }
      if (_selectedSkills.isEmpty) {
        _showSnackBar('En az bir yetenek seçmelisiniz.', isError: true);
        return;
      }

      final selectedSkillIds = _selectedSkills.map((skill) => skill.id).toList();

      final success = await Provider.of<ProjectProvider>(context, listen: false).createProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        budgetMin: int.tryParse(_budgetMinController.text.trim()),
        budgetMax: int.tryParse(_budgetMaxController.text.trim()),
        deadline: _selectedDeadline,
        skillIds: selectedSkillIds,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar('Proje başarıyla yayınlandı!', isError: false);
        Navigator.of(context).pop(true);
      } else {
        final error = context.read<ProjectProvider>().errorMessage;
        _showSnackBar(error ?? 'Proje oluşturulurken bir hata oluştu.', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light().copyWith(
            primaryColor: Theme.of(context).primaryColor,
            colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('dd MMMM yyyy', 'tr_TR').format(picked);
      });
    }
  }

  // --- MODERN KATEGORİ SEÇİCİ ---
  void _showCategoryPicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Kategori Seç", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return ListTile(
                      title: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? theme.primaryColor : null)),
                      trailing: isSelected ? Icon(Icons.check_circle, color: theme.primaryColor) : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectProvider = context.watch<ProjectProvider>();

    // Renkler
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Yeni Proje Yayınla', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. PROJE DETAYLARI ---
              _buildSectionTitle('Proje Detayları', 'Projenizi tanımlayan temel bilgiler.', theme),
              _buildInfoCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Proje Başlığı',
                      hint: 'Örn: E-Ticaret Sitesi Tasarımı',
                      icon: Icons.title,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Proje Açıklaması',
                      hint: 'Projenin amacını, hedeflerini ve beklentilerinizi detaylıca anlatın.',
                      icon: Icons.description_outlined,
                      maxLines: 5,
                      isDark: isDark,
                    ),
                  ],
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // --- 2. KATEGORİ VE YETENEKLER ---
              _buildSectionTitle('Uzmanlık Alanı', 'Projenizin doğru kişilere ulaşması için.', theme),
              _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _showCategoryPicker(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.black12 : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, color: theme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory ?? 'Kategori Seçin',
                                style: TextStyle(
                                  color: _selectedCategory == null ? hintColor : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: _selectedCategory == null ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DropdownSearch (Skills)
                    _skillsLoading
                        ? const Center(child: LinearProgressIndicator())
                        : DropdownSearch<Skill>.multiSelection(
                      items: _allSkills,
                      itemAsString: (Skill s) => s.name,
                      selectedItems: _selectedSkills,
                      onChanged: (List<Skill> skills) => setState(() => _selectedSkills = skills),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Gerekli Yetenekler",
                          labelStyle: TextStyle(color: hintColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.stars_rounded, color: theme.primaryColor),
                        ),
                      ),
                      popupProps: const PopupPropsMultiSelection.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "Yetenek ara...", border: OutlineInputBorder())),
                      ),
                    ),
                  ],
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // --- 3. BÜTÇE VE ZAMANLAMA ---
              _buildSectionTitle('Bütçe ve Zamanlama', 'Proje için ayırdığınız kaynaklar.', theme),
              _buildInfoCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _budgetMinController, label: 'Min Bütçe (₺)', hint: '1000', icon: Icons.currency_lira, isDark: isDark, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: _budgetMaxController, label: 'Max Bütçe (₺)', hint: '5000', icon: Icons.currency_lira_outlined, isDark: isDark, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: IgnorePointer(
                        child: _buildTextField(
                          controller: _deadlineController,
                          label: 'Son Başvuru Tarihi',
                          hint: 'Tarih seçin',
                          icon: Icons.calendar_today_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
                isDark: isDark,
              ),

              const SizedBox(height: 40),

              // --- YAYINLA BUTONU ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: projectProvider.isLoading ? null : _submitProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: theme.primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: projectProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'PROJEYİ YAYINLA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildSectionTitle(String title, String subtitle, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        alignLabelWithHint: true,
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        filled: true,
        fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Bu alan gerekli' : null,
    );
  }
}