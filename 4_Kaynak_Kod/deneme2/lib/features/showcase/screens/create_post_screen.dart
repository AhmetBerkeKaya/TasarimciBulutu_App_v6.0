// lib/features/showcase/screens/create_post_screen.dart (Lansman Sürümü)

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
  final List<String> _selectedSoftware = [];
  final List<String> _tags = [];

  // Makine öğrenmesi için örnek veriler. Bunlar gelecekte API'den gelmeli.
  final List<String> _categories = ['Makine Tasarımı', 'Mimari Görselleştirme', 'BIM Modelleme', 'Endüstriyel Ürün Tasarımı', 'Kalıpçılık'];
  final List<String> _software = ['AutoCAD', 'Revit', 'SolidWorks', 'Fusion 360', 'Inventor', 'Blender', '3ds Max'];

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
            // YENİ: Seçilen dosyanın Revit olup olmadığını kontrol et
            _isRevitFileSelected = (fileExtension == 'rvt');
          });
        } else {
          _showSnackBar('Desteklenmeyen dosya formatı. Lütfen desteklenen bir 3D model dosyası seçin.', isSuccess: false);
        }
      }
    } catch (e) {
      _showSnackBar('Dosya seçilirken bir hata oluştu: $e', isSuccess: false);
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
      _showSnackBar('Lütfen bir proje kategorisi seçin.', isSuccess: false);
      return;
    }

    final provider = context.read<ShowcaseProvider>();
    // TODO: Backend ve Provider'ı yeni alanları (category, software, tags) alacak şekilde güncelle.
    final success = await provider.createPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      fileToUpload: _selectedFile!,
      // category: _selectedCategory,
      // software: _selectedSoftware,
      // tags: _tags,
    );

    if (mounted && success) {
      _showSnackBar('Gönderiniz işlenmek üzere alındı! Kısa süre içinde vitrinde görünecektir.', isSuccess: true);
      Navigator.of(context).pop();
    } else if (mounted) {
      _showSnackBar(provider.errorMessage ?? 'Gönderi oluşturulurken bir hata oluştu.', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? Colors.green[600] : Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Vitrin Projesi"),
        backgroundColor: theme.scaffoldBackgroundColor,
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

                    _buildStepHeader(2, 'Proje Dosyası', 'Sergilemek istediğiniz 3D model dosyasını (.obj) yükleyin.', theme),
                    _buildFilePicker(),
                    const SizedBox(height: 32),

                    _buildStepHeader(3, 'Projenizi Kategorize Edin', 'Doğru kitleye ulaşmak için projenizi tanımlayın.', theme),
                    _buildCategorySelector(theme),
                    const SizedBox(height: 24),
                    Text('Kullanılan Yazılımlar (Opsiyonel)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildSoftwareSelector(theme),
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

  Widget _buildFilePicker() {
    // ========================================================================
    // ===       DEĞİŞİKLİK: Dinamik uyarıyı göstermek için güncellendi       ===
    // ========================================================================
    return Column(
      children: [
        if (_selectedFile != null)
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
              title: Text(path.basename(_selectedFile!.path), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                // YENİ: Dosya kaldırıldığında Revit bayrağını da sıfırla
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
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  const Text('Dosya Seçmek için Tıklayın'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Tüm yaygın CAD formatları desteklenmektedir.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // --- YENİ ANİMASYONLU UYARI WIDGET'I ---
        AnimatedOpacity(
          opacity: _isRevitFileSelected ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
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
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proje Kategorisi*', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _categories.map((category) {
            return ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() => _selectedCategory = selected ? category : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSoftwareSelector(ThemeData theme) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _software.map((software) {
        return FilterChip(
          label: Text(software),
          selected: _selectedSoftware.contains(software),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSoftware.add(software);
              } else {
                _selectedSoftware.remove(software);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTagsInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            labelText: 'Etiket ekle (örn: render, konsept)',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addTag,
            ),
          ),
          onSubmitted: (_) => _addTag(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() => _tags.remove(tag));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
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
              ),
              // Yükleme durumunu butonun içinde göstermek daha şık
              // child: provider.isCreatingPost
              //     ? const CircularProgressIndicator(color: Colors.white)
              //     : const Text("Paylaş"),
            );
          },
        ),
      ),
    );
  }
}
