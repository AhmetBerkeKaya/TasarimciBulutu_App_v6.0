// lib/features/messages/screens/message_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/message_model.dart';
import 'chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  // Veriyi FutureBuilder'da yönetmek için bir Future nesnesi tutuyoruz.
  late Future<List<Message>> _conversationsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında konuşmaları yükle
    _loadConversations();
  }

  // Konuşmaları yükleyen veya yenileyen ana fonksiyon
  Future<void> _loadConversations() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      // Future'ı setState içinde güncellemek, FutureBuilder'ın yeniden tetiklenmesini sağlar
      setState(() {
        _conversationsFuture = _apiService.getConversations();
      });
    } else {
      // Token yoksa boş bir liste göster
      setState(() {
        _conversationsFuture = Future.value([]);
      });
    }
  }

  // Tarihi daha kullanıcı dostu formatta gösteren yardımcı fonksiyon
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (date == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (date == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('dd.MM.yy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: RefreshIndicator(
        onRefresh: () async => _loadConversations(),
        child: FutureBuilder<List<Message>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator();
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return EmptyState(
                icon: Icons.message_outlined,
                message: 'Mesaj Kutunuz Boş',
                suggestion: 'Birisiyle mesajlaşmaya başladığınızda burada görünecektir.',
                actionButton: ElevatedButton.icon(
                  onPressed: _loadConversations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
              );
            }

            final conversations = snapshot.data!;
            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                final lastMessage = conversations[index];
                final otherUser = lastMessage.sender.id == currentUserId
                    ? lastMessage.receiver
                    : lastMessage.sender;

                final bool isUnread = !lastMessage.isRead && lastMessage.sender.id != currentUserId;

                return Dismissible(
                  key: ValueKey(lastMessage.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Silmeden önce kullanıcıdan onay alıyoruz
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Konuşmayı Sil'),
                        content: Text('"${otherUser.name}" ile olan konuşmayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sil', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final success = await _apiService.deleteConversation(
                        otherUserId: otherUser.id,
                      );
                      if (success) {
                        // İşlem backend'de başarılı olursa, listeyi yenilemek için Future'ı tekrar tetikle
                        _loadConversations();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Konuşma silindi.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hata: Konuşma silinemedi.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return success;
                    }
                    return false;
                  },
                  background: Container(
                    color: Colors.red.shade700,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: otherUser.profilePictureUrl != null && otherUser.profilePictureUrl!.isNotEmpty
                          ? NetworkImage(otherUser.profilePictureUrl!) // Sabit IP adresi kaldırıldı
                          : null,
                      child: otherUser.profilePictureUrl == null || otherUser.profilePictureUrl!.isEmpty
                          ? Text(otherUser.name.isNotEmpty ? otherUser.name.substring(0, 1).toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(
                      otherUser.name,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).colorScheme.secondary,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(lastMessage.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isUnread ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isUnread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          )
                      ],
                    ),
                    onTap: () async {
                      // Sohbet ekranına git
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(otherUser: otherUser),
                        ),
                      );
                      // Sohbet ekranından geri dönüldüğünde okunmadı durumunu güncellemek için listeyi yenile
                      _loadConversations();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}