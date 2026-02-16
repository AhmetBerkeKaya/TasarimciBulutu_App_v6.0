// lib/features/showcase/screens/showcase_detail_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/showcase_post_model.dart';
import '../widgets/comment_bottom_sheet.dart';
import 'three_d_viewer_screen.dart';

class ShowcaseDetailScreen extends StatefulWidget {
  final ShowcasePost post;

  const ShowcaseDetailScreen({super.key, required this.post});

  @override
  State<ShowcaseDetailScreen> createState() => _ShowcaseDetailScreenState();
}

class _ShowcaseDetailScreenState extends State<ShowcaseDetailScreen> with SingleTickerProviderStateMixin {

  // --- ANİMASYON VE STATE YÖNETİMİ ---
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnimation;

  // Anlık değişim için yerel değişkenler (Optimistic UI)
  bool? _isLikedLocal;
  int? _likeCountLocal;

  // Şikayet Sebepleri
  static const List<String> reportReasons = [
    "Spam / Reklam",
    "Uygunsuz İçerik (+18, Şiddet)",
    "Telif Hakkı İhlali",
    "Sahte / Yanıltıcı",
    "Diğer"
  ];

  @override
  void initState() {
    super.initState();
    // Kalp atışı animasyonu
    _likeAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // 1.0 -> 1.5 -> 1.0 (Büyüyüp küçülme efekti)
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeAnimController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  // Beğeni İşlemi (Anlık Tepki)
  void _handleLike(String currentUserId) {
    // 1. Animasyonu tetikleme
    _likeAnimController.reset();
    _likeAnimController.forward();

    // 2. Arayüzü anında güncelleme
    setState(() {
      if (_isLikedLocal!) {
        _isLikedLocal = false;
        _likeCountLocal = (_likeCountLocal ?? 0) - 1;
      } else {
        _isLikedLocal = true;
        _likeCountLocal = (_likeCountLocal ?? 0) + 1;
      }
    });

    // 3. Sunucuya isteği arkada gönderme
    Provider.of<ShowcaseProvider>(context, listen: false)
        .toggleLike(widget.post.id, currentUserId);
  }

  String _getCorrectImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    const marker = '.amazonaws.com';
    final index = url.indexOf(marker);
    if (index != -1) {
      final nextCharIndex = index + marker.length;
      if (nextCharIndex < url.length && url[nextCharIndex] != '/') {
        return url.substring(0, nextCharIndex) + '/' + url.substring(nextCharIndex);
      }
    }
    return url;
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = reportReasons[0];
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Gönderiyi Bildir', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lütfen şikayet sebebini seçin:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ...reportReasons.map((reason) => RadioListTile<String>(
                      title: Text(reason, style: const TextStyle(fontSize: 14)),
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: theme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) => setState(() => selectedReason = value!),
                    )),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Ek Açıklama',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Provider.of<ShowcaseProvider>(context, listen: false)
                        .reportPost(widget.post.id, selectedReason, descriptionController.text)
                        .then((success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success ? 'Bildirim alındı.' : 'Hata oluştu.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ));
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sil'),
        content: const Text('Bu projeyi silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ShowcaseProvider>().deletePost(widget.post.id).then((success) {
                if (success && context.mounted) {
                  Navigator.pop(context); // Detay ekranından çık
                }
              });
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final correctedImageUrl = _getCorrectImageUrl(widget.post.thumbnailUrl);

    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isMyPost = widget.post.owner.id == currentUserId;

    // Provider'dan gelen güncel veriyi al (Senkronizasyon için)
    final providerPost = context.select<ShowcaseProvider, ShowcasePost?>(
            (p) => p.posts.where((element) => element.id == widget.post.id).firstOrNull
    ) ?? widget.post;

    // Yerel değişkenleri başlat (eğer null ise veritabanından al)
    final bool realIsLiked = providerPost.likes.any((like) => like.userId == currentUserId);
    _isLikedLocal ??= realIsLiked;
    _likeCountLocal ??= providerPost.likes.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _buildGlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: _buildGlassMenuButton(context, isMyPost),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. TAM EKRAN GÖRSEL
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: widget.post.id,
              child: Image.network(
                correctedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
              ),
            ),
          ),

          // 2. DETAY PANELİ
          DraggableScrollableSheet(
            initialChildSize: 0.60,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181A20) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  children: [
                    // Tutamaç
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Başlık
                    Text(
                      widget.post.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kullanıcı Satırı
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.primaryColor.withOpacity(0.5), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: widget.post.owner.profilePictureUrl != null
                                ? NetworkImage(widget.post.owner.profilePictureUrl!)
                                : null,
                            child: widget.post.owner.profilePictureUrl == null
                                ? Text(widget.post.owner.name[0].toUpperCase())
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.owner.name,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              timeago.format(widget.post.createdAt, locale: 'tr'),
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // 3D Model Butonu (Varsa)
                        if (widget.post.modelUrn != null)
                          _build3DButton(context),
                      ],
                    ),

                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                    // Açıklama
                    Text(
                      "Proje Hakkında",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.description ?? "Açıklama bulunmuyor.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // İstatistikler ve Aksiyonlar (Modern Bar)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // --- ÖZEL BEĞEN BUTONU (ANİMASYONLU) ---
                          InkWell(
                            onTap: () {
                              if (currentUserId != null) _handleLike(currentUserId);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  ScaleTransition(
                                    scale: _likeScaleAnimation,
                                    child: Icon(
                                      _isLikedLocal! ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: _isLikedLocal! ? Colors.red : Colors.grey,
                                      size: 30, // Biraz daha büyük
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      "${_likeCountLocal}",
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)
                                  ),
                                ],
                              ),
                            ),
                          ),

                          _buildDetailAction(
                            context,
                            icon: Icons.chat_bubble_outline_rounded,
                            color: theme.primaryColor,
                            label: "${providerPost.comments.length}",
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => CommentBottomSheet(post: widget.post),
                              );
                            },
                          ),
                          _buildDetailAction(
                            context,
                            icon: Icons.share_rounded,
                            color: Colors.green,
                            label: "Paylaş",
                            onTap: () {
                              Share.share('Bu projeye göz at: ${widget.post.title}');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), // Hafif koyu arka plan
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMenuButton(BuildContext context, bool isMyPost) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'delete') _showDeleteDialog(context);
              if (value == 'report') _showReportDialog(context);
            },
            itemBuilder: (context) => [
              if (isMyPost)
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 10), Text('Projeyi Sil', style: TextStyle(color: Colors.red))])),
              if (!isMyPost)
                const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 20), SizedBox(width: 10), Text('Bildir')])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ThreeDViewerScreen(
            modelUrn: widget.post.modelUrn!,
            title: widget.post.title,
          ),
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)], // Canlı Mavi Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('3D İncele', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailAction(BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}