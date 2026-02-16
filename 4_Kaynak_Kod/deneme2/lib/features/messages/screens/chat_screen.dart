// lib/features/chat/screens/chat_screen.dart

import 'dart:async';
import 'dart:ui'; // Blur için
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/message_provider.dart';
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

  Future<List<Message>>? _messagesFuture;
  List<Message> _messages = [];
  bool _isSending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadInitialMessages();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _refreshMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIC (Aynı kaldı) ---
  Future<List<Message>> _loadInitialMessages() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await _apiService.markAsRead(otherUserId: widget.otherUser.id);
      final messages = await _apiService.getChatHistory(otherUserId: widget.otherUser.id);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(isAnimated: false));
      return messages;
    }
    return [];
  }

  Future<void> _refreshMessages() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      final newMessages = await _apiService.getChatHistory(otherUserId: widget.otherUser.id);
      if (mounted && newMessages.length != _messages.length) {
        setState(() => _messages = newMessages);
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
      setState(() => _messages.add(sentMessage));
      _scrollToBottom();
      if (mounted) Provider.of<MessageProvider>(context, listen: false).fetchConversations();
    }
    setState(() => _isSending = false);
  }

  Future<void> _deleteMessage(BuildContext context, Message message) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Mesajı Sil"),
        content: const Text("Bu mesaj sadece sizden silinecektir."),
        actions: [
          TextButton(child: const Text("İptal"), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text("Sil", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmed == true && token != null) {
      final success = await _apiService.deleteMessage(messageId: message.id);
      if (success) {
        setState(() => _messages.remove(message));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu.'), backgroundColor: Colors.red));
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

  // --- UI KISMI (SADELEŞTİRİLDİ) ---
  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user!.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F7), // Sohbet arka planı
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Center(
            child: _GlassBackButton(onTap: () => Navigator.pop(context)),
          ),
        ),
        title: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.otherUser.id))),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${widget.otherUser.id}',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    backgroundImage: widget.otherUser.profilePictureUrl != null ? NetworkImage(widget.otherUser.profilePictureUrl!) : null,
                    child: widget.otherUser.profilePictureUrl == null
                        ? Text(widget.otherUser.name[0], style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.otherUser.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      Text("Çevrimiçi", style: TextStyle(fontSize: 12, color: Colors.green[400], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // --- DEĞİŞİKLİK 1: actions (3 nokta) KALDIRILDI ---
        actions: const [],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) return const LoadingIndicator();
                if (snapshot.hasError) return const Center(child: Text('Mesajlar yüklenemedi.'));
                if (snapshot.hasData && _messages.isEmpty) _messages = snapshot.data!;

                if (_messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Sohbeti başlatın...', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message.sender.id == currentUserId;
                    final bool isFirstInSequence = index == 0 || _messages[index - 1].sender.id != message.sender.id;
                    return _buildMessageBubble(context, message, isMe, isFirstInSequence);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(context, isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message message, bool isMe, bool isFirst) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (isMe) _deleteMessage(context, message);
        },
        child: Container(
          margin: EdgeInsets.only(top: isFirst ? 16 : 4, bottom: 4, left: isMe ? 50 : 0, right: isMe ? 0 : 50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isMe ? null : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}", // Placeholder saat
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Colors.white70),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.05), offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // --- DEĞİŞİKLİK 2: '+' (Ataş) Butonu KALDIRILDI ---

            // Input Alanı
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yaz...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Gönder Butonu
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: _isSending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Geri butonu
class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }
}