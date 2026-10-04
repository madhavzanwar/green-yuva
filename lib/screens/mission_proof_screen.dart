import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ecore.dart';
import '../models/user.dart';
import '../models/ai_green_lens_result.dart';
import '../models/verification_request.dart';
import '../services/ai_service.dart';
import '../services/climagame_service.dart';
import '../services/image_upload_service.dart';
import '../services/verification_service.dart';
import '../theme/app_theme.dart';

class MissionProofScreen extends StatefulWidget {
  final Ecore ecore;
  final EcoreMission mission;
  final AppUser user;

  const MissionProofScreen({
    super.key,
    required this.ecore,
    required this.mission,
    required this.user,
  });

  @override
  State<MissionProofScreen> createState() => _MissionProofScreenState();
}

class _MissionProofScreenState extends State<MissionProofScreen> {
  Uint8List? _selectedImageBytes;
  bool _isAuditingWithAi = false;
  AIGreenLensResult? _lensResult;
  bool _isVerifying = false;
  String _verificationStep = '';
  double _verificationProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.solidBlack, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lens_blur_rounded, size: 16, color: AppColors.solidBlack),
              const SizedBox(width: 6),
              Text(
                'AI GREEN LENS PROOF',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Mission Details Hero Card
            NeoCard(
              color: AppColors.cardWhite,
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricMint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        ),
                        child: Text(
                          widget.ecore.name.split(' ').first.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.butterYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, size: 14, color: AppColors.solidBlack),
                            const SizedBox(width: 4),
                            Text(
                              '+${widget.mission.points} Karma Coins',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.mission.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.mission.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.solidBlack.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo Capture / Preview Card
            if (_selectedImageBytes == null)
              _buildEmptyPhotoPickerCard()
            else ...[
              _buildPhotoPreviewCard(),
              const SizedBox(height: 16),
              // AI Green Lens Verdict or Scanning Card
              if (_isAuditingWithAi)
                _buildScanningWithAiCard()
              else if (_lensResult != null)
                _buildAiGreenLensVerdictCard(),
            ],

            const SizedBox(height: 16),

            // Verification Guidelines Card
            NeoCard(
              color: AppColors.cardWhite,
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI MRV CRITERIA (GEMINI 1.5 PRO)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const NeoPulseBadge(
                        label: 'SUB-2S AUDIT',
                        badgeColor: AppColors.butterYellow,
                        dotColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCriterionRow('🛡️', 'Anti-Spoofing: Detects live camera captures vs. computer screen moiré & stock downloads.'),
                  const SizedBox(height: 6),
                  _buildCriterionRow('🔍', 'Object Fidelity: AI identifies botanical roots, mulching, microgrids, or waste bins.'),
                  const SizedBox(height: 6),
                  _buildCriterionRow('⚡', 'Instant Payout: ≥80% confidence unlocks instant provisional +${widget.mission.points} Karma Coins.'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            if (_isVerifying)
              _buildVerifyingStateCard()
            else
              NeoButton(
                text: _selectedImageBytes == null
                    ? 'Take Mission Photo First'
                    : (_isAuditingWithAi
                        ? 'AI Green Lens Scanning...'
                        : (_lensResult != null && _lensResult!.isProvisionalApproved
                            ? 'Claim Instant +${widget.mission.points} Karma Coins ⚡'
                            : 'Submit for Campus Coordinator Review 📋')),
                color: _selectedImageBytes == null
                    ? Colors.grey[300]!
                    : (_lensResult != null && _lensResult!.isProvisionalApproved
                        ? AppColors.electricMint
                        : AppColors.butterYellow),
                textColor: AppColors.solidBlack,
                onPressed: (_selectedImageBytes == null || _isAuditingWithAi)
                    ? null
                    : _startAiVerificationAndSubmit,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoPickerCard() {
    return NeoCard(
      color: AppColors.cardWhite,
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.softSky,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.solidBlack,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppColors.solidBlack,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Upload Mission Proof Photo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.solidBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a photo of your tangible action on campus for AI Green Lens MRV audit',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _takePhotoWithCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.electricMint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.solidBlack),
                        const SizedBox(width: 6),
                        Text(
                          'Open Camera',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.solidBlack),
                        const SizedBox(width: 6),
                        Text(
                          'From Gallery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
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

  Widget _buildPhotoPreviewCard() {
    return NeoCard(
      color: AppColors.pureWhite,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricMint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.solidBlack),
                    const SizedBox(width: 4),
                    Text(
                      'PROOF PHOTO CAPTURED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_selectedImageBytes != null) {
                        _handleImagePicked(_selectedImageBytes!);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.refresh_rounded, size: 12, color: AppColors.solidBlack),
                          const SizedBox(width: 3),
                          Text(
                            'Re-scan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImageBytes = null;
                        _lensResult = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.2),
                      ),
                      child: Text(
                        'Retake',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dustyCoral,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.solidBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 14, color: AppColors.leafGreen),
                  const SizedBox(width: 4),
                  Text(
                    'AI Green Lens MRV Engine Ready',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.leafGreen,
                    ),
                  ),
                ],
              ),
              Text(
                '${(_selectedImageBytes!.length / 1024).toStringAsFixed(1)} KB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningWithAiCard() {
    return NeoCard(
      color: AppColors.butterYellow,
      radius: 18,
      borderWidth: 2.2,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.solidBlack,
                  strokeWidth: 2.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Green Lens Auditing Proof Photo...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.5),
                ),
                child: Text(
                  '< 2s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Running anti-spoofing heuristics and Gemini Vision ecological object classification...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiGreenLensVerdictCard() {
    final result = _lensResult!;
    final confidencePercent = (result.confidence * 100).toInt();
    final isProvisional = result.isProvisionalApproved;

    return NeoCard(
      color: AppColors.cardWhite,
      radius: 18,
      borderWidth: 2.5,
      shadowOffset: const Offset(4.0, 4.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeoPulseBadge(
                label: isProvisional ? 'PROVISIONAL PAYOUT READY' : 'ANOMALY DETECTED',
                badgeColor: isProvisional ? AppColors.electricMint : AppColors.dustyCoral,
                dotColor: isProvisional ? Colors.green[800]! : Colors.red[800]!,
                textColor: AppColors.solidBlack,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Text(
                  '$confidencePercent% CONFIDENCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Anti-Spoofing & Context Verification Strip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: result.isAuthentic ? const Color(0xFFEDF7ED) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: result.isAuthentic ? Colors.green[700]! : Colors.red[700]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isAuthentic ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                  color: result.isAuthentic ? Colors.green[700] : Colors.red[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.isAuthentic ? 'Anti-Spoofing Verified: Live Physical Capture' : 'Anti-Spoofing Flag: Digital Spoof Suspected',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      Text(
                        result.spoofingDetails,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Classification
          Text(
            'ACTION CLASSIFICATION & OBJECT FIDELITY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paperCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.solidBlack, width: 1.8),
            ),
            child: Text(
              result.classification,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Detected Objects Tags
          if (result.detectedObjects.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.detectedObjects.map((obj) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.solidBlack, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_outlined, size: 11, color: AppColors.leafGreen),
                      const SizedBox(width: 4),
                      Text(
                        '#$obj',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Provisional Status Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isProvisional ? AppColors.butterYellow : AppColors.softSky,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.solidBlack, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  isProvisional ? Icons.bolt_rounded : Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.solidBlack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isProvisional
                        ? 'Confidence is ≥80%. You will receive +${widget.mission.points} Karma Coins instantly upon submitting!'
                        : 'Confidence is <80%. Your proof will be routed to your school coordinator for review.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyingStateCard() {
    return NeoCard(
      color: AppColors.butterYellow,
      radius: 16,
      borderWidth: 2.2,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.solidBlack,
                  strokeWidth: 2.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _verificationStep,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _verificationProgress,
              backgroundColor: AppColors.pureWhite,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.leafGreen),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.solidBlack.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      HapticFeedback.lightImpact();
      final bytes = await ImageUploadService.takePhotoWithCamera();
      if (bytes != null && mounted) {
        _handleImagePicked(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera: $e'),
            backgroundColor: AppColors.dustyCoral,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      HapticFeedback.lightImpact();
      final bytes = await ImageUploadService.pickImageFromGallery();
      if (bytes != null && mounted) {
        _handleImagePicked(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick photo: $e'),
            backgroundColor: AppColors.dustyCoral,
          ),
        );
      }
    }
  }

  Future<void> _handleImagePicked(Uint8List bytes) async {
    setState(() {
      _selectedImageBytes = bytes;
      _lensResult = null;
      _isAuditingWithAi = true;
    });

    try {
      final audit = await AIService.auditMissionProof(
        imageBytes: bytes,
        missionTitle: widget.mission.title,
        missionDescription: widget.mission.description,
        campusName: widget.ecore.name,
        points: widget.mission.points,
      );

      if (mounted) {
        setState(() {
          _lensResult = audit;
          _isAuditingWithAi = false;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuditingWithAi = false;
        });
      }
    }
  }

  Future<void> _startAiVerificationAndSubmit() async {
    if (_selectedImageBytes == null) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isVerifying = true;
      _verificationStep = 'Extracting GPS geofence & anti-spoof proof...';
      _verificationProgress = 0.25;
    });

    // Run AI Green Lens audit if not already completed
    AIGreenLensResult auditResult = _lensResult ??
        await AIService.auditMissionProof(
          imageBytes: _selectedImageBytes!,
          missionTitle: widget.mission.title,
          missionDescription: widget.mission.description,
          campusName: widget.ecore.name,
          points: widget.mission.points,
        );

    if (!mounted) return;

    setState(() {
      _lensResult = auditResult;
      _verificationStep = 'Gemini Vision MRV: Ecological object & action classification...';
      _verificationProgress = 0.60;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _verificationStep = 'Logging cryptographic proof to Green Yuva Registry...';
      _verificationProgress = 0.85;
    });

    // Upload proof image
    String? proofUrl = await ImageUploadService.uploadMissionProofImage(
      missionId: widget.mission.id,
      userId: widget.user.id,
      imageBytes: _selectedImageBytes,
    );

    // Create verification request record in Firestore
    final verificationService = VerificationService();
    await verificationService.createVerificationRequest(
      user: widget.user,
      schoolId: widget.user.joinedSchoolId ?? 'campus-general',
      schoolName: widget.ecore.name,
      type: VerificationType.mission,
      itemId: widget.mission.id,
      itemTitle: widget.mission.title,
      points: widget.mission.points,
      proofImageUrl: proofUrl,
      description: auditResult.classification,
      aiConfidence: auditResult.confidence,
      aiClassification: auditResult.classification,
      aiIsAuthentic: auditResult.isAuthentic,
      isProvisionalApproved: auditResult.isProvisionalApproved,
      aiDetectedObjects: auditResult.detectedObjects.join(', '),
      aiEngine: auditResult.engineUsed,
    );

    // If provisional approval granted, also mark mission completed in ClimaGame
    if (auditResult.isProvisionalApproved) {
      await ClimaGameService.completeMission(
        userId: widget.user.id,
        userName: widget.user.fullName,
        ecoreId: widget.ecore.id,
        missionId: widget.mission.id,
        proofImageUrl: proofUrl,
      );
    }

    if (!mounted) return;

    setState(() {
      _verificationProgress = 1.0;
      _verificationStep = auditResult.isProvisionalApproved
          ? 'Verified! Provisional Karma Coins credited instantly!'
          : 'Submitted! Forwarded to Campus Coordinator Queue.';
    });

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() => _isVerifying = false);
      if (auditResult.isProvisionalApproved) {
        _showCelebrationDialog(auditResult);
      } else {
        _showAdminReviewRoutedDialog(auditResult);
      }
    }
  }

  void _showCelebrationDialog(AIGreenLensResult audit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoCard(
          color: AppColors.pureWhite,
          radius: 22,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.solidBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.stars_rounded, size: 44, color: AppColors.solidBlack),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI GREEN LENS CERTIFIED!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gemini Vision MRV validated your action with ${(audit.confidence * 100).toInt()}% confidence. No waiting in the admin queue!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.mutedText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.electricMint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
                ),
                child: Text(
                  '+${widget.mission.points} Karma Coins Instantly Credited 🪙',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              NeoButton(
                text: 'Back to GreenRush Radar',
                color: AppColors.butterYellow,
                textColor: AppColors.solidBlack,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminReviewRoutedDialog(AIGreenLensResult audit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoCard(
          color: AppColors.pureWhite,
          radius: 22,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.softSky,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.solidBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.assignment_turned_in_outlined, size: 36, color: AppColors.solidBlack),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ROUTED TO CAMPUS ADMIN',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI recorded ${(audit.confidence * 100).toInt()}% confidence (<80%). Your proof was routed to your campus sustainability coordinator for manual review.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.solidBlack, width: 1.5),
                ),
                child: Text(
                  'Status: In Review (Review SLA < 24 hrs)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              NeoButton(
                text: 'Got It',
                color: AppColors.butterYellow,
                textColor: AppColors.solidBlack,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}