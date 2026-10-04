import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> saves;
  final int commentCount;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.saves,
    required this.commentCount,
  });

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return DateTime.now();
  }

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      userId: data['userId']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      timestamp: _parseDate(data['timestamp']),
      likes: List<String>.from(data['likes'] ?? []),
      saves: List<String>.from(data['saves'] ?? []),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'likes': likes,
      'saves': saves,
      'commentCount': commentCount,
    };
  }
}