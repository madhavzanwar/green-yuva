import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verification_request.dart';
import '../models/activity.dart';
import '../models/ecore.dart';
import '../models/user.dart';
import '../services/verification_service.dart';
import '../services/image_upload_service.dart';

class VerificationRequestScreen extends StatefulWidget {
  final VerificationType type;
  final String itemId;
  final String itemTitle;
  final int points;
  final AppUser user;
  final String schoolId;
  final String schoolName;
  final Activity? activity;
  final EcoreMission? mission;

  const VerificationRequestScreen({
    Key? key,
    required this.type,
    required this.itemId,
    required this.itemTitle,
    required this.points,
    required this.user,
    required this.schoolId,
    required this.schoolName,
    this.activity,
    this.mission,
  }) : super(key: key);

  @override
  _VerificationRequestScreenState createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  final VerificationService _verificationService = VerificationService();
  final TextEditingController _descriptionController = TextEditingController();

  String? _proofImageUrl;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final imageBytes = await ImageUploadService.pickImageFromGallery();
      if (!mounted) return;
      if (imageBytes != null) {
        final imageUrl = await ImageUploadService.uploadMissionProofImage(
          missionId: widget.itemId,
          userId: widget.user.id,
          imageBytes: imageBytes,
        );
        if (!mounted) return;

        setState(() {
          _proofImageUrl = imageUrl;
          _isUploadingImage = false;
        });
      } else {
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitVerificationRequest() async {
    if (_isSubmitting) return;

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a description of what you did'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _verificationService.createVerificationRequest(
        user: widget.user,
        schoolId: widget.schoolId,
        schoolName: widget.schoolName,
        type: widget.type,
        itemId: widget.itemId,
        itemTitle: widget.itemTitle,
        points: widget.points,
        proofImageUrl: _proofImageUrl,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit verification request: $e'),
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
        title: Text(
          'Submit Verification',
          style: GoogleFonts.questrial(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemTitle,
                    style: GoogleFonts.questrial(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        widget.type == VerificationType.activity
                            ? Icons.event
                            : Icons.flag,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.type == VerificationType.activity ? 'Activity' : 'Mission',
                        style: GoogleFonts.questrial(
                          fontSize: 16,
                          color: Colors.green[600],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.green[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.points} points',
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
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Describe what you did',
              style: GoogleFonts.questrial(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about your participation...',
                hintStyle: GoogleFonts.questrial(
                  color: Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.questrial(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Add Photo',
              style: GoogleFonts.questrial(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            if (_proofImageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _proofImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploadingImage ? null : _pickImage,
                icon: _isUploadingImage
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.photo_camera),
                label: Text(
                  _isUploadingImage
                      ? 'Uploading...'
                      : _proofImageUrl != null
                          ? 'Change Image'
                          : 'Add Photo',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerificationRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Submitting...',
                            style: GoogleFonts.questrial(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Submit Verification',
                        style: GoogleFonts.questrial(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your verification request will be reviewed by an admin. You will receive points once approved.',
                      style: GoogleFonts.questrial(
                        fontSize: 14,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
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
}