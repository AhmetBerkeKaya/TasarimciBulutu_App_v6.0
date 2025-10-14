import 'package:deneme2/data/models/showcase_post_model.dart';
import 'package:deneme2/features/showcase/screens/image_viewer_screen.dart';
import 'package:deneme2/features/showcase/screens/three_d_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import 'comment_bottom_sheet.dart';

class PostCard extends StatelessWidget {
  final ShowcasePost post;

  const PostCard({super.key, required this.post});

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

  void _showPostOptions(BuildContext context, String postId, bool isMyPost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Gönderiyi Bildir'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bildiriminiz alındı.'), backgroundColor: Colors.orange),
                  );
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
        content: const Text('Bu gönderiyi kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ShowcaseProvider>().deletePost(postId).then((success) {
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gönderi başarıyla silindi.'), backgroundColor: Colors.green),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gönderi silinirken bir hata oluştu.'), backgroundColor: Colors.red),
                  );
                }
              });
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

    final correctedThumbnailUrl = _getCorrectImageUrl(post.thumbnailUrl);

    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isLikedByMe = post.likes.any((like) => like.userId == currentUserId);
    final isMyPost = post.owner.id == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          if (post.processingStatus == ProcessingStatus.COMPLETED) {
            // ================== SON DÜZELTME BURADA ==================
            // 3D Görüntüleyiciye artık `modelUrn`'yi gönderiyoruz.
            if (post.modelUrn != null && post.modelUrn!.isNotEmpty) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ThreeDViewerScreen(
                    modelUrn: post.modelUrn!,
                    title: post.title
                ),
              ));
            }
            // ==========================================================
            else if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty) {
              // Resim görüntüleyiciye tıklama
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageViewerScreen(imageUrl: correctedThumbnailUrl, heroTag: post.id)));
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: post.owner.profilePictureUrl != null ? NetworkImage(post.owner.profilePictureUrl!) : null,
                  child: post.owner.profilePictureUrl == null ? Text(post.owner.name.isNotEmpty ? post.owner.name[0].toUpperCase() : 'U') : null,
                ),
                title: Text(post.owner.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(timeago.format(post.createdAt, locale: 'tr'), style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _showPostOptions(context, post.id, isMyPost),
                ),
              ),
              const SizedBox(height: 8),

              Text(post.title, style: textTheme.titleLarge),
              if (post.description != null && post.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.description!,
                  style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),

              _buildContentArea(context, correctedThumbnailUrl),

              const SizedBox(height: 8),
              Row(
                children: [
                  if (post.likes.isNotEmpty) Text('${post.likes.length} beğeni', style: textTheme.bodySmall),
                  const Spacer(),
                  if (post.comments.isNotEmpty) Text('${post.comments.length} yorum', style: textTheme.bodySmall),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: isLikedByMe ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                    label: 'Beğen',
                    color: isLikedByMe ? theme.primaryColor : Colors.grey[700],
                    onTap: () {
                      if (currentUserId != null) {
                        Provider.of<ShowcaseProvider>(context, listen: false).toggleLike(post.id, currentUserId);
                      }
                    },
                  ),
                  _buildActionButton(
                      context: context,
                      icon: Icons.comment_outlined,
                      label: 'Yorum Yap',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => CommentBottomSheet(post: post),
                        );
                      }),
                  _buildActionButton(
                      context: context,
                      icon: Icons.share_outlined,
                      label: 'Paylaş',
                      onTap: () {
                        // TODO: Paylaşma işlevselliği eklenecek
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, String imageUrl) {
    switch (post.processingStatus) {
      case ProcessingStatus.PROCESSING:
      case ProcessingStatus.PENDING:
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Modeliniz işleniyor..."),
                Text("Bu işlem birkaç dakika sürebilir.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      case ProcessingStatus.FAILED:
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 16),
                Text("Model işlenirken bir hata oluştu.", style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      case ProcessingStatus.COMPLETED:
        if (imageUrl.isNotEmpty) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: post.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("THUMBNAIL HATASI: URL -> $imageUrl, Hata -> $error");
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Resim yüklenemedi", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ================== SON DÜZELTME BURADA ==================
              // `modelUrn`'yi kontrol ediyoruz.
              if (post.modelUrn != null && post.modelUrn!.isNotEmpty)
              // ==========================================================
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('3D GÖRÜNÜM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color ?? Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
