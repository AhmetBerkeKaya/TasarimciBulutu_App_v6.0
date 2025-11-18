// lib/features/profile/screens/manage_portfolio_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/portfolio_item_model.dart';
import 'add_portfolio_item_screen.dart';

class ManagePortfolioScreen extends StatelessWidget {
  const ManagePortfolioScreen({super.key});


  // Dosya yoluna göre doğru ikonu veya resmi döndürür.
  Widget _buildFilePreview(String fileUrl) {
    // --- DÜZELTME BAŞLANGICI ---
    // Linki kontrol et, http yoksa ekle
    String fullPath = fileUrl;
    if (!fullPath.startsWith('http')) {
      fullPath = 'http://10.0.2.2:8000/$fileUrl';
    }
    // --- DÜZELTME SONU ---

    final extension = fileUrl.split('.').last.toLowerCase();

    if (['png', 'jpg', 'jpeg', 'gif'].contains(extension)) {
      // Eğer bir resimse, DÜZELTİLMİŞ fullPath ile yükle
      return Image.network(
        fullPath, // <-- Burayı düzelttik
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else if (extension == 'pdf') {
      // Eğer PDF ise, PDF ikonunu göster
      return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 48);
    } else {
      // Diğer tüm dosya türleri için genel bir dosya ikonu göster
      return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 48);
    }
  }


  Future<void> _deleteItem(BuildContext context, PortfolioItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmeyi Onayla'),
        content: Text('"${item.title}" başlıklı portfolyo öğesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await Provider.of<AuthProvider>(context, listen: false).deletePortfolioItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final portfolioItems = authProvider.user?.portfolioItems ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Portfolyoyu Yönet'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                tooltip: 'Yeni Öğe Ekle',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddPortfolioItemScreen())),
              ),
            ],
          ),
          body: portfolioItems.isEmpty
              ? const Center(child: Text('Henüz portfolyo öğesi eklenmemiş.'))
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: portfolioItems.length,
            itemBuilder: (context, index) {
              final item = portfolioItems[index];
              final extension = item.imageUrl.split('.').last.toLowerCase();
              return Card(
                child: ListTile(
                  leading: SizedBox(width: 50, height: 50, child: _buildFilePreview(item.imageUrl)),
                  title: Text(item.title, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {

                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AddPortfolioItemScreen(itemToEdit: item),
                        )),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _deleteItem(context, item),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}