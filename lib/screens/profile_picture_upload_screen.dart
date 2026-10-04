import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/image_upload_service.dart';
import 'dart:typed_data';

class ProfilePictureUploadScreen extends StatefulWidget {
  final AppUser user;
  final bool isFromRegistration;

  const ProfilePictureUploadScreen({
    Key? key,
    required this.user,
    this.isFromRegistration = false,
  }) : super(key: key);

  @override
  State<ProfilePictureUploadScreen> createState() => _ProfilePictureUploadScreenState();
}

class _ProfilePictureUploadScreenState extends State<ProfilePictureUploadScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = false;
  bool _isImageValid = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
    _loadCurrentProfilePicture();
  }

  Future<void> _loadCurrentProfilePicture() async {

  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final imageBytes = await ImageUploadService.pickImageFromGallery();
      if (!mounted) return;
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _isImageValid = true;
          _isLoading = false;
        });
        _showSuccessMessage('Image selected successfully');
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final imageBytes = await ImageUploadService.takePhotoWithCamera();
      if (!mounted) return;
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _isImageValid = true;
          _isLoading = false;
        });
        _showSuccessMessage('Photo captured successfully');
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _saveProfilePicture() async {
    if (!_isImageValid) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;

      if (_selectedImageBytes != null) {
        print('📤 Uploading profile picture from bytes...');
        imageUrl = await ImageUploadService.uploadProfilePicture(
          userId: widget.user.id,
          imageBytes: _selectedImageBytes,
        );
      }

      if (imageUrl != null) {
        print('✅ Profile picture uploaded successfully: $imageUrl');

        await UserService().updateUserProfilePic(widget.user.id, imageUrl);

        if (mounted) {
          _showSuccessMessage('Profile picture updated successfully!');

          if (widget.isFromRegistration) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('❌ Error saving profile picture: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save profile picture: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _skipForNow() {
    if (widget.isFromRegistration) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile Picture',
          style: GoogleFonts.questrial(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildImagePreview(),
                  const SizedBox(height: 30),
                  _buildUploadOptions(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Add a Profile Picture',
          style: GoogleFonts.questrial(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Choose a photo from your gallery or take a new one',
          style: GoogleFonts.questrial(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: _isImageValid
              ? _selectedImageBytes != null
                  ? Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage()
              : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildUploadButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onPressed: _isLoading ? null : _pickImageFromGallery,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildUploadButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onPressed: _isLoading ? null : _takePhotoWithCamera,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading || !_isImageValid ? null : _saveProfilePicture,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Profile Picture',
                    style: GoogleFonts.questrial(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: _isLoading ? null : _skipForNow,
          child: Text(
            'Skip for now',
            style: GoogleFonts.questrial(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}