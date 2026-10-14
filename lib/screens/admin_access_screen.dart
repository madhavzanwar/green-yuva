import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'admin_verification_screen.dart';

class AdminAccessScreen extends StatefulWidget {
  final AppUser user;

  const AdminAccessScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _AdminAccessScreenState createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends State<AdminAccessScreen> {
  final TextEditingController _schoolIdController = TextEditingController();
  bool _isLoading = false;
  bool _checkingRole = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _verifyAdminRole();
  }

  Future<void> _verifyAdminRole() async {
    final isAdmin = await UserService().isAdmin(widget.user.id);
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _checkingRole = false;
    });
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    super.dispose();
  }

  void _accessAdminPanel() {
    if (!_isAdmin) return;
    if (_schoolIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a school ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminVerificationScreen(
          adminUser: widget.user,
          schoolId: _schoolIdController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Access',
          style: GoogleFonts.questrial(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _checkingRole
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Your account does not have admin access.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.questrial(fontSize: 18, color: Colors.grey[700]),
                    ),
                  ),
                )
              : SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Panel Access',
              style: GoogleFonts.questrial(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the school ID to access verification requests for that school.',
              style: GoogleFonts.questrial(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _schoolIdController,
              decoration: InputDecoration(
                labelText: 'School ID',
                hintText: 'Enter school ID (e.g., daegu, jungheung)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.school),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _accessAdminPanel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
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
                            'Loading...',
                            style: GoogleFonts.questrial(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Access Admin Panel',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Admin Features',
                        style: GoogleFonts.questrial(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Review and approve verification requests\n• Reject requests with feedback\n• Award points to users\n• View verification history',
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: Colors.blue[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}