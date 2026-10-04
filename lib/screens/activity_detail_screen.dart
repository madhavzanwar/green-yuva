import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../models/user.dart';
import '../models/verification_request.dart';
import '../services/activity_service.dart';
import '../services/verification_service.dart';
import 'verification_request_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  final AppUser user;
  final String schoolId;

  const ActivityDetailScreen({
    Key? key,
    required this.activity,
    required this.user,
    required this.schoolId,
  }) : super(key: key);

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityService _activityService = ActivityService();
  final VerificationService _verificationService = VerificationService();
  bool _isJoining = false;
  bool _isJoined = false;
  VerificationRequest? _verificationRequest;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
    _checkVerificationStatus();
  }

  Future<void> _checkJoinStatus() async {
    try {
      final joined = await _activityService.isUserJoinedActivity(
        widget.schoolId,
        widget.activity.id,
        widget.user.id,
      );
      if (mounted) {
        setState(() {
          _isJoined = joined;
        });
      }
    } catch (e) {
      print('❌ Error checking join status: $e');
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final request = await _verificationService.getVerificationRequest(
        userId: widget.user.id,
        itemId: widget.activity.id,
        type: VerificationType.activity,
      );
      if (mounted) {
        setState(() {
          _verificationRequest = request;
        });
      }
    } catch (e) {
      print('❌ Error checking verification status: $e');
    }
  }

  Future<void> _joinActivity() async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await _activityService.joinActivity(
        widget.schoolId,
        widget.activity.id,
        widget.user.id,
      );

      if (mounted) {
        setState(() {
          _isJoined = true;
          _isJoining = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerificationRequestScreen(
              type: VerificationType.activity,
              itemId: widget.activity.id,
              itemTitle: widget.activity.title,
              points: widget.activity.points,
              user: widget.user,
              schoolId: widget.schoolId,
              schoolName: widget.activity.communityName ?? 'Unknown School',
              activity: widget.activity,
            ),
          ),
        ).then((_) {

          _checkVerificationStatus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveActivity() async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await _activityService.leaveActivity(
        widget.schoolId,
        widget.activity.id,
        widget.user.id,
      );

      if (mounted) {
        setState(() {
          _isJoined = false;
          _isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully left ${widget.activity.title}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Details'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: ClipRect(
                child: _buildActivityImage(),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.activity.title,
                          style: GoogleFonts.questrial(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/green_points.svg',
                              width: 16,
                              height: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${widget.activity.points}',
                              style: GoogleFonts.questrial(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  Text(
                    '${widget.activity.participantCount} Participant • ${widget.activity.fullDateTime}',
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 24),

                  Text(
                    'About Event',
                    style: GoogleFonts.questrial(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    widget.activity.description,
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            if (_verificationRequest != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _verificationRequest!.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _verificationRequest!.statusColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      _verificationRequest!.isPending
                          ? Icons.schedule
                          : _verificationRequest!.isApproved
                              ? Icons.check_circle
                              : Icons.cancel,
                      color: _verificationRequest!.statusColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _verificationRequest!.isPending
                            ? 'Verification Pending'
                            : _verificationRequest!.isApproved
                                ? 'Verification Approved'
                                : 'Verification Rejected',
                        style: GoogleFonts.questrial(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _verificationRequest!.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.activity.isPast
                    ? null
                    : _isJoining
                        ? null
                        : _isJoined
                            ? _leaveActivity
                            : _joinActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.activity.isPast
                      ? Colors.grey[400]
                      : _isJoined
                          ? Colors.orange[600]
                          : Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isJoining
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Processing...',
                            style: GoogleFonts.questrial(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.activity.isPast
                            ? 'Activity Ended'
                            : _isJoined
                                ? 'Leave Activity'
                                : 'Join Activity',
                        style: GoogleFonts.questrial(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityImage() {
    if (widget.activity.imageUrl == null || widget.activity.imageUrl!.isEmpty) {

      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.event,
          size: 80,
          color: Colors.grey[400],
        ),
      );
    }

    if (widget.activity.imageUrl!.startsWith('assets/images/')) {
      return Image.asset(
        widget.activity.imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              size: 80,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    if (widget.activity.imageUrl!.startsWith('http://') || widget.activity.imageUrl!.startsWith('https://')) {
      return Image.network(
        widget.activity.imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              size: 80,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.event,
        size: 80,
        color: Colors.grey[400],
      ),
    );
  }
}