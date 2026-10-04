import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ecore.dart';
import '../models/user.dart';
import '../models/verification_request.dart';
import '../services/verification_service.dart';
import 'verification_request_screen.dart';

class MissionDetailScreen extends StatefulWidget {
  final EcoreMission mission;
  final Ecore ecore;
  final AppUser user;

  const MissionDetailScreen({
    Key? key,
    required this.mission,
    required this.ecore,
    required this.user,
  }) : super(key: key);

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final VerificationService _verificationService = VerificationService();
  VerificationRequest? _verificationRequest;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final request = await _verificationService.getVerificationRequest(
        userId: widget.user.id,
        itemId: widget.mission.id,
        type: VerificationType.mission,
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

  Widget _buildMissionImage() {

    if (widget.mission.imageUrl.startsWith('assets/images/')) {
      return Image.asset(
        widget.mission.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.green[100],
            child: Icon(
              Icons.eco,
              size: 64,
              color: Colors.green[400],
            ),
          );
        },
      );
    }

    if (widget.mission.imageUrl.startsWith('http://') || widget.mission.imageUrl.startsWith('https://')) {
      return Image.network(
        widget.mission.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.green[100],
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
            color: Colors.green[100],
            child: Icon(
              Icons.eco,
              size: 64,
              color: Colors.green[400],
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.green[100],
      child: Icon(
        Icons.eco,
        size: 64,
        color: Colors.green[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mission Detail',
          style: GoogleFonts.questrial(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.green[100],
              ),
              child: widget.mission.imageUrl.isNotEmpty
                  ? _buildMissionImage()
                  : Container(
                      color: Colors.green[100],
                      child: Icon(
                        Icons.eco,
                        size: 64,
                        color: Colors.green[400],
                      ),
                    ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.mission.title,
                          style: GoogleFonts.questrial(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
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
                            const SizedBox(width: 4),
                            Text(
                              '${widget.mission.points}',
                              style: GoogleFonts.questrial(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.mission.categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          '#$category',
                          style: GoogleFonts.questrial(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Summary',
                    style: GoogleFonts.questrial(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.mission.summary,
                    style: GoogleFonts.questrial(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Tips',
                    style: GoogleFonts.questrial(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.mission.tips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.questrial(
                                fontSize: 16,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 40),

                  if (_verificationRequest != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _verificationRequest!.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _verificationRequest!.isPending
                                      ? 'Verification Pending'
                                      : _verificationRequest!.isApproved
                                          ? 'Verification Approved'
                                          : 'Verification Rejected',
                                  style: GoogleFonts.questrial(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _verificationRequest!.statusColor,
                                  ),
                                ),
                                if (_verificationRequest!.reviewNotes != null)
                                  Text(
                                    _verificationRequest!.reviewNotes!,
                                    style: GoogleFonts.questrial(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!widget.mission.isCompleted && widget.ecore.canBeConquered && _verificationRequest == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _completeMission(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'I did this Mission',
                          style: GoogleFonts.questrial(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (widget.mission.isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mission Completed!',
                            style: GoogleFonts.questrial(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!widget.ecore.canBeConquered)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ecore in Cooling Time',
                            style: GoogleFonts.questrial(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
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

  void _completeMission() {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationRequestScreen(
          type: VerificationType.mission,
          itemId: widget.mission.id,
          itemTitle: widget.mission.title,
          points: widget.mission.points,
          user: widget.user,
          schoolId: widget.user.joinedSchoolId ?? '',
          schoolName: 'Unknown School',
          mission: widget.mission,
        ),
      ),
    ).then((_) {

      _checkVerificationStatus();
    });
  }
}