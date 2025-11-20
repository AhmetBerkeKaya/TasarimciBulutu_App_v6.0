// lib/features/profile/screens/add_experience_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/work_experience_model.dart';

class AddExperienceScreen extends StatefulWidget {
  final WorkExperience? experienceToEdit;

  const AddExperienceScreen({super.key, this.experienceToEdit});

  @override
  State<AddExperienceScreen> createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrentlyWorking = false;

  bool _isLoading = false;
  bool get _isEditMode => widget.experienceToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final exp = widget.experienceToEdit!;
      _titleController.text = exp.title;
      _companyController.text = exp.companyName;
      _descriptionController.text = exp.description ?? '';
      _startDate = exp.startDate;
      _endDate = exp.endDate;
      if (_endDate == null) {
        _isCurrentlyWorking = true;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
          _isCurrentlyWorking = false;
        }
      });
    }
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Lütfen başlangıç tarihini seçin.'),
              backgroundColor: Theme.of(context).colorScheme.error
          )
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'company_name': _companyController.text,
      'description': _descriptionController.text,
      'start_date': _startDate!.toIso8601String().substring(0, 10),
      'end_date': _isCurrentlyWorking ? null : _endDate?.toIso8601String().substring(0, 10),
    };

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isEditMode) {
      success = await authProvider.updateWorkExperience(
          experienceId: widget.experienceToEdit!.id,
          data: data
      );
    } else {
      success = await authProvider.addWorkExperience(data);
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deneyim başarıyla kaydedildi!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Kaydedilirken bir hata oluştu.'),
            backgroundColor: Theme.of(context).colorScheme.error
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Deneyimi Düzenle' : 'Yeni Deneyim Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pozisyon Bilgileri', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Ünvan / Pozisyon',
                  hintText: 'Örn: Kıdemli Mimari Tasarımcı',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Lütfen ünvanınızı girin.' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Firma Adı',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Lütfen firma adını girin.' : null,
              ),

              const SizedBox(height: 32),

              Text('Çalışma Süresi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      context: context,
                      label: 'Başlangıç',
                      selectedDate: _startDate,
                      onTap: () => _pickDate(true),
                      // Başlangıç tarihi silinirse null yap
                      onClear: () => setState(() => _startDate = null),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Opacity(
                      opacity: _isCurrentlyWorking ? 0.5 : 1.0,
                      child: _buildDatePicker(
                        context: context,
                        label: 'Bitiş',
                        selectedDate: _endDate,
                        onTap: _isCurrentlyWorking ? null : () => _pickDate(false),
                        placeholder: 'Seçiniz',
                        // Bitiş tarihi silinirse null yap
                        onClear: () => setState(() => _endDate = null),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isCurrentlyWorking,
                        activeColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _isCurrentlyWorking = val ?? false;
                            if (_isCurrentlyWorking) {
                              _endDate = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Bu görevde halen çalışıyorum', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text('Detaylar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Sorumluluklarınızdan ve başarılarınızdan bahsedin...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 5,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExperience,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GÜNCELLENMİŞ TARİH SEÇİCİ (OVERFLOW HATASI DÜZELTİLDİ) ---
  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback? onTap,
    VoidCallback? onClear, // Opsiyonel yaptık
    String placeholder = 'Seçiniz',
  }) {
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'tr');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
      ),
      child: Row(
        children: [
          // Tıklanabilir Alan (Metin ve İkon)
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        // --- DÜZELTME: Metni Expanded ile sarmaladık ---
                        Expanded(
                          child: Text(
                            selectedDate != null ? formatter.format(selectedDate) : placeholder,
                            maxLines: 1, // Tek satırda kalsın
                            overflow: TextOverflow.ellipsis, // Sığmazsa ... koysun
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedDate != null ? theme.textTheme.bodyLarge?.color : Colors.grey,
                            ),
                          ),
                        ),
                        // -----------------------------------------------
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Temizleme Butonu
          if (selectedDate != null && onTap != null && onClear != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: onClear,
              tooltip: "Tarihi Temizle",
              // Butonun kapladığı alanı biraz daraltalım ki metne yer kalsın
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }
}