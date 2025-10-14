// lib/features/showcase/widgets/comment_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/showcase_post_model.dart';
import 'comment_card.dart';

enum CommentSortType { newest, oldest, mostLiked }

class CommentBottomSheet extends StatefulWidget {
  final ShowcasePost post;

  const CommentBottomSheet({super.key, required this.post});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet>
    with TickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  CommentSortType _sortType = CommentSortType.newest;

  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeAnimationController);

    _slideAnimationController.forward();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    FocusScope.of(context).unfocus();

    final success = await context.read<ShowcaseProvider>().addComment(
      widget.post.id,
      _commentController.text.trim(),
      parentCommentId: _replyingToCommentId,
    );

    if (mounted) {
      if (success) {
        _commentController.clear();
        _cancelReply();
        _showSuccessAnimation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Yorum gönderilemedi. Tekrar deneyin.'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      setState(() => _isSending = false);
    }
  }

  void _showSuccessAnimation() {
    // Basit bir başarı animasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Yorum başarıyla gönderildi!'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleReply(String authorName, String commentId) {
    setState(() {
      _replyingToAuthorName = authorName;
      _replyingToCommentId = commentId;
      _focusNode.requestFocus();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToAuthorName = null;
      _replyingToCommentId = null;
      _focusNode.unfocus();
    });
  }

  List<Comment> _getSortedComments(List<Comment> comments) {
    final sortedComments = List<Comment>.from(comments);

    switch (_sortType) {
      case CommentSortType.newest:
        sortedComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CommentSortType.oldest:
        sortedComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CommentSortType.mostLiked:
        sortedComments.sort((a, b) => b.likes.length.compareTo(a.likes.length));
        break;
    }

    return sortedComments;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comments = context.select(
          (ShowcaseProvider p) => p.posts
          .firstWhere((p) => p.id == widget.post.id)
          .comments,
    );

    final sortedComments = _getSortedComments(comments);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(theme, comments.length),
                  _buildSortingRow(theme),
                  const Divider(height: 1),
                  Expanded(
                    child: comments.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildCommentsList(sortedComments, scrollController),
                  ),
                  _buildCommentInput(theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int commentCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.comment_outlined,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yorumlar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$commentCount yorum',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortingRow(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: [
          Text(
            'Sırala:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip(
                    'En Yeni',
                    CommentSortType.newest,
                    Icons.schedule,
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _buildSortChip(
                    'En Eski',
                    CommentSortType.oldest,
                    Icons.history,
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _buildSortChip(
                    'En Çok Beğenilen',
                    CommentSortType.mostLiked,
                    Icons.favorite,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(
      String label,
      CommentSortType sortType,
      IconData icon,
      ThemeData theme,
      ) {
    final isSelected = _sortType == sortType;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _sortType = sortType;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primaryColor
                  : theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : theme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? Colors.white : theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz hiç yorum yok',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk yorumu sen yap ve konuşmayı başlat!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _focusNode.requestFocus(),
            icon: const Icon(Icons.edit),
            label: const Text('Yorum Yaz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<Comment> comments, ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: comments.length,
      itemBuilder: (ctx, index) {
        final comment = comments[index];
        final isTopComment = _sortType == CommentSortType.mostLiked &&
            index == 0 &&
            comment.likes.isNotEmpty;

        return Column(
          children: [
            if (isTopComment)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.2),
                      Colors.orange.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'En Çok Beğenilen Yorum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
            CommentCard(
              postId: widget.post.id,
              comment: comment,
              onReply: _handleReply,
              isHighlighted: isTopComment,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToAuthorName != null) _buildReplyIndicator(theme),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _replyingToAuthorName != null
                            ? '@$_replyingToAuthorName kişisine yanıt ver...'
                            : 'Bir yorum ekle...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  width: 48,
                  child: _isSending
                      ? Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                      : Material(
                    color: theme.primaryColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _sendComment,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyIndicator(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '@$_replyingToAuthorName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' kişisine yanıt veriliyor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cancelReply,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}