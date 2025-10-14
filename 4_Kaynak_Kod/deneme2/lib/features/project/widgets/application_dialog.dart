// lib/features/project/widgets/application_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/application_provider.dart';

class ApplicationDialog extends StatefulWidget {
  final String projectId;

  // DEĞİŞİKLİK: Artık token'a ihtiyacımız yok
  const ApplicationDialog({
    super.key,
    required this.projectId,
  });

  @override
  State<ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<ApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _budgetController = TextEditingController();

  // DEĞİŞİKLİK: _isLoading durumunu provider'dan dinleyeceğiz
  // bool _isLoading = false;

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      // DEĞİŞİKLİK: ApiService yerine Provider'ı çağırıyoruz
      final success = await Provider.of<ApplicationProvider>(context, listen: false).applyToProject(
        projectId: widget.projectId,
        coverLetter: _coverLetterController.text,
        proposedBudget: double.tryParse(_budgetController.text),
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Diyalog penceresini kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Başvurunuz başarıyla gönderildi!' : 'Başvuru gönderilirken bir hata oluştu.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // isLoading durumunu provider'dan alıyoruz
    final isLoading = context.watch<ApplicationProvider>().isLoading;

    return AlertDialog(
      title: const Text('Projeye Başvur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _coverLetterController,
                decoration: const InputDecoration(
                  labelText: 'Ön Yazı (Cover Letter)',
                  hintText: 'Proje sahibi için bir mesaj yazın...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Lütfen bir ön yazı ekleyin.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Teklif Ettiğiniz Bütçe (₺)',
                  hintText: 'örn: 12500',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submitApplication,
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Başvuruyu Gönder'),
        ),
      ],
    );
  }
}