// lib/features/showcase/screens/showcase_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart'; // YENİ: Paylaşma paketi

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/showcase_post_model.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../widgets/comment_card.dart'; // YENİ: CommentCard'ı import ediyoruz
import '../widgets/post_card.dart';

class ShowcaseDetailScreen extends StatelessWidget {
  final ShowcasePost post;
  const ShowcaseDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isLikedByMe = post.likes.any((like) => like.userId == currentUserId);
    final postCard = PostCard(post: post);
    final postContent = postCard.buildContentArea(context, post.thumbnailUrl ?? '');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(post.title, style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
              background: postContent,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: post.owner.profilePictureUrl != null && post.owner.profilePictureUrl!.isNotEmpty ? NetworkImage("${post.owner.profilePictureUrl!}?v=${DateTime.now().millisecondsSinceEpoch}") : null,
                      child: post.owner.profilePictureUrl == null || post.owner.profilePictureUrl!.isEmpty ? Text(post.owner.name.isNotEmpty ? post.owner.name[0].toUpperCase() : 'U') : null,
                    ),
                    title: Text(post.owner.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Text(timeago.format(post.createdAt, locale: 'tr'), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ),
                  if (post.description != null && post.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      post.description!,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (post.likes.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('${post.likes.length} beğeni', style: theme.textTheme.bodySmall),
                      ),
                      const Spacer(),
                      if (post.comments.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text('${post.comments.length} yorum', style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      postCard.buildActionButton(
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
                      postCard.buildActionButton(
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
                          }
                      ),
                      // ========================================================
                      // ===         DÜZELTME: PAYLAŞ BUTONU AKTİF EDİLDİ       ===
                      // ========================================================
                      postCard.buildActionButton(
                          context: context,
                          icon: Icons.share_outlined,
                          label: 'Paylaş',
                          onTap: () {
                            // TODO: Bu URL'yi projenizin canlıya çıktığındaki web adresiyle değiştirin.
                            final postUrl = "https://tasarimcibulutu.com/showcase/${post.id}";
                            Share.share(
                              'Tasarımcı Bulutu\'ndaki bu harika projeye göz atın: ${post.title}\n\n$postUrl',
                              subject: post.title,
                            );
                          }
                      ),
                      // ========================================================
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Yorumlar (${post.comments.length})',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ========================================================
          // ===        DÜZELTME: YORUM LİSTESİ GÜNCELLENDİ         ===
          // ========================================================
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final comment = post.comments[index];
                // Artık ListTile yerine CommentCard kullanıyoruz.
                return CommentCard(
                  postId: post.id,
                  comment: comment,
                  // Detay sayfasında yoruma yanıt verme özelliğini CommentBottomSheet'e yönlendirebiliriz.
                  onReply: (authorName, commentId) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => CommentBottomSheet(post: post),
                    );
                  },
                );
              },
              childCount: post.comments.length,
            ),
          ),
          // ========================================================
        ],
      ),
    );
  }
}