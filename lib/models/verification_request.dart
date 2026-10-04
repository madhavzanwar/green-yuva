import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum VerificationType {
  activity,
  mission,
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
}

class VerificationRequest {
  final String id;
  final String userId;
  final String userName;
  final String schoolId;
  final String schoolName;
  final VerificationType type;
  final String itemId;
  final String itemTitle;
  final int points;
  final String? proofImageUrl;
  final String? description;
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final double? aiConfidence;
  final String? aiClassification;
  final bool? aiIsAuthentic;
  final bool isProvisionalApproved;
  final String? aiDetectedObjects;
  final String? aiEngine;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.schoolId,
    required this.schoolName,
    required this.type,
    required this.itemId,
    required this.itemTitle,
    required this.points,
    this.proofImageUrl,
    this.description,
    this.status = VerificationStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    this.aiConfidence,
    this.aiClassification,
    this.aiIsAuthentic,
    this.isProvisionalApproved = false,
    this.aiDetectedObjects,
    this.aiEngine,
  });

  String get missionTitle => itemTitle;

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic dateVal) {
    if (dateVal == null) return null;
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal);
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return null;
  }

  factory VerificationRequest.fromMap(String id, Map<String, dynamic> data) {
    return VerificationRequest(
      id: id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      schoolId: data['schoolId']?.toString() ?? '',
      schoolName: data['schoolName']?.toString() ?? '',
      type: VerificationType.values.firstWhere(
        (e) => e.toString() == 'VerificationType.${data['type']}',
        orElse: () => VerificationType.activity,
      ),
      itemId: data['itemId']?.toString() ?? '',
      itemTitle: data['itemTitle']?.toString() ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      proofImageUrl: data['proofImageUrl']?.toString(),
      description: data['description']?.toString(),
      status: VerificationStatus.values.firstWhere(
        (e) => e.toString() == 'VerificationStatus.${data['status']}',
        orElse: () => VerificationStatus.pending,
      ),
      createdAt: _parseDate(data['createdAt']),
      reviewedAt: _parseNullableDate(data['reviewedAt']),
      reviewedBy: data['reviewedBy']?.toString(),
      reviewNotes: data['reviewNotes']?.toString(),
      aiConfidence: (data['aiConfidence'] as num?)?.toDouble(),
      aiClassification: data['aiClassification']?.toString(),
      aiIsAuthentic: data['aiIsAuthentic'] as bool?,
      isProvisionalApproved: data['isProvisionalApproved'] == true,
      aiDetectedObjects: data['aiDetectedObjects']?.toString(),
      aiEngine: data['aiEngine']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'type': type.toString().split('.').last,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'points': points,
      'proofImageUrl': proofImageUrl,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'aiConfidence': aiConfidence,
      'aiClassification': aiClassification,
      'aiIsAuthentic': aiIsAuthentic,
      'isProvisionalApproved': isProvisionalApproved,
      'aiDetectedObjects': aiDetectedObjects,
      'aiEngine': aiEngine,
    };
  }

  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? schoolId,
    String? schoolName,
    VerificationType? type,
    String? itemId,
    String? itemTitle,
    int? points,
    String? proofImageUrl,
    String? description,
    VerificationStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
    double? aiConfidence,
    String? aiClassification,
    bool? aiIsAuthentic,
    bool? isProvisionalApproved,
    String? aiDetectedObjects,
    String? aiEngine,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      points: points ?? this.points,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiClassification: aiClassification ?? this.aiClassification,
      aiIsAuthentic: aiIsAuthentic ?? this.aiIsAuthentic,
      isProvisionalApproved: isProvisionalApproved ?? this.isProvisionalApproved,
      aiDetectedObjects: aiDetectedObjects ?? this.aiDetectedObjects,
      aiEngine: aiEngine ?? this.aiEngine,
    );
  }

  bool get isPending => status == VerificationStatus.pending;
  bool get isApproved => status == VerificationStatus.approved;
  bool get isRejected => status == VerificationStatus.rejected;

  String get statusText {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
    }
  }
}