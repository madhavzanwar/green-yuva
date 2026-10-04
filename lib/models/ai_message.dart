import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  user,
  ai,
  system,
}

enum MessageStatus {
  sending,
  sent,
  error,
}

class AIMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? userId;
  final String? conversationId;
  final Map<String, dynamic>? metadata;

  AIMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.userId,
    this.conversationId,
    this.metadata,
  });

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return DateTime.now();
  }

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.user,
      ),
      timestamp: _parseDate(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      userId: json['userId']?.toString(),
      conversationId: json['conversationId']?.toString(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString().split('.').last,
      'userId': userId,
      'conversationId': conversationId,
      'metadata': metadata,
    };
  }

  AIMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? userId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) {
    return AIMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class AIConversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final List<AIMessage> messages;
  final Map<String, dynamic>? settings;

  AIConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.lastMessageAt,
    required this.messages,
    this.settings,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt: AIMessage._parseDate(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null ? AIMessage._parseDate(json['lastMessageAt']) : null,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'messages': messages.map((m) => m.toJson()).toList(),
      'settings': settings,
    };
  }

  AIConversation copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    List<AIMessage>? messages,
    Map<String, dynamic>? settings,
  }) {
    return AIConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      settings: settings ?? this.settings,
    );
  }
}

class AIResponse {
  final String content;
  final Map<String, dynamic>? metadata;
  final bool isError;
  final String? errorMessage;

  AIResponse({
    required this.content,
    this.metadata,
    this.isError = false,
    this.errorMessage,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      content: json['content'] ?? '',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      isError: json['isError'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'metadata': metadata,
      'isError': isError,
      'errorMessage': errorMessage,
    };
  }
}