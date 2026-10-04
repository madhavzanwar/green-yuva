import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';

class PostCard extends StatelessWidget {
  final PostWithUser postWithUser;
  final AppUser currentUser;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback? onDelete;

  const PostCard({
    Key? key,
    required this.postWithUser,
    required this.currentUser,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final post = postWithUser.post;
    final bool isOwnPost = post.userId == currentUser.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: NeoCard(
        color: AppColors.pureWhite,
        radius: 18,
        borderWidth: 2.0,
        shadowOffset: const Offset(3.0, 3.5),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.butterYellow,
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (isOwnPost ? 'You' : postWithUser.userName).isNotEmpty
                          ? (isOwnPost ? 'Y' : postWithUser.userName[0].toUpperCase())
                          : 'U',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnPost ? 'You' : postWithUser.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.solidBlack.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.solidBlack),
                    onSelected: (value) {
                      if (value == 'delete' && onDelete != null) {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Post',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content text
            Text(
              post.content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.solidBlack.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),

            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.network(
                    post.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        width: double.infinity,
                        color: AppColors.paperCream,
                        child: const Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.solidBlack),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action row
            Row(
              children: [
                _buildActionButton(
                  icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '${post.likes.length}',
                  color: liked ? Colors.red : AppColors.solidBlack,
                  onPressed: onLike,
                ),
                const SizedBox(width: 14),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentCount}',
                  color: AppColors.solidBlack,
                  onPressed: onComment,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: saved ? AppColors.solidBlack : AppColors.solidBlack.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  onPressed: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.paperCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
          ),
          title: Text(
            'Delete Post',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.solidBlack,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.solidBlack,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.solidBlack, width: 1.8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
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
