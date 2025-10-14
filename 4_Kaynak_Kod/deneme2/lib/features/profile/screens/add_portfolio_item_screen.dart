import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/portfolio_item_model.dart';

class AddPortfolioItemScreen extends StatefulWidget {
  final PortfolioItem? itemToEdit;
  const AddPortfolioItemScreen({super.key, this.itemToEdit});

  @override
  State<AddPortfolioItemScreen> createState() => _AddPortfolioItemScreenState();
}

class _AddPortfolioItemScreenState extends State<AddPortfolioItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  File? _selectedFile;
  String? _selectedFileName;
  bool _isLoading = false;

  bool get _isEditMode => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    // Eğer düzenleme modundaysak, mevcut dosyanın adını gösterelim
    if (_isEditMode) {
      _selectedFileName = widget.itemToEdit!.imageUrl.split('/').last;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // --- DEĞİŞİKLİK BURADA: Sadece PDF dosyalarına izin veriyoruz ---
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Sadece .pdf uzantılı dosyaları göster
    );
    // --- BİTTİ ---

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      // Yeni ekleme modunda dosya seçmek zorunlu.
      if (!_isEditMode && _selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir dosya seçin.')));
        return;
      }
      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      bool success = false;

      if (_isEditMode) {
        // --- GÜNCELLEME MANTIĞI ---
        success = await authProvider.updatePortfolioItem(
          itemId: widget.itemToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          // Eğer kullanıcı yeni bir dosya seçtiyse onu gönder, seçmediyse null gönder.
          newFile: _selectedFile,
        );
      } else {
        // --- EKLEME MANTIĞI ---
        success = await authProvider.addPortfolioItem(
          title: _titleController.text,
          description: _descriptionController.text,
          file: _selectedFile!,
        );
      }

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem sırasında bir hata oluştu.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Portfolyoyu Düzenle' : 'Yeni Portfolyo Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _pickFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: Center(
                  child: (_selectedFileName != null)
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 48),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          _selectedFileName!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isEditMode && _selectedFile == null)
                        const Text("(Mevcut Dosya)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        "Portfolyo için PDF Dosyası Seç",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "(.pdf formatında)",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Başlık'), validator: (v) => v!.isEmpty ? 'Başlık zorunludur.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _isLoading ? null : _saveItem, child: const Text('KAYDET')),
          ],
        ),
      ),
    );
  }
}