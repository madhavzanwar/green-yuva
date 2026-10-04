import 'package:cloud_firestore/cloud_firestore.dart';

class Ecore {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? conqueredBySchoolId;
  final String? conqueredBySchoolName;
  final DateTime? conqueredAt;
  final DateTime? coolingTimeEnd;
  final List<EcoreMission> missions;
  final int totalPoints;
  final bool isActive;
  final bool isDiscovered;
  final DateTime? discoveredAt;
  final String? discoveredBySchoolId;
  final DateTime createdAt;

  Ecore({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.conqueredBySchoolId,
    this.conqueredBySchoolName,
    this.conqueredAt,
    this.coolingTimeEnd,
    required this.missions,
    required this.totalPoints,
    required this.isActive,
    this.isDiscovered = false,
    this.discoveredAt,
    this.discoveredBySchoolId,
    required this.createdAt,
  });

  bool get isConquered => conqueredBySchoolId != null;
  bool get isInCoolingTime => coolingTimeEnd != null && DateTime.now().isBefore(coolingTimeEnd!);
  bool get canBeConquered => !isConquered && !isInCoolingTime;
  bool get isVisible => isDiscovered;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'conqueredBySchoolId': conqueredBySchoolId,
      'conqueredBySchoolName': conqueredBySchoolName,
      'conqueredAt': conqueredAt,
      'coolingTimeEnd': coolingTimeEnd,
      'missions': missions.map((m) => m.toMap()).toList(),
      'totalPoints': totalPoints,
      'isActive': isActive,
      'isDiscovered': isDiscovered,
      'discoveredAt': discoveredAt,
      'discoveredBySchoolId': discoveredBySchoolId,
      'createdAt': createdAt,
    };
  }

  static DateTime? _parseNullableDate(dynamic dateVal) {
    if (dateVal == null) return null;
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal);
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return null;
  }

  factory Ecore.fromMap(String id, Map<String, dynamic> data) {
    return Ecore(
      id: id,
      name: data['name'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      conqueredBySchoolId: data['conqueredBySchoolId'],
      conqueredBySchoolName: data['conqueredBySchoolName'],
      conqueredAt: _parseNullableDate(data['conqueredAt']),
      coolingTimeEnd: _parseNullableDate(data['coolingTimeEnd']),
      missions: (data['missions'] as List<dynamic>? ?? [])
          .map((m) => EcoreMission.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
      isDiscovered: data['isDiscovered'] ?? false,
      discoveredAt: _parseNullableDate(data['discoveredAt']),
      discoveredBySchoolId: data['discoveredBySchoolId'],
      createdAt: _parseNullableDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Ecore copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? conqueredBySchoolId,
    String? conqueredBySchoolName,
    DateTime? conqueredAt,
    DateTime? coolingTimeEnd,
    List<EcoreMission>? missions,
    int? totalPoints,
    bool? isActive,
    bool? isDiscovered,
    DateTime? discoveredAt,
    String? discoveredBySchoolId,
    DateTime? createdAt,
  }) {
    return Ecore(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      conqueredBySchoolId: conqueredBySchoolId ?? this.conqueredBySchoolId,
      conqueredBySchoolName: conqueredBySchoolName ?? this.conqueredBySchoolName,
      conqueredAt: conqueredAt ?? this.conqueredAt,
      coolingTimeEnd: coolingTimeEnd ?? this.coolingTimeEnd,
      missions: missions ?? this.missions,
      totalPoints: totalPoints ?? this.totalPoints,
      isActive: isActive ?? this.isActive,
      isDiscovered: isDiscovered ?? this.isDiscovered,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      discoveredBySchoolId: discoveredBySchoolId ?? this.discoveredBySchoolId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EcoreMission {
  final String id;
  final String title;
  final String description;
  final String summary;
  final List<String> tips;
  final List<String> categories;
  final int points;
  final String imageUrl;
  final bool isCompleted;
  final String? completedByUserId;
  final String? completedByUserName;
  final DateTime? completedAt;
  final String? proofImageUrl;

  EcoreMission({
    required this.id,
    required this.title,
    required this.description,
    required this.summary,
    required this.tips,
    required this.categories,
    required this.points,
    required this.imageUrl,
    this.isCompleted = false,
    this.completedByUserId,
    this.completedByUserName,
    this.completedAt,
    this.proofImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'summary': summary,
      'tips': tips,
      'categories': categories,
      'points': points,
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
      'completedByUserId': completedByUserId,
      'completedByUserName': completedByUserName,
      'completedAt': completedAt,
      'proofImageUrl': proofImageUrl,
    };
  }

  factory EcoreMission.fromMap(Map<String, dynamic> data) {
    return EcoreMission(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      summary: data['summary']?.toString() ?? '',
      tips: List<String>.from(data['tips'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      points: (data['points'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl']?.toString() ?? '',
      isCompleted: data['isCompleted'] == true,
      completedByUserId: data['completedByUserId']?.toString(),
      completedByUserName: data['completedByUserName']?.toString(),
      completedAt: Ecore._parseNullableDate(data['completedAt']),
      proofImageUrl: data['proofImageUrl']?.toString(),
    );
  }

  EcoreMission copyWith({
    String? id,
    String? title,
    String? description,
    String? summary,
    List<String>? tips,
    List<String>? categories,
    int? points,
    String? imageUrl,
    bool? isCompleted,
    String? completedByUserId,
    String? completedByUserName,
    DateTime? completedAt,
    String? proofImageUrl,
  }) {
    return EcoreMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      tips: tips ?? this.tips,
      categories: categories ?? this.categories,
      points: points ?? this.points,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      completedByUserId: completedByUserId ?? this.completedByUserId,
      completedByUserName: completedByUserName ?? this.completedByUserName,
      completedAt: completedAt ?? this.completedAt,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
    );
  }
}