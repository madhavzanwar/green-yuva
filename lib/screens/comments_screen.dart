import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;
  final AppUser currentUser;
  final String schoolId;

  const CommentsScreen({
    Key? key,
    required this.post,
    required this.currentUser,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final PostService _postService = PostService();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _commentAdded = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoading = true);
      final comments = await _postService.getComments(widget.schoolId, widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = Comment(
        id: const Uuid().v4(),
        userId: widget.currentUser.id,
        userName: widget.currentUser.displayName,
        text: commentText,
        timestamp: DateTime.now(),
      );

      await _postService.addComment(widget.schoolId, widget.post.id, comment);
      _commentController.clear();

      await _loadComments();
      _commentAdded = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.solidBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.butterYellow, width: 2.0),
            ),
            content: Text(
              'Comment shared with campus hub! +5 Karma Coins',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.solidBlack,
            content: Text('Failed to add comment: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () => Navigator.pop(context, _commentAdded),
            ),
          ),
        ),
        title: Text(
          'Campus Discussion (${_comments.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: Column(
          children: [
            // Original Post Context NeoCard
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: NeoCard(
                color: AppColors.cardWhite,
                radius: 16,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.butterYellow,
                            border: Border.all(color: AppColors.solidBlack, width: 1.8),
                          ),
                          child: const Icon(Icons.person, size: 18, color: AppColors.solidBlack),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.post.userId == widget.currentUser.id
                                ? 'Your Post'
                                : 'Student Post',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.electricMint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.solidBlack, width: 1.5),
                          ),
                          child: Text(
                            'Original',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.solidBlack.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Comments List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.solidBlack))
                  : _comments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: NeoCard(
                              color: AppColors.pureWhite,
                              radius: 20,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.butterYellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.solidBlack, width: 2.0),
                                    ),
                                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.solidBlack),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No comments yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.solidBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Start the conversation! Leave your thoughts or tips below.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: AppColors.solidBlack.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentCard(comment);
                          },
                        ),
            ),

            // Input Bar at bottom
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                border: const Border(
                  top: BorderSide(color: AppColors.solidBlack, width: 2.0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(0, -2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.paperCream,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppColors.solidBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Share your perspective...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _addComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: _isSubmitting
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.solidBlack),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: AppColors.solidBlack, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoCard(
        color: AppColors.pureWhite,
        radius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.electricMint,
                    border: Border.all(color: AppColors.solidBlack, width: 1.6),
                  ),
                  child: Center(
                    child: Text(
                      comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      Text(
                        _formatTimestamp(comment.timestamp),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.solidBlack.withValues(alpha: 0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.solidBlack.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
