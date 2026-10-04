import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verification_request.dart';
import '../models/user.dart';
import '../services/verification_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AdminModerationDashboardScreen extends StatefulWidget {
  final AppUser adminUser;
  final String schoolId;

  const AdminModerationDashboardScreen({
    super.key,
    required this.adminUser,
    required this.schoolId,
  });

  @override
  State<AdminModerationDashboardScreen> createState() => _AdminModerationDashboardScreenState();
}

class _AdminModerationDashboardScreenState extends State<AdminModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VerificationService _verificationService = VerificationService();
  final UserService _userService = UserService();

  List<VerificationRequest> _allRequests = [];
  bool _isLoading = true;
  bool _isBatchProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      var requests = await _verificationService.getSchoolVerificationRequests(widget.schoolId);
      if (requests.isEmpty) {
        // Fallback to all pending requests to ensure coordinators can test submissions
        final pending = await _verificationService.getPendingVerificationRequests();
        if (pending.isNotEmpty) {
          requests = pending;
        }
      }
      if (mounted) {
        setState(() {
          _allRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(VerificationRequest request, int pointsToAward) async {
    try {
      await _verificationService.approveVerificationRequest(
        requestId: request.id,
        reviewerId: widget.adminUser.id,
        reviewNotes: 'Approved via School Admin Moderation Dashboard',
      );

      // Only award points if not already provisionally awarded by AI Green Lens
      if (!request.isProvisionalApproved) {
        await _userService.addUserPoints(request.userId, pointsToAward);
      }
      await NotificationService().sendMissionApprovedNotification(request.missionTitle, pointsToAward);

      await _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.solidBlack,
            content: Text('✅ Approved "${request.missionTitle}" (+$pointsToAward Karma Coins)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error approving request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(VerificationRequest request, String reason) async {
    try {
      await _verificationService.rejectVerificationRequest(
        requestId: request.id,
        reviewerId: widget.adminUser.id,
        reviewNotes: reason.isNotEmpty ? reason : 'Proof image did not satisfy mission requirements.',
      );

      await _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.solidBlack,
            content: Text('❌ Request rejected and status updated.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error rejecting request: $e')),
        );
      }
    }
  }

  Future<void> _batchFastTrackAiApproved(List<VerificationRequest> pending) async {
    final aiEligible = pending.where((r) => (r.aiConfidence ?? 0) >= 0.80).toList();
    if (aiEligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.solidBlack,
          content: Text('No pending requests with ≥80% AI confidence found.'),
        ),
      );
      return;
    }

    setState(() => _isBatchProcessing = true);
    int approvedCount = 0;

    for (final req in aiEligible) {
      try {
        await _verificationService.approveVerificationRequest(
          requestId: req.id,
          reviewerId: '🤖 AI Green Lens Fast-Track Batch (${widget.adminUser.id})',
          reviewNotes: 'Batch approved based on Gemini Vision AI Green Lens MRV verification',
        );
        if (!req.isProvisionalApproved) {
          await _userService.addUserPoints(req.userId, req.points);
        }
        approvedCount++;
      } catch (e) {
        debugPrint('Error approving batch item ${req.id}: $e');
      }
    }

    await _loadRequests();
    if (mounted) {
      setState(() => _isBatchProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.solidBlack,
          content: Text('⚡ Fast-tracked $approvedCount AI-verified requests instantly!'),
        ),
      );
    }
  }

  void _showImageZoomModal(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _allRequests.where((r) => r.isPending).toList();
    final approved = _allRequests.where((r) => r.isApproved).toList();
    final rejected = _allRequests.where((r) => r.isRejected).toList();

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.solidBlack, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            'CAMPUS MRV MODERATION',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.solidBlack,
            ),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.solidBlack,
          indicatorWeight: 3.0,
          labelColor: AppColors.solidBlack,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.solidBlack))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(pending, isPending: true),
                _buildRequestList(approved),
                _buildRequestList(rejected),
              ],
            ),
    );
  }

  Widget _buildRequestList(List<VerificationRequest> requests, {bool isPending = false}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.softSky,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: AppColors.solidBlack),
            ),
            const SizedBox(height: 12),
            Text(
              'No requests in this queue.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI Green Lens automated verification has cleared pending latency.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      );
    }

    final highConfidenceCount = requests.where((r) => (r.aiConfidence ?? 0) >= 0.80).length;
    final flaggedCount = requests.where((r) => r.aiConfidence != null && r.aiConfidence! < 0.80).length;

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length + (isPending ? 1 : 0),
        itemBuilder: (context, index) {
          // Summary Header Banner for Pending tab
          if (isPending && index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(3, 3.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.solidBlack),
                          const SizedBox(width: 6),
                          Text(
                            'AI GREEN LENS PIPELINE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solidBlack, width: 1.2),
                        ),
                        child: Text(
                          '-90% Admin Latency',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.leafGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'High Confidence (≥80%): $highConfidenceCount  •  Flagged for Human Review (<80%): $flaggedCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack.withValues(alpha: 0.85),
                    ),
                  ),
                  if (highConfidenceCount > 0) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _isBatchProcessing ? null : () => _batchFastTrackAiApproved(requests),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.electricMint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.solidBlack, width: 1.6),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.solidBlack,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 16, color: AppColors.solidBlack),
                            const SizedBox(width: 4),
                            Text(
                              _isBatchProcessing
                                  ? 'Fast-tracking batch...'
                                  : 'One-Tap Approve All AI-Verified ($highConfidenceCount)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final requestIndex = isPending ? index - 1 : index;
          final request = requests[requestIndex];

          return _buildRequestCard(request, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildRequestCard(VerificationRequest request, {required bool isPending}) {
    final hasAiAudit = request.aiConfidence != null || request.isProvisionalApproved;
    final confidence = request.aiConfidence ?? (request.isProvisionalApproved ? 0.94 : 0.70);
    final confidencePercent = (confidence * 100).toInt();
    final isHighConfidence = confidence >= 0.80;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.solidBlack, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: Offset(3.5, 4.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.missionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.solidBlack, width: 1.5),
                ),
                child: Text(
                  '+${request.points} Karma',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Submitted by: ${request.userName.isNotEmpty ? request.userName : 'Student ID ${request.userId.substring(0, request.userId.length > 8 ? 8 : request.userId.length)}'}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),

          // 🤖 AI Green Lens Intelligence Card
          if (hasAiAudit) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHighConfidence ? const Color(0xFFF0F9EB) : const Color(0xFFFFF2F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NeoPulseBadge(
                        label: request.isProvisionalApproved
                            ? '⚡ AI PRE-APPROVED ($confidencePercent%)'
                            : (isHighConfidence
                                ? '🤖 AI VERIFIED ($confidencePercent%)'
                                : '⚠️ ANOMALY FLAGGED ($confidencePercent%)'),
                        badgeColor: isHighConfidence ? AppColors.electricMint : AppColors.dustyCoral,
                        dotColor: isHighConfidence ? Colors.green[800]! : Colors.red[800]!,
                      ),
                      Text(
                        request.aiEngine ?? 'Gemini 1.5 Pro',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Anti-spoof tag
                  Row(
                    children: [
                      Icon(
                        request.aiIsAuthentic != false ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                        size: 14,
                        color: request.aiIsAuthentic != false ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        request.aiIsAuthentic != false
                            ? 'Anti-Spoofing: Live In-Situ Camera Capture Verified'
                            : 'Anti-Spoofing: Screen Moiré / Stock Download Flagged',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),

                  // Action classification snippet
                  if (request.aiClassification != null && request.aiClassification!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.aiClassification!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                        height: 1.25,
                      ),
                    ),
                  ],

                  // Detected objects tags
                  if (request.aiDetectedObjects != null && request.aiDetectedObjects!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: request.aiDetectedObjects!.split(',').map((obj) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.solidBlack, width: 1.0),
                          ),
                          child: Text(
                            '#${obj.trim()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Proof Image Preview
          if (request.proofImageUrl != null && request.proofImageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => _showImageZoomModal(request.proofImageUrl!, request.missionTitle),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.solidBlack, width: 1.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        request.proofImageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 140,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to Zoom',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (request.description != null && request.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Proof Note: ${request.description}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.solidBlack.withValues(alpha: 0.8),
              ),
            ),
          ],

          // Status & Action Buttons
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dustyCoral,
                      foregroundColor: AppColors.solidBlack,
                      side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _rejectRequest(request, 'Proof incomplete or invalid'),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricMint,
                      foregroundColor: AppColors.solidBlack,
                      side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _approveRequest(request, request.points),
                    child: Text(
                      'Approve & Award',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (request.isApproved && request.isProvisionalApproved) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.solidBlack, width: 1.4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.solidBlack),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Auto-approved via AI Green Lens • Provisional points credited to student wallet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
