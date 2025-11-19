// lib/features/messages/screens/message_list_screen.dart (GÜNCEL)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/message_provider.dart'; // YENİ PROVIDER
import '../../../data/models/message_model.dart';
import 'chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  final _searchController = TextEditingController();
  Timer? _refreshTimer; // <-- EKLENDİ

  @override
  void initState() {
    super.initState();
    // İlk yükleme
    Future.microtask(() =>
        Provider.of<MessageProvider>(context, listen: false).fetchConversations()
    );

    // === EKLENEN KISIM: PERİYODİK YENİLEME ===
    // Her 10 saniyede bir sohbet listesini yenile (Yeni mesaj var mı diye bak)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // Sessizce güncelle (Loading göstermeden)
        Provider.of<MessageProvider>(context, listen: false).fetchConversations(silent: true);
      }
    });
    // =========================================
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel(); // <-- EKLENDİ: Timer'ı kapatmayı unutma
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    if (date == DateTime(now.year, now.month, now.day)) {
      return DateFormat('HH:mm').format(timestamp);
    }
    return DateFormat('dd.MM.yy').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final msgProvider = Provider.of<MessageProvider>(context);
    final currentUserId = Provider.of<AuthProvider>(context).user?.id;

    return Scaffold(
      // --- APP BAR (MOD DEĞİŞKEN) ---
      appBar: AppBar(
        title: msgProvider.isSelectionMode
            ? Text('${msgProvider.selectedCount} Seçildi')
            : const Text('Mesajlar'),
        actions: [
          if (msgProvider.isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              // Eğer seçim yoksa buton pasif (null), varsa fonksiyonu çağır
              onPressed: msgProvider.selectedCount > 0
                  ? () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Sil"),
                    content: Text("${msgProvider.selectedCount} konuşma silinsin mi?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );

                if (confirm == true) {
                  // --- DÜZELTME: Parametre göndermiyoruz, Provider zaten seçilenleri biliyor ---
                  await msgProvider.deleteSelectedConversations();
                }
              }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => msgProvider.toggleSelectionMode(),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist), // Seçim modunu aç
              tooltip: "Düzenle",
              onPressed: () => msgProvider.toggleSelectionMode(),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => msgProvider.searchConversations(val),
              decoration: InputDecoration(
                hintText: 'Mesajlarda ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () => msgProvider.fetchConversations(),
        child: Builder(
          builder: (context) {
            if (msgProvider.isLoading) return const LoadingIndicator();
            if (msgProvider.conversations.isEmpty) {
              return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: "Mesaj Bulunamadı"
              );
            }

            return ListView.separated(
              itemCount: msgProvider.conversations.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                final lastMessage = msgProvider.conversations[index];
                final otherUser = lastMessage.sender.id == currentUserId
                    ? lastMessage.receiver
                    : lastMessage.sender;

                // Seçim modunda ID olarak OtherUser ID'sini kullanıyoruz
                final isSelected = msgProvider.isSelected(otherUser.id);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: otherUser.profilePictureUrl != null
                            ? NetworkImage(otherUser.profilePictureUrl!)
                            : null,
                        child: otherUser.profilePictureUrl == null
                            ? Text(otherUser.name[0].toUpperCase())
                            : null,
                      ),
                      // Seçim Modu Checkbox'ı
                      if (msgProvider.isSelectionMode)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle
                            ),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    otherUser.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMessage.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (!lastMessage.isRead && lastMessage.sender.id != currentUserId)
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: (!lastMessage.isRead && lastMessage.sender.id != currentUserId)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    _formatTimestamp(lastMessage.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    if (msgProvider.isSelectionMode) {
                      msgProvider.toggleSelection(otherUser.id);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(otherUser: otherUser),
                        ),
                      ).then((_) => msgProvider.fetchConversations());
                    }
                  },
                  onLongPress: () {
                    if (!msgProvider.isSelectionMode) {
                      msgProvider.toggleSelectionMode();
                      msgProvider.toggleSelection(otherUser.id);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}