import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class ActivityCard extends StatefulWidget {
  final Activity activity;
  final AppUser currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final bool showJoinButton;

  const ActivityCard({
    Key? key,
    required this.activity,
    required this.currentUser,
    this.onTap,
    this.onJoin,
    this.onLeave,
    this.showJoinButton = true,
  }) : super(key: key);

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final isJoined = activity.participants.contains(widget.currentUser.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: NeoCard(
        color: AppColors.pureWhite,
        radius: 18,
        borderWidth: 2.0,
        shadowOffset: const Offset(3.0, 3.5),
        padding: const EdgeInsets.all(16),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Image with black border
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.paperCream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge & Karma Coins reward
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.electricMint,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.solidBlack, width: 1.4),
                              ),
                              child: Text(
                                activity.type.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.butterYellow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.solidBlack, width: 1.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, size: 13, color: AppColors.solidBlack),
                                const SizedBox(width: 4),
                                Text(
                                  '+${activity.points} Karma Coins',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        activity.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                          height: 1.25,
                        ),
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Location Badge
            if (activity.location.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softSky.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.solidBlack),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        activity.location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solidBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Description
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Text(
                activity.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.solidBlack.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              secondChild: Text(
                activity.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.solidBlack.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ),

            if (activity.description.length > 90)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Read less' : 'Read full action plan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: AppColors.solidBlack,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Footer row: Participants, Date, and Join Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paperCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.solidBlack, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_rounded, size: 14, color: AppColors.solidBlack),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.participantCount} joined',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paperCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.solidBlack, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.solidBlack),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(activity.date),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                if (widget.showJoinButton)
                  GestureDetector(
                    onTap: isJoined ? widget.onLeave : widget.onJoin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isJoined ? AppColors.electricMint : AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.solidBlack, width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        isJoined ? 'Joined ✓' : 'Join Action',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
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

  Widget _buildImageWidget() {
    final img = widget.activity.imageUrl;
    if (img != null && img.isNotEmpty) {
      if (img.startsWith('assets/images/')) {
        return Image.asset(
          img,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else if (img.startsWith('http')) {
        return Image.network(
          img,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.butterYellow,
      child: const Center(
        child: Icon(Icons.park_rounded, color: AppColors.solidBlack, size: 30),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Compare calendar days (not 24h spans) so e.g. tomorrow-morning is not 'Today'
    final now = DateTime.now();
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > 1 && days < 7) return 'In ${days}d';
    return '${date.day}/${date.month}';
  }
}
