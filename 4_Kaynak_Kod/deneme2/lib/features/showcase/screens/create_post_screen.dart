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

  // --- GÜNCELLENMİŞ SEÇİM PENCERESİ (Checkbox Sorunu Çözüldü) ---
  Future<T?> _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<String> items,
    required bool isMultiSelect,
    required List<String> currentlySelected,
  }) async {
    final theme = Theme.of(context);

    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final List<String> tempSelected = List.from(currentlySelected);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final filteredItems = items;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Başlık
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close)
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Liste
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredItems.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelected = tempSelected.contains(item);

                            // --- ÇOKLU SEÇİM İÇİN CheckboxListTile KULLANIYORUZ ---
                            if (isMultiSelect) {
                              return CheckboxListTile(
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                value: isSelected,
                                activeColor: theme.primaryColor, // Mavi renk
                                checkColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                onChanged: (bool? value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      tempSelected.add(item);
                                    } else {
                                      tempSelected.remove(item);
                                    }
                                  });
                                },
                              );
                            }
                            // --- TEKLİ SEÇİM İÇİN STANDART ListTile ---
                            else {
                              return ListTile(
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                trailing: isSelected
                                    ? Icon(Icons.radio_button_checked, color: theme.primaryColor)
                                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                                onTap: () {
                                  setSheetState(() {
                                    tempSelected.clear();
                                    tempSelected.add(item);
                                    // Tekli seçimde direkt kapat ve sonucu dön
                                    Navigator.of(context).pop(item as T);
                                  });
                                },
                              );
                            }
                          },
                        ),
                      ),

                      // Sadece çoklu seçimde "Tamamla" butonu göster
                      if (isMultiSelect)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(tempSelected as T);
                            },
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
      content: Text(message),
      backgroundColor: isSuccess ? Colors.green : Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Vitrin Projesi"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ADIM 1
                    _buildStepHeader(1, 'Proje Detayları', 'Projenize dikkat çekici bir başlık ve açıklama ekleyin.', theme),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Proje Başlığı'),
                      validator: (value) => value!.isEmpty ? 'Başlık boş olamaz' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)', alignLabelWithHint: true),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // ADIM 2
                    _buildStepHeader(2, 'Proje Dosyası', 'Sergilemek istediğiniz 3D model dosyasını (.obj) yükleyin.', theme),
                    _buildFilePicker(theme),
                    const SizedBox(height: 32),

                    // ADIM 3
                    _buildStepHeader(3, 'Projenizi Kategorize Edin', 'Doğru kitleye ulaşmak için projenizi tanımlayın.', theme),

                    _buildSelectionButton(
                      context: context,
                      title: 'Proje Kategorisi*',
                      selectedValue: _selectedCategory,
                      placeholder: 'Bir kategori seçin',
                      onTap: () async {
                        final result = await _showSelectionSheet<String>(
                          context: context,
                          title: 'Kategori Seç',
                          items: _categories,
                          isMultiSelect: false,
                          currentlySelected: _selectedCategory != null ? [_selectedCategory!] : [],
                        );
                        if (result != null) {
                          setState(() => _selectedCategory = result);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildSelectionButton(
                      context: context,
                      title: 'Kullanılan Yazılımlar (Opsiyonel)',
                      selectedValues: _selectedSoftware,
                      placeholder: 'Kullandığınız yazılımları seçin',
                      onTap: () async {
                        final result = await _showSelectionSheet<List<String>>(
                          context: context,
                          title: 'Yazılım Seç',
                          items: _software,
                          isMultiSelect: true,
                          currentlySelected: _selectedSoftware,
                        );
                        if (result != null) {
                          setState(() => _selectedSoftware = result);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    Text('Etiketler (Opsiyonel)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildTagsInput(theme),
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitButton(theme),
        ],
      ),
    );
  }

  Widget _buildStepHeader(int step, String title, String subtitle, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: Text(step.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilePicker(ThemeData theme) {
    return Column(
      children: [
        if (_selectedFile != null)
          Card(
            color: theme.primaryColor.withOpacity(0.05),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
              title: Text(path.basename(_selectedFile!.path), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => setState(() {
                  _selectedFile = null;
                  _isRevitFileSelected = false;
                }),
              ),
            ),
          )
        else
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border.all(color: theme.dividerColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded, size: 40, color: theme.primaryColor),
                  const SizedBox(height: 8),
                  const Text('Dosya Seçmek için Tıklayın'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Tüm yaygın CAD formatları desteklenmektedir.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

        AnimatedOpacity(
          opacity: _isRevitFileSelected ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: _isRevitFileSelected
              ? Container(
            margin: const EdgeInsets.only(top: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Not: En iyi sonuçlar için Revit (.rvt) dosyalarının 2015 veya daha yeni bir sürümde kaydedilmiş olması önerilir.',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSelectionButton({
    required BuildContext context,
    required String title,
    String? selectedValue,
    List<String>? selectedValues,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final hasValue = (selectedValue != null) || (selectedValues != null && selectedValues.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
              color: theme.cardColor,
            ),
            child: hasValue
                ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedValues != null
                  ? selectedValues.map((e) => Chip(
                label: Text(e, style: TextStyle(fontSize: 12, color: theme.primaryColor)),
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
                padding: EdgeInsets.zero,
                deleteIconColor: theme.primaryColor,
                onDeleted: () => setState(() => selectedValues.remove(e)),
              )).toList()
                  : [Chip(
                label: Text(selectedValue!, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
              )],
            )
                : Text(placeholder, style: TextStyle(color: Colors.grey.shade500)),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: 'Etiket yazıp +\'ya basın',
            suffixIcon: IconButton(
              icon: Icon(Icons.add_circle, color: theme.primaryColor),
              onPressed: _addTag,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (_) => _addTag(),
        ),
        if (_tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              children: _tags.map((tag) => Chip(
                label: Text(tag, style: TextStyle(color: theme.primaryColor)),
                backgroundColor: theme.cardColor,
                side: BorderSide(color: theme.dividerColor),
                deleteIconColor: theme.primaryColor,
                onDeleted: () {
                  setState(() => _tags.remove(tag));
                },
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Consumer<ShowcaseProvider>(
          builder: (context, provider, child) {
            return ElevatedButton.icon(
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Projeyi Yayınla'),
              onPressed: provider.isCreatingPost ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}