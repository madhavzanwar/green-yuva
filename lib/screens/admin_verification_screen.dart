import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verification_request.dart';
import '../models/user.dart';
import '../services/verification_service.dart';
import '../services/user_service.dart';

class AdminVerificationScreen extends StatefulWidget {
  final AppUser adminUser;
  final String schoolId;

  const AdminVerificationScreen({
    Key? key,
    required this.adminUser,
    required this.schoolId,
  }) : super(key: key);

  @override
  _AdminVerificationScreenState createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final VerificationService _verificationService = VerificationService();
  final UserService _userService = UserService();

  List<VerificationRequest> _verificationRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadVerificationRequests();
  }

  Future<void> _loadVerificationRequests() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final requests = await _verificationService.getSchoolVerificationRequests(widget.schoolId);

      if (mounted) {
        setState(() {
          _verificationRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load verification requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<VerificationRequest> get _filteredRequests {
    switch (_selectedFilter) {
      case 'pending':
        return _verificationRequests.where((r) => r.isPending).toList();
      case 'approved':
        return _verificationRequests.where((r) => r.isApproved).toList();
      case 'rejected':
        return _verificationRequests.where((r) => r.isRejected).toList();
      default:
        return _verificationRequests;
    }
  }

  Future<void> _approveRequest(VerificationRequest request) async {
    try {
      await _verificationService.approveVerificationRequest(
        requestId: request.id,
        reviewerId: widget.adminUser.id,
        reviewNotes: 'Approved by admin',
      );

      await _userService.addUserPoints(request.userId, request.points);

      await _loadVerificationRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification approved and ${request.points} points awarded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(VerificationRequest request) async {
    final TextEditingController notesController = TextEditingController();

    final String? reviewNotes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Verification',
          style: GoogleFonts.questrial(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: GoogleFonts.questrial(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(notesController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (reviewNotes != null) {
      try {
        await _verificationService.rejectVerificationRequest(
          requestId: request.id,
          reviewerId: widget.adminUser.id,
          reviewNotes: reviewNotes,
        );

        await _loadVerificationRequests();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject verification: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verification Requests',
          style: GoogleFonts.questrial(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadVerificationRequests,
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('all', 'All'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('pending', 'Pending'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('approved', 'Approved'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('rejected', 'Rejected'),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No verification requests found',
                              style: GoogleFonts.questrial(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildVerificationCard(request);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.questrial(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildVerificationCard(VerificationRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    request.type == VerificationType.activity
                        ? Icons.event
                        : Icons.flag,
                    color: request.statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.itemTitle,
                        style: GoogleFonts.questrial(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.type == VerificationType.activity ? 'Activity' : 'Mission',
                        style: GoogleFonts.questrial(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.statusText,
                    style: GoogleFonts.questrial(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: request.statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    request.userName.isNotEmpty ? request.userName[0].toUpperCase() : '?',
                    style: GoogleFonts.questrial(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: GoogleFonts.questrial(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        request.schoolName,
                        style: GoogleFonts.questrial(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.green[700],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${request.points}',
                        style: GoogleFonts.questrial(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (request.description != null && request.description!.isNotEmpty) ...[
              Text(
                'Description:',
                style: GoogleFonts.questrial(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.description!,
                style: GoogleFonts.questrial(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (request.proofImageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    request.proofImageUrl!,
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

            Text(
              'Submitted: ${_formatDate(request.createdAt)}',
              style: GoogleFonts.questrial(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),

            if (request.reviewedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reviewed: ${_formatDate(request.reviewedAt!)} by ${request.reviewedBy ?? 'Admin'}',
                style: GoogleFonts.questrial(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],

            if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'Review notes: ${request.reviewNotes}',
                  style: GoogleFonts.questrial(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],

            if (request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.questrial(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rejectRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.questrial(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}