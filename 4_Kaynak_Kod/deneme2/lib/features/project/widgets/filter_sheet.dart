import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/project_provider.dart';

class FilterSheet extends StatefulWidget {
  final String? currentSearchQuery;
  const FilterSheet({super.key, this.currentSearchQuery});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedCategory;
  String? _selectedSortBy;
  late TextEditingController _minBudgetController;
  late TextEditingController _maxBudgetController;

  // === GÜNCELLENMİŞ: BACKEND ENUM İLE BİREBİR AYNI LİSTE ===
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
  // =========================================================

  final Map<String, String> _sortOptions = {
    'newest': 'En Yeni',
    'budget_high': 'En Yüksek Bütçe',
    'budget_low': 'En Düşük Bütçe',
  };

  @override
  void initState() {
    super.initState();
    final projectProvider = context.read<ProjectProvider>();
    // Eğer seçili kategori yeni listede yoksa (eski veri kalıntısı), null yap.
    if (projectProvider.activeCategory != null && !_categories.contains(projectProvider.activeCategory)) {
      _selectedCategory = null;
    } else {
      _selectedCategory = projectProvider.activeCategory;
    }

    _selectedSortBy = _sortOptions[projectProvider.activeSortBy];
    _minBudgetController = TextEditingController(text: projectProvider.activeMinBudget?.toString() ?? '');
    _maxBudgetController = TextEditingController(text: projectProvider.activeMaxBudget?.toString() ?? '');
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final sortByValue = _sortOptions.keys.firstWhere((k) => _sortOptions[k] == _selectedSortBy, orElse: () => 'newest');
    context.read<ProjectProvider>().applyFiltersAndFetch(
      searchQuery: widget.currentSearchQuery,
      category: _selectedCategory,
      minBudget: int.tryParse(_minBudgetController.text),
      maxBudget: int.tryParse(_maxBudgetController.text),
      sortBy: sortByValue,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    context.read<ProjectProvider>().clearFiltersAndFetch(currentSearchQuery: widget.currentSearchQuery);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtrele ve Sırala', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true, // Uzun metinlerin taşmasını önler
              hint: const Text('Tüm Kategoriler'),
              items: _categories.map((c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis) // Uzun metinler için ... koyar
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Kategori'),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _minBudgetController, decoration: const InputDecoration(labelText: 'Min Bütçe (₺)', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _maxBudgetController, decoration: const InputDecoration(labelText: 'Max Bütçe (₺)', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSortBy,
              hint: const Text('Sıralama Ölçütü'),
              items: _sortOptions.values.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _selectedSortBy = v),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Sırala'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: _clearFilters, child: const Text('Filtreleri Temizle'))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(onPressed: _applyFilters, child: const Text('Uygula'))),
              ],
            )
          ],
        ),
      ),
    );
  }
}