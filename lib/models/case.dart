import 'package:cloud_firestore/cloud_firestore.dart';

class Case {
  final String id;
  final String personName;
  final String story;
  final String climateEvent;
  final String location;
  final String impact;
  final DateTime date;
  final String sourceUrl;
  final String? imageUrl;
  final String severity;
  final String source;
  final bool isReviewed;
  final String? description;

  Case({
    required this.id,
    required this.personName,
    required this.story,
    required this.climateEvent,
    required this.location,
    required this.impact,
    required this.date,
    required this.sourceUrl,
    this.imageUrl,
    required this.severity,
    required this.source,
    this.isReviewed = false,
    this.description,
  });

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return DateTime.now();
  }

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id']?.toString() ?? '',
      personName: json['personName'] ?? '',
      story: json['story'] ?? '',
      climateEvent: json['climateEvent'] ?? '',
      location: json['location'] ?? '',
      impact: json['impact'] ?? '',
      date: _parseDate(json['date']),
      sourceUrl: json['sourceUrl'] ?? '',
      imageUrl: json['imageUrl'],
      severity: json['severity'] ?? 'medium',
      source: json['source'] ?? '',
      isReviewed: json['isReviewed'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'story': story,
      'climateEvent': climateEvent,
      'location': location,
      'impact': impact,
      'date': Timestamp.fromDate(date),
      'sourceUrl': sourceUrl,
      'imageUrl': imageUrl,
      'severity': severity,
      'source': source,
      'isReviewed': isReviewed,
      'description': description,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final caseDate = DateTime(date.year, date.month, date.day);

    if (caseDate == today) {
      return 'Today';
    } else if (caseDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${_getDayName(date.weekday)}, ${_getMonthName(date.month)} ${date.day}';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}