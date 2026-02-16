// lib/features/showcase/screens/create_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../../core/providers/showcase_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isRevitFileSelected = false;
  File? _selectedFile;
  String? _selectedCategory;

  List<String> _selectedSoftware = [];
  List<String> _tags = [];

  final List<String> _categories = ['Makine Tasarımı', 'Mimari Görselleştirme', 'BIM Modelleme', 'Endüstriyel Ürün Tasarımı', 'Kalıpçılık', 'Konsept Sanatı', 'Oyun Varlıkları', 'Ürün Simülasyonu'];
  final List<String> _software = ['AutoCAD', 'Revit', 'SolidWorks', 'Fusion 360', 'Inventor', 'Blender', '3ds Max', 'CATIA', 'Creo', 'NX', 'SketchUp', 'Rhino'];

  // --- SEÇİM PENCERESİ ---
  Future<T?> _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<String> items,
    required bool isMultiSelect,
    required List<String> currentlySelected,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final List<String> tempSelected = List.from(currentlySelected);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded)
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: items.length,
                          separatorBuilder: (ctx, i) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.1)),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = tempSelected.contains(item);

                            if (isMultiSelect) {
                              return CheckboxListTile(
                                title: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                value: isSelected,
                                activeColor: isDark ? Colors.white : Colors.black,
                                checkColor: isDark ? Colors.black : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                onChanged: (bool? value) {
                                  setSheetState(() {
                                    if (value == true) tempSelected.add(item);
                                    else tempSelected.remove(item);
                                  });
                                },
                              );
                            } else {
                              return ListTile(
                                title: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? (isDark ? Colors.white : Colors.black) : null)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: isDark ? Colors.white : Colors.black) : null,
                                onTap: () {
                                  Navigator.of(context).pop(item as T);
                                },
                              );
                            }
                          },
                        ),
                      ),
                      if (isMultiSelect)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.of(context).pop(tempSelected as T),
                            child: const Text('Seçimi Tamamla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        const allowedExtensions = [
          'obj', 'stl', 'step', 'stp', 'iges', 'igs', 'fbx', 'x_t', 'x_b',
          'gltf', 'glb', '3ds', 'x3d', 'sldprt', 'sldasm', 'ipt', 'iam', 'rvt',
          'catpart', 'catproduct', 'cgr', 'prt', 'asm'
        ];
        final fileExtension = result.files.single.extension?.toLowerCase();

        if (fileExtension != null && allowedExtensions.contains(fileExtension)) {
          setState(() {
            _selectedFile = File(result.files.single.path!);
            _isRevitFileSelected = (fileExtension == 'rvt');
          });
        } else {
          _showSnackBar('Desteklenmeyen dosya formatı.', isSuccess: false);
        }
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isSuccess: false);
    }
  }

  void _addTag() {
    final text = _tagsController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagsController.clear();
      });
    }
  }

  Future<void> _submitPost() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFile == null) {
      _showSnackBar('Lütfen bir proje dosyası seçin.', isSuccess: false);
      return;
    }
    if (_selectedCategory == null) {
      _showSnackBar('Lütfen bir kategori seçin.', isSuccess: false);
      return;
    }

    final provider = context.read<ShowcaseProvider>();
    final success = await provider.createPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      fileToUpload: _selectedFile!,
      // Backend parametrelerine göre burayı açabilirsin:
      // category: _selectedCategory,
      // software: _selectedSoftware,
      // tags: _tags,
    );

    if (mounted && success) {
      _showSnackBar('Gönderiniz başarıyla paylaşıldı!', isSuccess: true);
      Navigator.of(context).pop();
    } else if (mounted) {
      _showSnackBar(provider.errorMessage ?? 'Hata oluştu.', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(isSuccess ? Icons.check_circle : Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]),
      backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Yeni Proje", style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ADIM 1
                    _buildStepHeader(1, 'Proje Detayları', 'Projenize dikkat çekici bir başlık ve açıklama ekleyin.', isDark),
                    _buildModernInput(controller: _titleController, hint: 'Proje Başlığı', isDark: isDark, validator: (v) => v!.isEmpty ? 'Başlık gerekli' : null),
                    const SizedBox(height: 16),
                    _buildModernInput(controller: _descriptionController, hint: 'Proje hakkında detaylar...', isDark: isDark, maxLines: 4),
                    const SizedBox(height: 32),

                    // ADIM 2
                    _buildStepHeader(2, 'Proje Dosyası', 'Sergilemek istediğiniz 3D model dosyasını yükleyin.', isDark),
                    _buildModernFilePicker(isDark),
                    const SizedBox(height: 32),

                    // ADIM 3
                    _buildStepHeader(3, 'Kategori & Araçlar', 'Projenizi doğru kitleye ulaştırın.', isDark),
                    _buildSelectionButton(
                      title: 'Kategori',
                      selectedValue: _selectedCategory,
                      placeholder: 'Seçiniz',
                      isDark: isDark,
                      icon: Icons.category_rounded,
                      onTap: () async {
                        final result = await _showSelectionSheet<String>(
                          context: context,
                          title: 'Kategori Seç',
                          items: _categories,
                          isMultiSelect: false,
                          currentlySelected: _selectedCategory != null ? [_selectedCategory!] : [],
                        );
                        if (result != null) setState(() => _selectedCategory = result);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionButton(
                      title: 'Yazılımlar',
                      selectedValues: _selectedSoftware,
                      placeholder: 'Seçiniz',
                      isDark: isDark,
                      icon: Icons.computer_rounded,
                      onTap: () async {
                        final result = await _showSelectionSheet<List<String>>(
                          context: context,
                          title: 'Yazılım Seç',
                          items: _software,
                          isMultiSelect: true,
                          currentlySelected: _selectedSoftware,
                        );
                        if (result != null) setState(() => _selectedSoftware = result);
                      },
                    ),
                    const SizedBox(height: 24),

                    Text('Etiketler', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 8),
                    _buildTagsInput(isDark),
                    const SizedBox(height: 100), // Alt boşluk
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitButton(isDark),
        ],
      ),
    );
  }

  // --- MODERN BİLEŞENLER ---

  Widget _buildStepHeader(int step, String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(step.toString(), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40.0, top: 4),
          child: Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildModernFilePicker(bool isDark) {
    return Column(
      children: [
        if (_selectedFile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(path.basename(_selectedFile!.path), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      Text('${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  onPressed: () => setState(() { _selectedFile = null; _isRevitFileSelected = false; }),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, style: BorderStyle.solid, width: 1.5),
                // Dashed border efekti için custom painter kullanılabilir ama şimdilik solid gri border yeterli
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Dosya Seçmek için Tıklayın', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text('Desteklenen: .obj, .fbx, .rvt, .stl...', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey.shade500)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionButton({
    required String title,
    String? selectedValue,
    List<String>? selectedValues,
    required String placeholder,
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = (selectedValue != null) || (selectedValues != null && selectedValues.isNotEmpty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  const SizedBox(height: 4),
                  hasValue
                      ? (selectedValues != null
                      ? Text(selectedValues.join(", "), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)
                      : Text(selectedValue!, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)))
                      : Text(placeholder, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.grey[500] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
              child: Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: TextStyle(fontSize: 12, color: isDark ? Colors.black : Colors.white)),
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  deleteIcon: Icon(Icons.close, size: 14, color: isDark ? Colors.black : Colors.white),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ),
          TextField(
            controller: _tagsController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Etiket yazıp ekleyin...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle_rounded, color: isDark ? Colors.white : Colors.black),
                onPressed: _addTag,
              ),
            ),
            onSubmitted: (_) => _addTag(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Consumer<ShowcaseProvider>(
          builder: (context, provider, child) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)]) // Dark Mode: Beyaz Buton
                    : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF020617)]), // Light Mode: Siyah Buton
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: provider.isCreatingPost ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: provider.isCreatingPost
                    ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                    : Text(
                  'PROJEYİ YAYINLA',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}