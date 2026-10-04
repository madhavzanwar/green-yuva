import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  final String author;
  final String category;
  final int questionCount;
  final int timeLimit;
  final int points;
  final double rating;
  final String imageUrl;
  final String videoUrl;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final bool isActive;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.category,
    required this.questionCount,
    required this.timeLimit,
    required this.points,
    required this.rating,
    required this.imageUrl,
    required this.videoUrl,
    required this.questions,
    required this.createdAt,
    this.isActive = true,
  });

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    if (dateVal is num) return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt());
    return DateTime.now();
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      timeLimit: (json['timeLimit'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
          .toList() ?? [],
      createdAt: _parseDate(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'category': category,
      'questionCount': questionCount,
      'timeLimit': timeLimit,
      'points': points,
      'rating': rating,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizAnswer> answers;
  final String correctAnswerId;
  final String explanation;
  final int points;
  final String? imageUrl;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.correctAnswerId,
    required this.explanation,
    required this.points,
    this.imageUrl,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => QuizAnswer.fromJson(a))
          .toList() ?? [],
      correctAnswerId: json['correctAnswerId'] ?? '',
      explanation: json['explanation'] ?? '',
      points: json['points'] ?? 0,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answers': answers.map((a) => a.toJson()).toList(),
      'correctAnswerId': correctAnswerId,
      'explanation': explanation,
      'points': points,
      'imageUrl': imageUrl,
    };
  }
}

class QuizAnswer {
  final String id;
  final String text;
  final bool isCorrect;

  QuizAnswer({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String userId;
  final int attemptNumber;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int finalScore;
  final int timeSpent;
  final bool isCompleted;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionResult> questionResults;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.attemptNumber,
    required this.startedAt,
    this.completedAt,
    required this.finalScore,
    required this.timeSpent,
    required this.isCompleted,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questionResults,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
      startedAt: Quiz._parseDate(json['startedAt']),
      completedAt: json['completedAt'] != null ? Quiz._parseDate(json['completedAt']) : null,
      finalScore: (json['finalScore'] as num?)?.toInt() ?? 0,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      questionResults: (json['questionResults'] as List<dynamic>?)
          ?.map((result) => QuestionResult.fromJson(Map<String, dynamic>.from(result as Map)))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'attemptNumber': attemptNumber,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'finalScore': finalScore,
      'timeSpent': timeSpent,
      'isCompleted': isCompleted,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'questionResults': questionResults.map((result) => result.toJson()).toList(),
    };
  }

  double get progressPercentage => totalQuestions > 0 ? questionResults.length / totalQuestions : 0.0;
  double get accuracyPercentage => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
  bool get isPassed => finalScore >= 70;
}

class QuestionResult {
  final String questionId;
  final String selectedAnswerId;
  final bool isCorrect;
  final int timeSpent;
  final DateTime answeredAt;

  QuestionResult({
    required this.questionId,
    required this.selectedAnswerId,
    required this.isCorrect,
    required this.timeSpent,
    required this.answeredAt,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId']?.toString() ?? '',
      selectedAnswerId: json['selectedAnswerId']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      answeredAt: Quiz._parseDate(json['answeredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswerId': selectedAnswerId,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };
  }
}

class QuizProgress {
  final String id;
  final String quizId;
  final String userId;
  final int currentQuestion;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpent;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int score;
  final Map<String, String> userAnswers;

  QuizProgress({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.currentQuestion,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
    required this.score,
    required this.userAnswers,
  });

  factory QuizProgress.fromJson(Map<String, dynamic> json) {
    return QuizProgress(
      id: json['id']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      currentQuestion: (json['currentQuestion'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      startedAt: Quiz._parseDate(json['startedAt']),
      completedAt: json['completedAt'] != null ? Quiz._parseDate(json['completedAt']) : null,
      score: (json['score'] as num?)?.toInt() ?? 0,
      userAnswers: Map<String, String>.from(json['userAnswers'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'currentQuestion': currentQuestion,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'timeSpent': timeSpent,
      'isCompleted': isCompleted,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'score': score,
      'userAnswers': userAnswers,
    };
  }

  double get progressPercentage => totalQuestions > 0 ? currentQuestion / totalQuestions : 0.0;
  double get accuracyPercentage => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
}