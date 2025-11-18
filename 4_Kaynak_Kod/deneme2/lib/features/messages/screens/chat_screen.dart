import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_summary_model.dart';
import '../../profile/screens/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final UserSummary otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // --- State Değişkenleri ---
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  // Future'ı nullable yapıyoruz, initState'de dolduracağız
  Future<List<Message>>? _messagesFuture;

  // Anlık güncellemeler için mesajları ayrıca bir listede tutuyoruz
  List<Message> _messages = [];
  bool _isSending = false;
  Timer? _timer;

  // --- Yaşam Döngüsü Metotları ---
  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında mesajları yükle
    _messagesFuture = _loadInitialMessages();

    // Periyodik olarak yeni mesajları kontrol et
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshMessages();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    // build metodu içinde Provider'a erişmek en güvenlisidir.
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user!.id;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            // Kişinin profiline git
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProfileScreen(
                  userId: widget.otherUser.id, // ProfilScreen'in userId kabul ettiğinden emin ol
              ),
            ));
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.otherUser.profilePictureUrl != null
                    ? NetworkImage(widget.otherUser.profilePictureUrl!)
                    : null,
                child: widget.otherUser.profilePictureUrl == null
                    ? Text(widget.otherUser.name[0]) : null,
              ),
              const SizedBox(width: 10),
              Text(widget.otherUser.name, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) {
                  return const LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Mesajlar yüklenemedi.'));
                }
                // Future'dan gelen ilk veriyi ve sonradan eklenenleri birleştirerek gösteriyoruz
                if (snapshot.hasData && _messages.isEmpty) {
                  _messages = snapshot.data!;
                }

                if (_messages.isEmpty) {
                  return const Center(child: Text('Sohbeti başlatın...'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message.sender.id == currentUserId;
                    return _buildMessageBubble(context, message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  // --- Yardımcı Fonksiyonlar ---
  Future<List<Message>> _loadInitialMessages() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await _apiService.markAsRead(otherUserId: widget.otherUser.id);
      final messages = await _apiService.getChatHistory(otherUserId: widget.otherUser.id);
      // Mesajlar yüklendikten hemen sonra en alta kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(isAnimated: false));
      return messages;
    }
    return [];
  }

  Future<void> _refreshMessages() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      final newMessages = await _apiService.getChatHistory(otherUserId: widget.otherUser.id);
      // Eğer yeni mesaj varsa ve ekranda bir değişiklik olacaksa, state'i güncelle
      if (mounted && newMessages.length != _messages.length) {
        setState(() {
          _messages = newMessages;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSending = true);
    final content = _messageController.text.trim();
    _messageController.clear();

    final sentMessage = await _apiService.sendMessage(receiverId: widget.otherUser.id, content: content);

    if (sentMessage != null) {
      setState(() {
        _messages.add(sentMessage);
      });
      _scrollToBottom();
    }
    setState(() => _isSending = false);
  }

  Future<void> _deleteMessage(BuildContext context, Message message) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mesajı Sil"),
        content: const Text("Bu mesaj sadece sizden silinecektir. Onaylıyor musunuz?"),
        actions: [
          TextButton(child: const Text("İptal"), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text("Sil", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmed == true && token != null) {
      final success = await _apiService.deleteMessage(messageId: message.id);
      if (success) {
        setState(() {
          _messages.remove(message);
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesaj silinirken bir hata oluştu.'), backgroundColor: Colors.red));
      }
    }
  }

  void _scrollToBottom({bool isAnimated = true}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (isAnimated) {
        _scrollController.animateTo(position, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  // --- Yardımcı UI Widget'ları ---
  Widget _buildMessageBubble(BuildContext context, Message message, bool isMe) {
    final theme = Theme.of(context);
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? theme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? theme.colorScheme.surface.withOpacity(0.5) : theme.cardColor);
    final textColor = isMe ? Colors.white : theme.textTheme.bodyLarge?.color;
    final borderRadius = isMe
        ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4))
        : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18));

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () {
          if (isMe) {
            _deleteMessage(context, message);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(color: color, borderRadius: borderRadius),
          child: Text(message.content, style: TextStyle(color: textColor, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05), spreadRadius: 5)]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Mesajınızı yazın...', border: InputBorder.none, filled: false),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}