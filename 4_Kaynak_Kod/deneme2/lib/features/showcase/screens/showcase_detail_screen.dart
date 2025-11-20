// lib/features/showcase/screens/showcase_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/showcase_post_model.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../widgets/comment_card.dart';
import '../widgets/post_card.dart';

class ShowcaseDetailScreen extends StatelessWidget {
  final ShowcasePost post;
  const ShowcaseDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.read<AuthProvider>().user?.id;

    // PostCard instance'ı oluşturup metodlarını kullanacağız
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
                  // --- DÜZELTME BURADA BAŞLIYOR ---
                  // İstatistikleri ve Butonları Consumer ile sarmaladık.
                  // Böylece Provider değişince sadece burası güncellenir.
                  Consumer<ShowcaseProvider>(
                    builder: (context, provider, child) {
                      // Güncel post verisini provider'daki listeden buluyoruz
                      // Eğer bulamazsak (silinmişse vs) parametre olarak gelen 'post'u kullanırız.
                      final currentPost = provider.posts.firstWhere(
                            (p) => p.id == post.id,
                        orElse: () => post,
                      );

                      final isLiked = currentPost.likes.any((like) => like.userId == currentUserId);
                      final likeCount = currentPost.likes.length;
                      final commentCount = currentPost.comments.length;

                      return Column(
                        children: [
                          Row(
                            children: [
                              if (likeCount > 0) Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text('$likeCount beğeni', style: theme.textTheme.bodySmall),
                              ),
                              const Spacer(),
                              if (commentCount > 0) Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text('$commentCount yorum', style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              postCard.buildActionButton(
                                context: context,
                                icon: isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                label: 'Beğen',
                                color: isLiked ? theme.primaryColor : Colors.grey[700],
                                onTap: () {
                                  if (currentUserId != null) {
                                    provider.toggleLike(post.id, currentUserId);
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
                                      builder: (ctx) => CommentBottomSheet(post: currentPost),
                                    );
                                  }
                              ),
                              postCard.buildActionButton(
                                  context: context,
                                  icon: Icons.share_outlined,
                                  label: 'Paylaş',
                                  onTap: () {
                                    final postUrl = "https://tasarimcibulutu.com/showcase/${post.id}";
                                    Share.share(
                                      'Tasarımcı Bulutu\'ndaki bu harika projeye göz atın: ${post.title}\n\n$postUrl',
                                      subject: post.title,
                                    );
                                  }
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  // --- DÜZELTME BURADA BİTİYOR ---

                  const Divider(),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Consumer<ShowcaseProvider>( // Yorum başlığı için de Consumer ekledik (sayı değişebilir)
                builder: (context, provider, child) {
                  final currentPost = provider.posts.firstWhere((p) => p.id == post.id, orElse: () => post);
                  return Text(
                    'Yorumlar (${currentPost.comments.length})',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),

          // Yorum Listesi (Burası da güncel veriyi almalı)
          Consumer<ShowcaseProvider>(
            builder: (context, provider, child) {
              final currentPost = provider.posts.firstWhere((p) => p.id == post.id, orElse: () => post);
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final comment = currentPost.comments[index];
                    return CommentCard(
                      postId: post.id,
                      comment: comment,
                      onReply: (authorName, commentId) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => CommentBottomSheet(post: currentPost),
                        );
                      },
                    );
                  },
                  childCount: currentPost.comments.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}