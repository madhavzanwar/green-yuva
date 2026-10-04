import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/image_upload_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class CreatePostScreen extends StatefulWidget {
  final String schoolId;
  final AppUser user;
  const CreatePostScreen({Key? key, required this.schoolId, required this.user}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _loading = false;
  Uint8List? _selectedImageBytes;
  bool _hasImage = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final imageBytes = await ImageUploadService.pickImageFromGallery();
      if (!mounted) return;
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _hasImage = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final imageBytes = await ImageUploadService.takePhotoWithCamera();
      if (!mounted) return;
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _hasImage = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; });

    try {
      print('📝 CreatePost: Creating new post for school ${widget.schoolId}');
      print('📝 CreatePost: User ID: ${widget.user.id}');
      print('📝 CreatePost: Content: ${_contentController.text.trim()}');

      final postId = Uuid().v4();
      String? imageUrl;

      if (_hasImage && _selectedImageBytes != null) {
        print('📝 CreatePost: Uploading image to Supabase...');
        imageUrl = await ImageUploadService.uploadPostImage(
          postId: postId,
          imageBytes: _selectedImageBytes,
        );
        print('📝 CreatePost: Image uploaded: $imageUrl');
      }

      final post = Post(
        id: postId,
        userId: widget.user.id,
        content: _contentController.text.trim(),
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        likes: [],
        saves: [],
        commentCount: 0,
      );

      print('📝 CreatePost: Post created, saving to Firebase...');
      print('📝 CreatePost: Post ID: ${post.id}');
      await PostService().addPost(widget.schoolId, post);
      print('✅ CreatePost: Post saved successfully');

      if (mounted) {

        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ CreatePost: Error creating post: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to create post: $e');
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.questrial(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: Text(
              'Post',
              style: GoogleFonts.questrial(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.purple.withOpacity(0.3),
                      child: Text(
                        widget.user.displayName.isNotEmpty
                            ? widget.user.displayName[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.questrial(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      widget.user.displayName.isNotEmpty
                          ? widget.user.displayName
                          : 'Anonymous User',
                      style: GoogleFonts.questrial(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter some content';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                if (_hasImage)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Image selected',
                          style: GoogleFonts.questrial(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              _selectedImageBytes = null;
                              _hasImage = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: Icon(Icons.photo_library),
                        label: Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _takePhotoWithCamera,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_loading)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}