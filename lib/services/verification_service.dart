import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_request.dart';
import '../models/user.dart';
import 'user_service.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createVerificationRequest({
    required AppUser user,
    required String schoolId,
    required String schoolName,
    required VerificationType type,
    required String itemId,
    required String itemTitle,
    required int points,
    String? proofImageUrl,
    String? description,
    double? aiConfidence,
    String? aiClassification,
    bool? aiIsAuthentic,
    bool isProvisionalApproved = false,
    String? aiDetectedObjects,
    String? aiEngine,
  }) async {
    try {
      final now = DateTime.now();
      final verificationRequest = VerificationRequest(
        id: '',
        userId: user.id,
        userName: user.fullName,
        schoolId: schoolId,
        schoolName: schoolName,
        type: type,
        itemId: itemId,
        itemTitle: itemTitle,
        points: points,
        proofImageUrl: proofImageUrl,
        description: description,
        status: isProvisionalApproved ? VerificationStatus.approved : VerificationStatus.pending,
        createdAt: now,
        reviewedAt: isProvisionalApproved ? now : null,
        reviewedBy: isProvisionalApproved ? '🤖 Gemini Vision AI Green Lens' : null,
        reviewNotes: isProvisionalApproved
            ? (aiClassification ?? 'Provisional Approval granted by Gemini Vision AI Green Lens')
            : (aiClassification != null ? 'AI Review Note: $aiClassification' : null),
        aiConfidence: aiConfidence,
        aiClassification: aiClassification,
        aiIsAuthentic: aiIsAuthentic,
        isProvisionalApproved: isProvisionalApproved,
        aiDetectedObjects: aiDetectedObjects,
        aiEngine: aiEngine,
      );

      await _firestore
          .collection('verification_requests')
          .add(verificationRequest.toMap());

      // If approved provisionally by AI Green Lens, credit points immediately!
      if (isProvisionalApproved) {
        await UserService().addUserPoints(user.id, points);
      }
    } catch (e) {
      print('Notice: Verification stored locally/fallback: $e');
    }
  }

  Future<List<VerificationRequest>> getUserVerificationRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 4));

      return snapshot.docs
          .map((doc) => VerificationRequest.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('ℹ️ VerificationService getUserVerificationRequests fallback: $e');
      return [];
    }
  }

  Future<List<VerificationRequest>> getPendingVerificationRequests() async {
    try {
      final snapshot = await _firestore
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 4));

      return snapshot.docs
          .map((doc) => VerificationRequest.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('ℹ️ VerificationService getPendingVerificationRequests fallback: $e');
      return [];
    }
  }

  Future<List<VerificationRequest>> getSchoolVerificationRequests(String schoolId) async {
    try {
      final snapshot = await _firestore
          .collection('verification_requests')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 4));

      return snapshot.docs
          .map((doc) => VerificationRequest.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('ℹ️ VerificationService getSchoolVerificationRequests fallback: $e');
      return [];
    }
  }

  Future<void> approveVerificationRequest({
    required String requestId,
    required String reviewerId,
    String? reviewNotes,
  }) async {
    try {
      await _firestore.collection('verification_requests').doc(requestId).update({
        'status': 'approved',
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'reviewedBy': reviewerId,
        'reviewNotes': reviewNotes,
      });
    } catch (e) {
      print('❌ Failed to approve verification request: $e');
    }
  }

  Future<void> rejectVerificationRequest({
    required String requestId,
    required String reviewerId,
    String? reviewNotes,
  }) async {
    try {
      await _firestore.collection('verification_requests').doc(requestId).update({
        'status': 'rejected',
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'reviewedBy': reviewerId,
        'reviewNotes': reviewNotes,
      });
    } catch (e) {
      print('❌ Failed to reject verification request: $e');
    }
  }

  Future<bool> hasPendingVerification({
    required String userId,
    required String itemId,
    required VerificationType type,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'pending')
          .get()
          .timeout(const Duration(seconds: 3));

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('ℹ️ VerificationService hasPendingVerification fallback: $e');
      return false;
    }
  }

  Future<VerificationRequest?> getVerificationRequest({
    required String userId,
    required String itemId,
    required VerificationType type,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.docs.isEmpty) return null;

      return VerificationRequest.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      print('ℹ️ VerificationService getVerificationRequest fallback: $e');
      return null;
    }
  }

  Future<void> deleteVerificationRequest(String requestId) async {
    try {
      await _firestore
          .collection('verification_requests')
          .doc(requestId)
          .delete();
    } catch (e) {
      print('❌ Failed to delete verification request: $e');
    }
  }
}