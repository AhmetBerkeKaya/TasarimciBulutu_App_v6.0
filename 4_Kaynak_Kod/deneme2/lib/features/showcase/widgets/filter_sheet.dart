// lib/features/showcase/widgets/filter_sheet.dart (DÜZELTİLMİŞ)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/showcase_provider.dart';

class ShowcaseFilterSheet extends StatefulWidget {
  const ShowcaseFilterSheet({super.key});

  @override
  State<ShowcaseFilterSheet> createState() => _ShowcaseFilterSheetState();
}

class _ShowcaseFilterSheetState extends State<ShowcaseFilterSheet> {
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    // Mevcut seçimi Provider'dan al ki ekran açılınca doğru yer seçili gelsin
    _selectedSort = context.read<ShowcaseProvider>().sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Filtrele ve Sırala',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Text('Sıralama', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildChip('En Yeni', 'newest', theme),
              _buildChip('En Eski', 'oldest', theme),
            ],
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            // --- DÜZELTME BURADA: PROVIDER BAĞLANTISI ---
            onPressed: () {
              print("Filtre Uygulanıyor: $_selectedSort"); // Debug için
              context.read<ShowcaseProvider>().setSortBy(_selectedSort);
              Navigator.pop(context);
            },
            // --------------------------------------------
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Uygula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedSort = value);
      },
    );
  }
}