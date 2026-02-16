// lib/features/project/widgets/application_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/application_provider.dart';

class ApplicationDialog extends StatefulWidget {
  final String projectId;

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

  bool _isSubmitting = false;

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await Provider.of<ApplicationProvider>(context, listen: false).applyToProject(
        projectId: widget.projectId,
        coverLetter: _coverLetterController.text.trim(),
        // Backend'in beklediği parametre (proposedBudget)
        proposedBudget: double.tryParse(_budgetController.text.trim()) ?? 0,
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Dialogu kapat

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(success ? 'Başvurunuz başarıyla gönderildi!' : 'Başvuru gönderilemedi.')),
            ],
          ),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bir hata oluştu.")));
      }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Modern Renk Paleti
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F7FA);
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: bgColor,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BAŞLIK ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.send_rounded, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projeye Başvur',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Teklifinizi hazırlayın',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- ÖN YAZI ---
                _buildInputLabel("Ön Yazı (Cover Letter)", isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _coverLetterController,
                  maxLines: 4,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  decoration: _buildInputDecoration(
                    hint: "Kendinizden ve bu işe yaklaşımınızdan bahsedin...",
                    fillColor: inputFillColor,
                    borderColor: borderColor,
                    isDark: isDark,
                  ),
                  validator: (value) => value!.isEmpty ? 'Lütfen bir ön yazı yazın.' : null,
                ),

                const SizedBox(height: 20),

                // --- BÜTÇE ---
                _buildInputLabel("Teklif Ettiğiniz Bütçe (₺)", isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration(
                    hint: "0.00",
                    fillColor: inputFillColor,
                    borderColor: borderColor,
                    isDark: isDark,
                    // --- DEĞİŞİKLİK BURADA: Attach Money -> Currency Lira ---
                    prefixIcon: Icons.currency_lira,
                    iconColor: theme.primaryColor,
                  ),
                  validator: (value) => value!.isEmpty ? 'Lütfen bir bütçe girin.' : null,
                ),

                const SizedBox(height: 32),

                // --- AKSİYON BUTONLARI ---
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? const LinearGradient(colors: [Colors.white, Color(0xFFE2E8F0)])
                              : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          )
                              : const Text("Başvuruyu Gönder", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required Color fillColor,
    required Color borderColor,
    required bool isDark,
    IconData? prefixIcon,
    Color? iconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
      filled: true,
      fillColor: fillColor,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: iconColor, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white70 : Colors.black87, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}