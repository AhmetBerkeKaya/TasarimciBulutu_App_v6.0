// lib/features/profile/screens/add_experience_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/work_experience_model.dart'; // <-- Modeli import et

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
  bool _isLoading = false;
  bool get _isEditMode => widget.experienceToEdit != null;

  @override
  void initState() {
    super.initState();
    // --- YENİ: Eğer güncelleme modundaysak, formları doldur ---
    if (_isEditMode) {
      final exp = widget.experienceToEdit!;
      _titleController.text = exp.title;
      _companyController.text = exp.companyName;
      _descriptionController.text = exp.description ?? '';
      _startDate = exp.startDate;
      _endDate = exp.endDate;
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
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.validate() || _startDate == null) return;

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'company_name': _companyController.text,
      'description': _descriptionController.text,
      'start_date': _startDate!.toIso8601String().substring(0, 10),
      'end_date': _endDate?.toIso8601String().substring(0, 10),
    };

    final authProvider = context.read<AuthProvider>();
    bool success;

    // --- YENİ: Mod'a göre doğru provider fonksiyonunu çağır ---
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem sırasında bir hata oluştu.'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd MMMM yyyy');
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Deneyimi Düzenle' : 'Yeni Deneyim Ekle')),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Pozisyon'), validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _companyController, decoration: const InputDecoration(labelText: 'Firma Adı'), validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz.' : null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(_startDate == null ? 'Başlangıç Tarihi' : formatter.format(_startDate!))),
                IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickDate(true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text(_endDate == null ? 'Bitiş Tarihi (İsteğe Bağlı)' : formatter.format(_endDate!))),
                IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickDate(false)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 4),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveExperience, child: const Text('KAYDET')),
          ],
        ),
      ),
    );
  }
}