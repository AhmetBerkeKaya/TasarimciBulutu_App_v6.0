// lib/features/profile/screens/add_portfolio_item_screen.dart

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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveItem() async {
    // Klavye açıksa kapat
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (!_isEditMode && _selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir PDF dosyası seçin.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      bool success = false;

      if (_isEditMode) {
        success = await authProvider.updatePortfolioItem(
          itemId: widget.itemToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          newFile: _selectedFile,
        );
      } else {
        success = await authProvider.addPortfolioItem(
          title: _titleController.text,
          description: _descriptionController.text,
          file: _selectedFile!,
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolyo başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('İşlem sırasında bir hata oluştu.'),
              backgroundColor: Theme.of(context).colorScheme.error
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Portfolyoyu Düzenle' : 'Yeni Portfolyo Ekle'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- DOSYA SEÇİM ALANI ---
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _selectedFileName != null
                            ? theme.primaryColor
                            : theme.dividerColor,
                        width: 2,
                        style: _selectedFileName != null ? BorderStyle.solid : BorderStyle.solid // İstenirse dotted border paketi eklenebilir
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedFileName != null) ...[
                        // Dosya Seçiliyse
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _selectedFileName!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_isEditMode && _selectedFile == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                                "(Mevcut Dosya)",
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "Değiştirmek için tıklayın",
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor),
                        ),
                      ] else ...[
                        // Dosya Seçili Değilse
                        Icon(Icons.cloud_upload_outlined, size: 48, color: theme.primaryColor.withOpacity(0.6)),
                        const SizedBox(height: 12),
                        Text(
                          "PDF Dosyası Seçin",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Portfolyonuz için .pdf formatı",
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- INPUTLAR ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Örn: Mimari Restorasyon Projesi',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'Başlık zorunludur.' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Proje detaylarından bahsedin...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 40),

              // --- KAYDET BUTONU ---
              ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'KAYDET',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}