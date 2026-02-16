// lib/features/showcase/widgets/post_card.dart

import 'package:deneme2/data/models/showcase_post_model.dart';
import 'package:deneme2/features/showcase/screens/three_d_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../screens/showcase_detail_screen.dart';
import 'comment_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final ShowcasePost post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  // Animasyon Kontrolcüsü
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnimation;

  // Anlık değişim için yerel state (Optimistic UI)
  bool? _isLikedLocal;
  int? _likeCountLocal;

  @override
  void initState() {
    super.initState();
    // Kalp atışı animasyonu (Büyüyüp küçülme)
    _likeAnimController = AnimationController(
      duration: const Duration(milliseconds: 150), // Çok hızlı tepki
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _likeAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  // Backend sebepleri
  static const List<String> reportReasons = [
    "Spam / Reklam",
    "Uygunsuz İçerik (+18, Şiddet)",
    "Telif Hakkı İhlali",
    "Sahte / Yanıltıcı",
    "Diğer"
  ];

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

  // --- BEĞENİ BUTONU MANTIĞI (ANİMASYONLU & HIZLI) ---
  void _handleLike(String currentUserId) {
    // 1. Animasyonu Oynat (Bounce)
    _likeAnimController.forward().then((_) => _likeAnimController.reverse());

    // 2. State'i Anlık Güncelle (Optimistic Update)
    setState(() {
      if (_isLikedLocal!) {
        _isLikedLocal = false;
        _likeCountLocal = (_likeCountLocal ?? 0) - 1;
      } else {
        _isLikedLocal = true;
        _likeCountLocal = (_likeCountLocal ?? 0) + 1;
      }
    });

    // 3. Backend'e İsteği Gönder (Arkada çalışsın)
    Provider.of<ShowcaseProvider>(context, listen: false)
        .toggleLike(widget.post.id, currentUserId);
  }

  // ... Diğer Metotlar (Report, Delete vb.) aynı kalacak, sadece UI güncellemeleri aşağıda ...
  void _showReportDialog(BuildContext context, String postId) {
    // ... Eski kodun aynısı ...
    String selectedReason = reportReasons[0];
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Gönderiyi Bildir'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lütfen şikayet sebebini seçin:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ...reportReasons.map((reason) => RadioListTile<String>(
                      title: Text(reason, style: const TextStyle(fontSize: 14)),
                      value: reason,
                      groupValue: selectedReason,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) => setState(() => selectedReason = value!),
                    )),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Ek Açıklama (Opsiyonel)', border: OutlineInputBorder(), isDense: true),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _submitReport(context, postId, selectedReason, descriptionController.text);
                  },
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitReport(BuildContext context, String postId, String reason, String description) async {
    final success = await Provider.of<ShowcaseProvider>(context, listen: false).reportPost(postId, reason, description);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Bildiriminiz alındı.' : 'Bir hata oluştu.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  void _showPostOptions(BuildContext context, String postId, bool isMyPost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (isMyPost)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Gönderiyi Sil', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showDeleteConfirmationDialog(context, postId);
                  },
                ),
              if (!isMyPost)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Gönderiyi Bildir'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showReportDialog(context, postId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gönderiyi Sil'),
        content: const Text('Bu gönderiyi kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(child: const Text('İptal'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ShowcaseProvider>().deletePost(postId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final correctedThumbnailUrl = _getCorrectImageUrl(widget.post.thumbnailUrl);
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;

    // Veri Tutarlılığı: Eğer yerel state (kullanıcı bastıysa) varsa onu kullan, yoksa veritabanından geleni.
    // Bu sayede sayfa yenilendiğinde gerçek veriyi alırız ama basınca anlık tepki veririz.
    final bool realIsLiked = widget.post.likes.any((like) => like.userId == currentUserId);
    final int realLikeCount = widget.post.likes.length;

    // İlk açılışta veya senkronizasyonda yerel değişkeni güncelle (eğer kullanıcı henüz etkileşime girmediyse)
    _isLikedLocal ??= realIsLiked;
    _likeCountLocal ??= realLikeCount;

    // Eğer provider'dan yeni veri geldiyse ve bizim local işlemimizle çelişmiyorsa senkronize etmeye çalışabiliriz
    // Ama basitlik için etkileşimden sonra local'i öncelikli kılıyoruz.
    // *Not: Daha gelişmiş bir yapı için post ID'sine göre cache mekanizması kurulabilir.*

    final isMyPost = widget.post.owner.id == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ShowcaseDetailScreen(post: widget.post),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: widget.post.owner.profilePictureUrl != null ? NetworkImage(widget.post.owner.profilePictureUrl!) : null,
                  child: widget.post.owner.profilePictureUrl == null ? Text(widget.post.owner.name.isNotEmpty ? widget.post.owner.name[0].toUpperCase() : 'U') : null,
                ),
                title: Text(widget.post.owner.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(timeago.format(widget.post.createdAt, locale: 'tr'), style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _showPostOptions(context, widget.post.id, isMyPost),
                ),
              ),
              const SizedBox(height: 8),

              Text(widget.post.title, style: textTheme.titleLarge),
              if (widget.post.description != null && widget.post.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(widget.post.description!, style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),

              buildContentArea(context, correctedThumbnailUrl),

              const SizedBox(height: 8),
              // İstatistikler (Yerel Değişkenleri Kullanıyoruz)
              Row(
                children: [
                  if ((_likeCountLocal ?? 0) > 0) Text('${_likeCountLocal} beğeni', style: textTheme.bodySmall),
                  const Spacer(),
                  if (widget.post.comments.isNotEmpty) Text('${widget.post.comments.length} yorum', style: textTheme.bodySmall),
                ],
              ),
              const Divider(),

              // --- AKSİYON BUTONLARI ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // BEĞEN BUTONU (ÖZEL)
                  InkWell(
                    onTap: () {
                      if (currentUserId != null) {
                        _handleLike(currentUserId);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Row(
                        children: [
                          // Scale Transition ile Animasyon
                          ScaleTransition(
                            scale: _likeScaleAnimation,
                            child: Icon(
                              _isLikedLocal! ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isLikedLocal! ? Colors.red : Colors.grey[700],
                              size: 24, // Bir tık büyüttük
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              'Beğen',
                              style: TextStyle(
                                  color: _isLikedLocal! ? Colors.red : Colors.grey[700],
                                  fontWeight: FontWeight.w600
                              )
                          ),
                        ],
                      ),
                    ),
                  ),

                  buildActionButton(
                      context: context,
                      icon: Icons.comment_outlined,
                      label: 'Yorum Yap',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => CommentBottomSheet(post: widget.post),
                        );
                      }
                  ),
                  buildActionButton(
                      context: context,
                      icon: Icons.share_outlined,
                      label: 'Paylaş',
                      onTap: () {
                        Share.share('Tasarımcı Bulutu\'ndaki projeye göz at: ${widget.post.title}');
                      }
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildContentArea(BuildContext context, String imageUrl) {
    // ... İçerik alanı (Resim/3D) değişmedi, olduğu gibi kopyalıyorum ...
    switch (widget.post.processingStatus) {
      case ProcessingStatus.PROCESSING:
      case ProcessingStatus.PENDING:
        return Container(height: 250, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator()));
      case ProcessingStatus.FAILED:
        return Container(height: 250, color: Colors.red.shade50, child: const Center(child: Icon(Icons.error, color: Colors.red)));
      case ProcessingStatus.COMPLETED:
        if (imageUrl.isNotEmpty) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: widget.post.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 250, color: Colors.grey)),
                ),
              ),
              if (widget.post.modelUrn != null && widget.post.modelUrn!.isNotEmpty)
                Positioned(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ThreeDViewerScreen(modelUrn: widget.post.modelUrn!, title: widget.post.title),
                        ));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Icon(Icons.view_in_ar, color: Colors.white, size: 18), SizedBox(width: 6), Text('3D GÖRÜNTÜLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget buildActionButton({required BuildContext context, required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [Icon(icon, color: color ?? Colors.grey[700], size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: color ?? Colors.grey[700], fontWeight: FontWeight.w600))],
        ),
      ),
    );
  }
}