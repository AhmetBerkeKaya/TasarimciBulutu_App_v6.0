// lib/features/project/widgets/filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/project_provider.dart';

class FilterSheet extends StatefulWidget {
  final String currentSearchQuery;

  const FilterSheet({super.key, required this.currentSearchQuery});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  // --- ÖRNEK BÜYÜK LİSTE SİMÜLASYONU ---
  // Gerçekte burası API'den gelebilir veya çok uzun bir liste olabilir.
  final List<String> _allCategories = [
    "Tümü",
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

  final List<String> _sortOptions = [
    "En Yeni",
    "Fiyat Artan",
    "Fiyat Azalan"
  ];

  // State
  String _selectedCategory = "Tümü";
  String _selectedSort = "En Yeni";
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProjectProvider>();
    _selectedCategory = provider.activeCategory ?? "Tümü";
    _selectedSort = provider.activeSortBy ?? "En Yeni";
    if (provider.activeMinBudget != null) _minPriceController.text = provider.activeMinBudget.toString();
    if (provider.activeMaxBudget != null) _maxPriceController.text = provider.activeMaxBudget.toString();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  // --- YENİ: KATEGORİ SEÇİM PENCERESİ (ARAMALI) ---
  Future<void> _showCategoryPicker(BuildContext context, bool isDark) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekran hissi için
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Ekranın %90'ını kaplasın
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            // Arama state'ini yönetmek için StatefulBuilder
            return StatefulBuilder(
              builder: (context, setState) {
                // Arama filtresi (Basitçe query ile filtreliyoruz)
                // Gerçek uygulamada searchController ekleyip listener ile yapabiliriz
                // Şimdilik temiz bir liste gösteriyoruz.

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Kategori Seç", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Arama Kutusu (Liste içinde arama yapmak için)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Kategori ara...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          ),
                          // Basit arama mantığı buraya eklenebilir, şimdilik listeyi olduğu gibi gösteriyoruz
                        ),
                      ),
                      const Divider(),

                      // Sonsuz Liste (ListView.builder ile performanslı)
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _allCategories.length,
                          itemBuilder: (context, index) {
                            final category = _allCategories[index];
                            final isSelected = _selectedCategory == category;

                            return ListTile(
                              title: Text(
                                category,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? theme.primaryColor : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: theme.primaryColor)
                                  : null,
                              onTap: () {
                                // Seçimi ana ekrana aktar
                                this.setState(() {
                                  _selectedCategory = category;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    final provider = context.read<ProjectProvider>();
    int? minPrice = int.tryParse(_minPriceController.text.trim());
    int? maxPrice = int.tryParse(_maxPriceController.text.trim());

    provider.applyFiltersAndFetch(
      searchQuery: widget.currentSearchQuery,
      category: _selectedCategory == "Tümü" ? null : _selectedCategory,
      minBudget: minPrice,
      maxBudget: maxPrice,
      sortBy: _selectedSort,
    );
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = "Tümü";
      _selectedSort = "En Yeni";
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final contentColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Yükseklik
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filtrele & Sırala', style: TextStyle(fontFamily: 'Manrope', fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                    TextButton(onPressed: _clearFilters, style: TextButton.styleFrom(foregroundColor: Colors.red.shade400), child: const Text('Temizle', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KATEGORİ (ARTIK BİR BUTON)
                  _buildSectionTitle('Kategori', textColor),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showCategoryPicker(context, isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: contentColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. BÜTÇE
                  _buildSectionTitle('Bütçe Aralığı (₺)', textColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildModernInput(controller: _minPriceController, hint: 'Min', isDark: isDark, contentColor: contentColor, textColor: textColor)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('-', style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
                      Expanded(child: _buildModernInput(controller: _maxPriceController, hint: 'Max', isDark: isDark, contentColor: contentColor, textColor: textColor)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 3. SIRALAMA (AZ SEÇENEK OLDUĞU İÇİN LISTVIEW KALABİLİR)
                  _buildSectionTitle('Sıralama', textColor),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 45,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sortOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final sort = _sortOptions[index];
                        final isSelected = _selectedSort == sort;
                        return InkWell(
                          onTap: () => setState(() => _selectedSort = sort),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.primaryColor : contentColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? theme.primaryColor : Colors.transparent),
                            ),
                            child: Text(sort, style: TextStyle(color: isSelected ? Colors.white : textColor.withOpacity(0.8), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ALT BUTON
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Text('Sonuçları Göster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700, color: color));
  }

  Widget _buildModernInput({required TextEditingController controller, required String hint, required bool isDark, required Color contentColor, required Color textColor}) {
    return Container(
      decoration: BoxDecoration(color: contentColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixText: '₺ ',
          prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}