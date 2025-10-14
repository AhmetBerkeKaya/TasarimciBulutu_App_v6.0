// lib/features/showcase/widgets/comment_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/comment_model.dart';

class CommentCard extends StatefulWidget {
  final String postId;
  final Comment comment;
  final Function(String authorName, String commentId) onReply;
  final int nestingLevel;
  final bool isHighlighted;

  const CommentCard({
    super.key,
    required this.postId,
    required this.comment,
    required this.onReply,
    this.nestingLevel = 0,
    this.isHighlighted = false,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> with TickerProviderStateMixin {
  bool _showAllReplies = false;
  late AnimationController _likeAnimationController;
  late AnimationController _expandAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final provider = context.watch<ShowcaseProvider>();
    final currentUserId = context.read<AuthProvider>().user?.id;

    final post = provider.posts.firstWhere((p) => p.id == widget.postId);
    final currentComment = provider.findComment(post.comments, widget.comment.id);

    if (currentComment == null) {
      return const SizedBox.shrink();
    }

    final isLikedByMe = currentComment.likes.any((like) => like.userId == currentUserId);
    final isMyComment = currentComment.author.id == currentUserId;
    final hasReplies = currentComment.replies.isNotEmpty;
    final visibleReplies = _showAllReplies
        ? currentComment.replies
        : currentComment.replies.take(2).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        left: widget.nestingLevel * 16.0,
        top: widget.nestingLevel == 0 ? 12.0 : 8.0,
        bottom: 4.0,
      ),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? theme.primaryColor.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: widget.isHighlighted
            ? Border.all(color: theme.primaryColor.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(currentComment, theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentBubble(currentComment, theme, textTheme),
                      const SizedBox(height: 6),
                      _buildInteractionRow(
                          currentComment,
                          isLikedByMe,
                          isMyComment,
                          theme,
                          textTheme,
                          provider
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildLikesIndicator(currentComment, theme, textTheme),
            if (hasReplies) _buildRepliesSection(currentComment, theme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Comment comment, ThemeData theme) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: widget.nestingLevel == 0 ? 22 : 18,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage: comment.author.profilePictureUrl != null
                ? NetworkImage(comment.author.profilePictureUrl!)
                : null,
            child: comment.author.profilePictureUrl == null
                ? Text(
              comment.author.name.isNotEmpty
                  ? comment.author.name[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: widget.nestingLevel == 0 ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            )
                : null,
          ),
        ),
        if (comment.author.id == context.read<AuthProvider>().user?.id)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
              ),
              child: const Icon(
                Icons.check,
                size: 6,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentBubble(Comment comment, ThemeData theme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.brightness == Brightness.dark
                ? Colors.grey[850]!
                : Colors.grey[50]!,
            theme.brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.author.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeago.format(comment.createdAt, locale: 'tr'),
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[200]
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionRow(
      Comment comment,
      bool isLikedByMe,
      bool isMyComment,
      ThemeData theme,
      TextTheme textTheme,
      ShowcaseProvider provider,
      ) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _likeAnimation.value,
                child: _buildInteractionButton(
                  icon: isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: 'Beğen',
                  count: comment.likes.length,
                  isActive: isLikedByMe,
                  onPressed: () {
                    if (currentUserId != null) {
                      provider.toggleCommentLike(widget.postId, comment.id, currentUserId);
                      if (!isLikedByMe) {
                        _likeAnimationController.forward().then((_) {
                          _likeAnimationController.reverse();
                        });
                      }
                    }
                  },
                  theme: theme,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          _buildInteractionButton(
            icon: Icons.reply_outlined,
            label: 'Yanıtla',
            onPressed: () => widget.onReply(comment.author.name, comment.id),
            theme: theme,
          ),
          if (isMyComment) ...[
            const SizedBox(width: 16),
            _buildInteractionButton(
              icon: Icons.delete_outline,
              label: 'Sil',
              isDestructive: true,
              onPressed: () => _showDeleteConfirmationDialog(
                  context,
                  provider,
                  widget.postId,
                  comment.id
              ),
              theme: theme,
            ),
          ],
          const Spacer(),
          if (comment.replies.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${comment.replies.length} yanıt',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required ThemeData theme,
    int? count,
    bool isActive = false,
    bool isDestructive = false,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDestructive
                    ? Colors.red[600]
                    : isActive
                    ? theme.primaryColor
                    : Colors.grey[600],
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? theme.primaryColor : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikesIndicator(Comment comment, ThemeData theme, TextTheme textTheme) {
    if (comment.likes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLikesList(context, comment.likes),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.thumb_up,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  comment.likes.length.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepliesSection(Comment comment, ThemeData theme, TextTheme textTheme) {
    final visibleReplies = _showAllReplies
        ? comment.replies
        : comment.replies.take(2).toList();
    final hiddenCount = comment.replies.length - visibleReplies.length;

    return Column(
      children: [
        if (hiddenCount > 0 && !_showAllReplies)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showAllReplies = true;
                  });
                  _expandAnimationController.forward();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$hiddenCount yanıtı daha göster',
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: visibleReplies
                .map((reply) => CommentCard(
              postId: widget.postId,
              comment: reply,
              onReply: widget.onReply,
              nestingLevel: widget.nestingLevel + 1,
            ))
                .toList(),
          ),
        ),
        if (_showAllReplies && hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showAllReplies = false;
                  });
                  _expandAnimationController.reverse();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.expand_less,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Daha az göster',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      ShowcaseProvider provider,
      String postId,
      String commentId
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Yorumu Sil'),
          ],
        ),
        content: const Text(
          'Bu yorumu kalıcı olarak silmek istediğinizden emin misiniz? '
              'Bu işlem geri alınamaz ve tüm yanıtlar da silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.deleteComment(postId, commentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showLikesList(BuildContext context, List<dynamic> likes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Beğenenler (${likes.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Beğeni listesi burada gösterilecek
              // TODO: Beğeni modelinden kullanıcı bilgilerini çek ve listele
              const Text('Beğeni detayları yakında eklenecek...'),
            ],
          ),
        );
      },
    );
  }
}