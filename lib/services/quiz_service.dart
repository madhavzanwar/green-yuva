import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quiz.dart';
import '../services/user_service.dart';

class QuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();
  static final UserService _userService = UserService();

  static List<Quiz>? _cachedQuizzes;
  static final Map<String, List<QuizAttempt>> _localAttempts = {};

  static void _saveLocalAttempt(QuizAttempt attempt) {
    final key = '${attempt.userId}_${attempt.quizId}';
    final list = _localAttempts[key] ?? [];
    final existingIdx = list.indexWhere((a) => a.id == attempt.id);
    if (existingIdx != -1) {
      list[existingIdx] = attempt;
    } else {
      list.add(attempt);
    }
    _localAttempts[key] = list;
  }

  static List<QuizAttempt> _getLocalAttempts(String userId, String quizId) {
    final key = '${userId}_${quizId}';
    final list = _localAttempts[key] ?? [];
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.from(list);
  }

  static void clearQuizCache() {
    _cachedQuizzes = null;
    print('🗑️ Quiz cache cleared');
  }

  static Future<List<Quiz>> getQuizzes() async {
    try {
      print('📚 Fetching quizzes from Firebase...');
      final snapshot = await _firestore.collection('quizzes').get().timeout(const Duration(seconds: 3));
      print('📊 Found ${snapshot.docs.length} quiz documents');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No quiz documents found in Firestore, falling back to JSON');
        return await _loadQuizzesFromJSON();
      }

      final quizzes = <Quiz>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('🏫 Processing quiz: ${doc.id}');
          print('  Document data keys: ${data.keys.toList()}');

          final questions = <QuizQuestion>[];
          final questionsData = data['questions'] as List<dynamic>? ?? [];

          print('🔍 Loading questions for quiz ${doc.id}:');
          print('  Questions found in main document: ${questionsData.length}');

          for (final questionData in questionsData) {
            final answers = <QuizAnswer>[];
            final answersData = questionData['answers'] as List<dynamic>? ?? [];

            for (final answerData in answersData) {
              answers.add(QuizAnswer(
                id: answerData['id'] ?? '',
                text: answerData['text'] ?? '',
                isCorrect: answerData['isCorrect'] ?? false,
              ));
            }

            final question = QuizQuestion(
              id: questionData['id'] ?? '',
              question: questionData['question'] ?? '',
              answers: answers,
              correctAnswerId: questionData['correctAnswerId'] ?? '',
              explanation: questionData['explanation'] ?? '',
              points: questionData['points'] ?? 10,
              imageUrl: questionData['imageUrl'],
            );

            questions.add(question);
          }

          // If no questions were directly in document, hydrate from JSON fallback
          if (questions.isEmpty) {
            try {
              final jsonQuizzes = await _loadQuizzesFromJSON();
              final matched = jsonQuizzes.firstWhere(
                (jq) => jq.id == doc.id || jq.title.toLowerCase().trim() == (data['title'] ?? '').toString().toLowerCase().trim(),
                orElse: () => jsonQuizzes.isNotEmpty ? jsonQuizzes[quizzes.length % jsonQuizzes.length] : jsonQuizzes.first,
              );
              if (matched.questions.isNotEmpty) {
                questions.addAll(matched.questions);
              }
            } catch (_) {}
          }

          final quiz = Quiz(
            id: doc.id,
            title: data['title'] ?? doc.id,
            description: data['description'] ?? '',
            author: data['author'] ?? 'Green Yuva Climate Academy',
            category: data['category'] ?? 'Climate Science',
            questionCount: questions.isNotEmpty ? questions.length : 10,
            timeLimit: data['timeLimit'] ?? 900,
            points: data['points'] ?? 100,
            rating: (data['rating'] ?? 4.8).toDouble(),
            imageUrl: data['imageUrl'] ?? '',
            videoUrl: data['videoUrl'] ?? '',
            questions: questions,
            createdAt: data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isActive: data['isActive'] ?? true,
          );

          quizzes.add(quiz);
          print('✅ Added quiz: ${quiz.title} with ${questions.length} questions');
        } catch (e) {
          print('❌ Error processing quiz ${doc.id}: $e');
        }
      }

      print('🎉 Successfully processed ${quizzes.length} quizzes');
      return quizzes;
    } catch (e) {
      print('❌ Error fetching quizzes: $e');
      return await _loadQuizzesFromJSON();
    }
  }

  static Future<List<Quiz>> loadQuizzesFromJSON() async {
    return _loadQuizzesFromJSON();
  }

  static Future<List<Quiz>> _loadQuizzesFromJSON() async {
    try {
      if (_cachedQuizzes != null) {
        print('📚 Returning cached quizzes from JSON');
        return _cachedQuizzes!;
      }

      print('📚 Loading quizzes from JSON file...');
      final String jsonString = await rootBundle.loadString('assets/data/sample_quizzes.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> quizzesData = jsonData['quizzes'];

      final quizzes = <Quiz>[];

      for (final quizData in quizzesData) {
        try {
          final questions = <QuizQuestion>[];
          final List<dynamic> questionsData = quizData['questions'] ?? [];

          for (final questionData in questionsData) {
            final answers = <QuizAnswer>[];
            final List<dynamic> answersData = questionData['answers'] ?? [];

            for (final answerData in answersData) {
              answers.add(QuizAnswer(
                id: answerData['id'] ?? '',
                text: answerData['text'] ?? '',
                isCorrect: answerData['isCorrect'] ?? false,
              ));
            }

            final question = QuizQuestion(
              id: questionData['id'] ?? '',
              question: questionData['question'] ?? '',
              answers: answers,
              correctAnswerId: questionData['correctAnswerId'] ?? '',
              explanation: questionData['explanation'] ?? '',
              points: questionData['points'] ?? 10,
              imageUrl: questionData['imageUrl'],
            );

            questions.add(question);

            if (questions.length <= 3) {
              print('🔍 JSON Question ${questions.length}:');
              print('  Question: ${question.question}');
              print('  Correct Answer ID: ${question.correctAnswerId}');
              print('  Number of answers: ${question.answers.length}');
              for (final answer in question.answers) {
                print('    Answer ${answer.id}: ${answer.text} (Correct: ${answer.isCorrect})');
              }
            }
          }

          quizzes.add(Quiz(
            id: quizData['id'] ?? '',
            title: quizData['title'] ?? '',
            description: quizData['description'] ?? '',
            author: quizData['author'] ?? 'e-icon World Contest',
            category: quizData['category'] ?? 'Climate Science',
            questionCount: questions.length,
            timeLimit: quizData['timeLimit'] ?? 150,
            points: quizData['points'] ?? 50,
            rating: (quizData['rating'] ?? 4.5).toDouble(),
            imageUrl: quizData['imageUrl'] ?? '',
            videoUrl: quizData['videoUrl'] ?? '',
            questions: questions,
            createdAt: DateTime.now().subtract(Duration(days: 30)),
            isActive: true,
          ));

          print('✅ Loaded quiz from JSON: ${quizData['title']}');
        } catch (e) {
          print('❌ Error processing quiz from JSON: $e');
        }
      }

      _cachedQuizzes = quizzes;
      print('🎉 Successfully loaded ${quizzes.length} quizzes from JSON');
      return quizzes;
    } catch (e) {
      print('❌ Error loading quizzes from JSON: $e');
      return _getSampleQuizzes();
    }
  }

  static Future<Quiz?> getQuizById(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        final data = doc.data()!;

        final questions = <QuizQuestion>[];
        final questionsData = data['questions'] as List<dynamic>? ?? [];

        print('🔍 Loading quiz questions from Firestore:');
        print('  Quiz ID: $quizId');
        print('  Questions found: ${questionsData.length}');

        for (final questionData in questionsData) {
          final answers = <QuizAnswer>[];
          final answersData = questionData['answers'] as List<dynamic>? ?? [];

          for (final answerData in answersData) {
            answers.add(QuizAnswer(
              id: answerData['id'] ?? '',
              text: answerData['text'] ?? '',
              isCorrect: answerData['isCorrect'] ?? false,
            ));
          }

          final question = QuizQuestion(
            id: questionData['id'] ?? '',
            question: questionData['question'] ?? '',
            answers: answers,
            correctAnswerId: questionData['correctAnswerId'] ?? '',
            explanation: questionData['explanation'] ?? '',
            points: questionData['points'] ?? 10,
            imageUrl: questionData['imageUrl'],
          );

          questions.add(question);

          print('  Question: ${question.question}');
          print('  Correct Answer ID: ${question.correctAnswerId}');
          print('  Number of answers: ${question.answers.length}');
        }

        // Hydrate questions from JSON fallback if empty
        if (questions.isEmpty) {
          try {
            final jsonQuizzes = await _loadQuizzesFromJSON();
            final matched = jsonQuizzes.firstWhere(
              (jq) => jq.id == quizId || jq.title.toLowerCase().trim() == (data['title'] ?? '').toString().toLowerCase().trim(),
              orElse: () => jsonQuizzes.isNotEmpty ? jsonQuizzes.first : jsonQuizzes.first,
            );
            if (matched.questions.isNotEmpty) {
              questions.addAll(matched.questions);
            }
          } catch (_) {}
        }

        return Quiz(
          id: doc.id,
          title: data['title'] ?? doc.id,
          description: data['description'] ?? '',
          author: data['author'] ?? 'Green Yuva Climate Academy',
          category: data['category'] ?? 'Climate Science',
          questionCount: questions.isNotEmpty ? questions.length : 10,
          timeLimit: data['timeLimit'] ?? 900,
          points: data['points'] ?? 100,
          rating: (data['rating'] ?? 4.8).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          videoUrl: data['videoUrl'] ?? '',
          questions: questions,
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          isActive: data['isActive'] ?? true,
        );
      }
    } catch (e) {
      print('ℹ️ Firestore getQuizById fallback to local list: $e');
    }

    try {
      final quizzes = await getQuizzes();
      return quizzes.firstWhere((q) => q.id == quizId);
    } catch (_) {
      return null;
    }
  }

  static Future<List<QuizQuestion>> _getQuestionsForQuiz(String quizId) async {
    try {

      final questionsSnapshot = await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .get();

      if (questionsSnapshot.docs.isEmpty) {
        print('⚠️ No questions found for quiz $quizId, using sample questions');
        return _getSampleQuestions();
      }

      final questions = questionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return QuizQuestion(
          id: doc.id,
          question: data['question'] ?? '',
          answers: (data['answers'] as List<dynamic>?)?.map((answer) {
            return QuizAnswer(
              id: answer['id'] ?? '',
              text: answer['text'] ?? '',
              isCorrect: answer['isCorrect'] ?? false,
            );
          }).toList() ?? [],
          correctAnswerId: data['correctAnswerId'] ?? '',
          explanation: data['explanation'] ?? '',
          points: data['points'] ?? 10,
          imageUrl: data['imageUrl'],
        );
      }).toList();

      return questions;
    } catch (e) {
      print('❌ Error fetching questions for quiz $quizId: $e');
      return _getSampleQuestions();
    }
  }

  static Future<QuizProgress?> getQuizProgress(String userId, String quizId) async {
    try {
      final doc = await _firestore
          .collection('quiz_progress')
          .where('userId', isEqualTo: userId)
          .where('quizId', isEqualTo: quizId)
          .get();

      if (doc.docs.isNotEmpty) {
        return QuizProgress.fromJson(doc.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error fetching quiz progress: $e');
      return null;
    }
  }

  static Future<QuizProgress?> getQuizProgressById(String progressId) async {
    try {
      final doc = await _firestore.collection('quiz_progress').doc(progressId).get();
      if (doc.exists) {
        return QuizProgress.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching quiz progress by ID: $e');
      return null;
    }
  }

  static Future<List<QuizProgress>> getUserQuizProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('quiz_progress')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      final progressList = <QuizProgress>[];
      for (final doc in snapshot.docs) {
        try {
          final progress = QuizProgress.fromJson(doc.data());
          progressList.add(progress);
        } catch (e) {
          print('Error parsing quiz progress: $e');
        }
      }

      return progressList;
    } catch (e) {
      print('Error fetching user quiz progress: $e');
      return [];
    }
  }

  static Future<void> saveQuizProgress(QuizProgress progress) async {
    try {
      await _firestore
          .collection('quiz_progress')
          .doc(progress.id)
          .set(progress.toJson());
    } catch (e) {
      print('Error saving quiz progress: $e');
    }
  }

  static Future<QuizProgress> createQuizProgress(String userId, String quizId, int totalQuestions) async {
    final progress = QuizProgress(
      id: _uuid.v4(),
      quizId: quizId,
      userId: userId,
      currentQuestion: 0,
      correctAnswers: 0,
      totalQuestions: totalQuestions,
      timeSpent: 0,
      isCompleted: false,
      startedAt: DateTime.now(),
      score: 0,
      userAnswers: {},
    );

    await saveQuizProgress(progress);
    return progress;
  }

  static Future<void> updateQuizProgress(QuizProgress progress) async {
    await saveQuizProgress(progress);
  }

  static Future<void> submitAnswer(QuizProgress progress, String questionId, String answerId, bool isCorrect) async {
    final updatedProgress = QuizProgress(
      id: progress.id,
      quizId: progress.quizId,
      userId: progress.userId,
      currentQuestion: progress.currentQuestion + 1,
      correctAnswers: progress.correctAnswers + (isCorrect ? 1 : 0),
      totalQuestions: progress.totalQuestions,
      timeSpent: progress.timeSpent,
      isCompleted: progress.currentQuestion + 1 >= progress.totalQuestions,
      startedAt: progress.startedAt,
      completedAt: progress.currentQuestion + 1 >= progress.totalQuestions ? DateTime.now() : null,
      score: progress.score + (isCorrect ? 10 : 0),
      userAnswers: {...progress.userAnswers, questionId: answerId},
    );

    await updateQuizProgress(updatedProgress);

    if (updatedProgress.isCompleted) {
      await _awardQuizPoints(updatedProgress);
    }
  }

  static Future<void> _awardQuizPoints(QuizProgress progress) async {
    try {
      final quiz = await getQuizById(progress.quizId);
      if (quiz != null) {
        final percentage = progress.correctAnswers / progress.totalQuestions;
        int pointsToAward;

        if (percentage >= 0.9) {
          pointsToAward = quiz.points;
        } else if (percentage >= 0.7) {
          pointsToAward = (quiz.points * 0.8).round();
        } else if (percentage >= 0.5) {
          pointsToAward = (quiz.points * 0.6).round();
        } else {
          pointsToAward = (quiz.points * 0.3).round();
        }

        await _userService.addUserPoints(progress.userId, pointsToAward);
        await _userService.addUserAction(progress.userId);
        print('Awarded $pointsToAward points to user ${progress.userId} for completing quiz ${progress.quizId}');
      }
    } catch (e) {
      print('Error awarding quiz points: $e');
    }
  }

  static Future<List<QuizAttempt>> getUserQuizAttempts(String userId, String quizId) async {
    final localAttempts = _getLocalAttempts(userId, quizId);
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_attempts')
          .where('quizId', isEqualTo: quizId)
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapshot.docs) {
        try {
          final attempt = QuizAttempt.fromJson(doc.data());
          _saveLocalAttempt(attempt);
        } catch (_) {}
      }
      return _getLocalAttempts(userId, quizId);
    } catch (e) {
      print('ℹ️ Firestore getUserQuizAttempts fallback to local: $e');
      return localAttempts;
    }
  }

  static Future<QuizAttempt?> getUserBestAttempt(String userId, String quizId) async {
    try {
      final attempts = await getUserQuizAttempts(userId, quizId);
      if (attempts.isEmpty) return null;

      attempts.sort((a, b) => b.finalScore.compareTo(a.finalScore));
      return attempts.first;
    } catch (e) {
      print('❌ Error fetching user best attempt: $e');
      return null;
    }
  }

  static Future<QuizAttempt?> getUserLatestAttempt(String userId, String quizId) async {
    try {
      final attempts = await getUserQuizAttempts(userId, quizId);
      if (attempts.isEmpty) return null;

      attempts.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return attempts.first;
    } catch (e) {
      print('❌ Error fetching user latest attempt: $e');
      return null;
    }
  }

  static Future<QuizAttempt> createQuizAttempt(String userId, String quizId, int totalQuestions) async {
    final existingAttempts = await getUserQuizAttempts(userId, quizId);
    final attemptNumber = existingAttempts.length + 1;

    print('🔍 Creating Quiz Attempt Debug:');
    print('  User ID: $userId');
    print('  Quiz ID: $quizId');
    print('  Total Questions: $totalQuestions');
    print('  Attempt Number: $attemptNumber');

    final attempt = QuizAttempt(
      id: _uuid.v4(),
      quizId: quizId,
      userId: userId,
      attemptNumber: attemptNumber,
      startedAt: DateTime.now(),
      finalScore: 0,
      timeSpent: 0,
      isCompleted: false,
      totalQuestions: totalQuestions,
      correctAnswers: 0,
      questionResults: [],
    );

    // Save locally first so user is never blocked
    _saveLocalAttempt(attempt);

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_attempts')
          .doc(attempt.id)
          .set(attempt.toJson())
          .timeout(const Duration(seconds: 3));

      print('✅ Created quiz attempt in Firestore: ${attempt.id}');
    } catch (e) {
      print('ℹ️ Firestore create quiz attempt offline/skipped: $e');
    }

    return attempt;
  }

  static Future<void> submitAnswerToAttempt(QuizAttempt attempt, String questionId, String answerId, bool isCorrect, int questionTimeSpent) async {
    try {
      final quiz = await getQuizById(attempt.quizId);
      int totalQuestions = attempt.totalQuestions;
      if (quiz != null && totalQuestions != quiz.questions.length) {
        totalQuestions = quiz.questions.length;
      }

      final questionResult = QuestionResult(
        questionId: questionId,
        selectedAnswerId: answerId,
        isCorrect: isCorrect,
        timeSpent: questionTimeSpent,
        answeredAt: DateTime.now(),
      );

      final updatedQuestionResults = [...attempt.questionResults, questionResult];
      final newCorrectAnswers = attempt.correctAnswers + (isCorrect ? 1 : 0);
      final isCompleted = updatedQuestionResults.length >= totalQuestions;
      final finalScore = totalQuestions > 0
          ? (newCorrectAnswers / totalQuestions * 100).round()
          : 0;
      final totalTimeSpent = attempt.timeSpent + questionTimeSpent;

      final updatedAttempt = QuizAttempt(
        id: attempt.id,
        quizId: attempt.quizId,
        userId: attempt.userId,
        attemptNumber: attempt.attemptNumber,
        startedAt: attempt.startedAt,
        completedAt: isCompleted ? DateTime.now() : null,
        finalScore: finalScore,
        timeSpent: totalTimeSpent,
        isCompleted: isCompleted,
        totalQuestions: totalQuestions,
        correctAnswers: newCorrectAnswers,
        questionResults: updatedQuestionResults,
      );

      // Save locally first
      _saveLocalAttempt(updatedAttempt);

      // Attempt Firestore sync
      try {
        await _firestore
            .collection('users')
            .doc(attempt.userId)
            .collection('quiz_attempts')
            .doc(attempt.id)
            .set(updatedAttempt.toJson())
            .timeout(const Duration(seconds: 3));
        print('✅ Synced quiz attempt to Firestore: ${attempt.id}');
      } catch (e) {
        print('ℹ️ Firestore sync answer offline/skipped: $e');
      }

      if (isCompleted) {
        await _awardQuizPointsForAttempt(updatedAttempt);
      }
    } catch (e) {
      print('❌ Error in submitAnswerToAttempt: $e');
    }
  }

  static Future<void> _awardQuizPointsForAttempt(QuizAttempt attempt) async {
    try {
      final quiz = await getQuizById(attempt.quizId);
      if (quiz == null) return;

      final newPoints = (attempt.finalScore / 100 * quiz.points).round();
      final previousBestAttempt = await getUserBestAttempt(attempt.userId, attempt.quizId);

      int pointsToAward = 0;

      if (previousBestAttempt == null || previousBestAttempt.id == attempt.id) {
        pointsToAward = newPoints;
        print('🎯 First attempt or new best - awarding $pointsToAward points');
      } else {
        final previousBestPoints = (previousBestAttempt.finalScore / 100 * quiz.points).round();
        if (newPoints > previousBestPoints) {
          pointsToAward = newPoints - previousBestPoints;
          print('📈 Improved performance! Previous best: $previousBestPoints, New: $newPoints, Awarding difference: $pointsToAward');
        } else {
          pointsToAward = 0;
          print('🚫 No improvement over previous best ($previousBestPoints points). No additional points awarded.');
        }
      }

      if (pointsToAward > 0) {
        final userService = UserService();
        await userService.addUserPoints(attempt.userId, pointsToAward);
        await userService.addUserAction(attempt.userId);
        print('✅ Awarded $pointsToAward points for quiz ${attempt.quizId} (${attempt.finalScore}% score)');

        await _trackMaxQuizPoints(attempt.userId, attempt.quizId, newPoints);
      } else {
        print('ℹ️ No points awarded - user already achieved better or equal performance');
      }
    } catch (e) {
      print('❌ Error awarding quiz points: $e');
    }
  }

  static Future<void> _trackMaxQuizPoints(String userId, String quizId, int maxPoints) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_max_points')
          .doc(quizId)
          .set({
        'quizId': quizId,
        'maxPointsEarned': maxPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));

      print('📊 Tracked max points for user $userId on quiz $quizId: $maxPoints points');
    } catch (e) {
      print('ℹ️ Offline/skipped tracking max quiz points: $e');
    }
  }

  static Future<int> getMaxPointsEarned(String userId, String quizId) async {
    try {
      final best = await getUserBestAttempt(userId, quizId);
      if (best != null) {
        final quiz = await getQuizById(quizId);
        if (quiz != null) {
          return (best.finalScore / 100 * quiz.points).round();
        }
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_max_points')
          .doc(quizId)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        return doc.data()?['maxPointsEarned'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> hasUserCompletedQuizPerfectly(String userId, String quizId) async {
    try {
      final quiz = await getQuizById(quizId);
      if (quiz == null) return false;

      final best = await getUserBestAttempt(userId, quizId);
      if (best != null && best.isCompleted && best.finalScore >= 100) {
        return true;
      }

      final maxPointsEarned = await getMaxPointsEarned(userId, quizId);
      return maxPointsEarned >= quiz.points;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getUserQuizStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_attempts')
          .where('isCompleted', isEqualTo: true)
          .get();

      final attempts = snapshot.docs.map((doc) => QuizAttempt.fromJson(doc.data())).toList();

      if (attempts.isEmpty) {
        return {
          'totalAttempts': 0,
          'completedAttempts': 0,
          'averageScore': 0,
          'bestScore': 0,
          'totalPointsEarned': 0,
          'totalTimeSpent': 0,
        };
      }

      final totalAttempts = attempts.length;
      final averageScore = attempts.map((a) => a.finalScore).reduce((a, b) => a + b) / totalAttempts;
      final bestScore = attempts.map((a) => a.finalScore).reduce((a, b) => a > b ? a : b);
      final totalTimeSpent = attempts.map((a) => a.timeSpent).reduce((a, b) => a + b);

      return {
        'totalAttempts': totalAttempts,
        'completedAttempts': totalAttempts,
        'averageScore': averageScore.round(),
        'bestScore': bestScore,
        'totalPointsEarned': attempts.where((a) => a.isPassed).length * 10,
        'totalTimeSpent': totalTimeSpent,
      };
    } catch (e) {
      print('❌ Error fetching user quiz stats: $e');
      return {};
    }
  }

  static Future<void> migrateOldQuizProgress() async {
    try {
      print('🔄 Starting quiz progress migration...');

      final snapshot = await _firestore.collection('quiz_progress').get();
      int migrated = 0;

      for (final doc in snapshot.docs) {
        try {
          final oldProgress = QuizProgress.fromJson(doc.data());

          final attempt = QuizAttempt(
            id: oldProgress.id,
            quizId: oldProgress.quizId,
            userId: oldProgress.userId,
            attemptNumber: 1,
            startedAt: oldProgress.startedAt,
            completedAt: oldProgress.completedAt,
            finalScore: oldProgress.totalQuestions > 0
                ? (oldProgress.correctAnswers / oldProgress.totalQuestions * 100).round()
                : 0,
            timeSpent: oldProgress.timeSpent,
            isCompleted: oldProgress.isCompleted,
            totalQuestions: oldProgress.totalQuestions,
            correctAnswers: oldProgress.correctAnswers,
            questionResults: [],
          );

          await _firestore
              .collection('users')
              .doc(oldProgress.userId)
              .collection('quiz_attempts')
              .doc(attempt.id)
              .set(attempt.toJson());

          migrated++;
        } catch (e) {
          print('❌ Error migrating progress ${doc.id}: $e');
        }
      }

      print('✅ Migrated $migrated quiz progress records');
    } catch (e) {
      print('❌ Error during migration: $e');
    }
  }

  static List<Quiz> _getSampleQuizzes() {
    return [
      Quiz(
        id: 'climate-change-basics',
        title: 'What is Climate Change',
        description: 'Learn about the fundamentals of climate change and its impact on our planet.',
        author: 'e-icon World Contest',
        category: 'Climate Science',
        questionCount: 10,
        timeLimit: 165,
        points: 50,
        rating: 4.8,
        imageUrl: 'assets/images/quiz/climate_basics.png',
        videoUrl: 'https://www.youtube.com/watch?v=example',
        questions: _getClimateChangeQuestions(),
        createdAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      Quiz(
        id: 'climate-causes',
        title: 'Climate Change: Causes',
        description: 'Explore the various causes of climate change and human impact on the environment.',
        author: 'e-icon World Contest',
        category: 'Climate Science',
        questionCount: 12,
        timeLimit: 192,
        points: 60,
        rating: 4.0,
        imageUrl: 'assets/images/quiz/climate_causes.png',
        videoUrl: 'https://www.youtube.com/watch?v=example2',
        questions: _getClimateCausesQuestions(),
        createdAt: DateTime.now().subtract(Duration(days: 25)),
      ),
      Quiz(
        id: 'sdg-climate-action',
        title: 'SDG 13: Climate Action',
        description: 'Understanding the United Nations Sustainable Development Goal 13 and climate action initiatives.',
        author: 'e-icon World Contest',
        category: 'Sustainability',
        questionCount: 10,
        timeLimit: 120,
        points: 50,
        rating: 4.5,
        imageUrl: 'assets/images/quiz/sdg13.png',
        videoUrl: 'https://www.youtube.com/watch?v=example3',
        questions: _getSDGQuestions(),
        createdAt: DateTime.now().subtract(Duration(days: 20)),
      ),
      Quiz(
        id: 'renewable-energy',
        title: 'Renewable Energy Sources',
        description: 'Test your knowledge about solar, wind, hydroelectric, and other renewable energy technologies.',
        author: 'e-icon World Contest',
        category: 'Clean Energy',
        questionCount: 8,
        timeLimit: 120,
        points: 40,
        rating: 4.2,
        imageUrl: 'assets/images/quiz/renewable_energy.png',
        videoUrl: 'https://www.youtube.com/watch?v=example4',
        questions: _getRenewableEnergyQuestions(),
        createdAt: DateTime.now().subtract(Duration(days: 15)),
      ),
      Quiz(
        id: 'carbon-footprint',
        title: 'Understanding Carbon Footprint',
        description: 'Learn about carbon footprints and how to reduce your environmental impact.',
        author: 'e-icon World Contest',
        category: 'Sustainability',
        questionCount: 6,
        timeLimit: 90,
        points: 30,
        rating: 4.6,
        imageUrl: 'assets/images/quiz/carbon_footprint.png',
        videoUrl: 'https://www.youtube.com/watch?v=example5',
        questions: _getCarbonFootprintQuestions(),
        createdAt: DateTime.now().subtract(Duration(days: 10)),
      ),
    ];
  }

  static List<QuizQuestion> _getClimateChangeQuestions() {
    return [
      QuizQuestion(
        id: 'cc_1',
        question: 'What is climate change?',
        answers: [
          QuizAnswer(id: 'cc_1_a', text: 'A natural increase in weather events like rain and snow every year', isCorrect: false),
          QuizAnswer(id: 'cc_1_b', text: 'The seasonal change from summer to winter and vice versa', isCorrect: false),
          QuizAnswer(id: 'cc_1_c', text: 'A sudden change in local weather due to storms or floods', isCorrect: false),
          QuizAnswer(id: 'cc_1_d', text: 'A long-term shift in global or regional climate patterns', isCorrect: true),
          QuizAnswer(id: 'cc_1_e', text: 'A temporary increase in temperature during heatwaves', isCorrect: false),
        ],
        correctAnswerId: 'cc_1_d',
        explanation: 'Climate change refers to long-term shifts in global or regional climate patterns, including temperature, precipitation, and wind patterns.',
        points: 10,
      ),
      QuizQuestion(
        id: 'cc_2',
        question: 'Which of the following is a greenhouse gas?',
        answers: [
          QuizAnswer(id: 'cc_2_a', text: 'Oxygen (O₂)', isCorrect: false),
          QuizAnswer(id: 'cc_2_b', text: 'Nitrogen (N₂)', isCorrect: false),
          QuizAnswer(id: 'cc_2_c', text: 'Carbon Dioxide (CO₂)', isCorrect: true),
          QuizAnswer(id: 'cc_2_d', text: 'Hydrogen (H₂)', isCorrect: false),
        ],
        correctAnswerId: 'cc_2_c',
        explanation: 'Carbon dioxide is a major greenhouse gas that traps heat in the Earth\'s atmosphere.',
        points: 10,
      ),
      QuizQuestion(
        id: 'cc_3',
        question: 'What is the main cause of current climate change?',
        answers: [
          QuizAnswer(id: 'cc_3_a', text: 'Volcanic eruptions', isCorrect: false),
          QuizAnswer(id: 'cc_3_b', text: 'Human activities', isCorrect: true),
          QuizAnswer(id: 'cc_3_c', text: 'Solar flares', isCorrect: false),
          QuizAnswer(id: 'cc_3_d', text: 'Natural climate cycles', isCorrect: false),
        ],
        correctAnswerId: 'cc_3_b',
        explanation: 'Human activities, particularly the burning of fossil fuels, are the primary cause of current climate change.',
        points: 10,
      ),
    ];
  }

  static List<QuizQuestion> _getClimateCausesQuestions() {
    return [
      QuizQuestion(
        id: 'causes_1',
        question: 'Which human activity contributes most to climate change?',
        answers: [
          QuizAnswer(id: 'causes_1_a', text: 'Burning fossil fuels', isCorrect: true),
          QuizAnswer(id: 'causes_1_b', text: 'Deforestation', isCorrect: false),
          QuizAnswer(id: 'causes_1_c', text: 'Agriculture', isCorrect: false),
          QuizAnswer(id: 'causes_1_d', text: 'Industrial processes', isCorrect: false),
        ],
        correctAnswerId: 'causes_1_a',
        explanation: 'Burning fossil fuels for energy production is the largest contributor to greenhouse gas emissions.',
        points: 10,
      ),
      QuizQuestion(
        id: 'causes_2',
        question: 'What is the greenhouse effect?',
        answers: [
          QuizAnswer(id: 'causes_2_a', text: 'A natural process that warms the Earth', isCorrect: true),
          QuizAnswer(id: 'causes_2_b', text: 'A man-made warming process', isCorrect: false),
          QuizAnswer(id: 'causes_2_c', text: 'A cooling effect from clouds', isCorrect: false),
          QuizAnswer(id: 'causes_2_d', text: 'A type of air pollution', isCorrect: false),
        ],
        correctAnswerId: 'causes_2_a',
        explanation: 'The greenhouse effect is a natural process where certain gases in the atmosphere trap heat from the sun.',
        points: 10,
      ),
    ];
  }

  static List<QuizQuestion> _getSDGQuestions() {
    return [
      QuizQuestion(
        id: 'sdg_1',
        question: 'What does SDG 13 stand for?',
        answers: [
          QuizAnswer(id: 'sdg_1_a', text: 'Sustainable Development Goal 13', isCorrect: true),
          QuizAnswer(id: 'sdg_1_b', text: 'Sustainable Development Group 13', isCorrect: false),
          QuizAnswer(id: 'sdg_1_c', text: 'Sustainable Development Guide 13', isCorrect: false),
          QuizAnswer(id: 'sdg_1_d', text: 'Sustainable Development Global 13', isCorrect: false),
        ],
        correctAnswerId: 'sdg_1_a',
        explanation: 'SDG 13 stands for Sustainable Development Goal 13, which focuses on Climate Action.',
        points: 10,
      ),
      QuizQuestion(
        id: 'sdg_2',
        question: 'What is the main focus of SDG 13?',
        answers: [
          QuizAnswer(id: 'sdg_2_a', text: 'Economic growth', isCorrect: false),
          QuizAnswer(id: 'sdg_2_b', text: 'Climate action', isCorrect: true),
          QuizAnswer(id: 'sdg_2_c', text: 'Education for all', isCorrect: false),
          QuizAnswer(id: 'sdg_2_d', text: 'Clean water', isCorrect: false),
        ],
        correctAnswerId: 'sdg_2_b',
        explanation: 'SDG 13 focuses on taking urgent action to combat climate change and its impacts.',
        points: 10,
      ),
    ];
  }

  static List<QuizQuestion> _getRenewableEnergyQuestions() {
    return [
      QuizQuestion(
        id: 're_1',
        question: 'Which renewable energy source is the fastest-growing globally?',
        answers: [
          QuizAnswer(id: 're_1_a', text: 'Solar power', isCorrect: true),
          QuizAnswer(id: 're_1_b', text: 'Wind power', isCorrect: false),
          QuizAnswer(id: 're_1_c', text: 'Hydroelectric power', isCorrect: false),
          QuizAnswer(id: 're_1_d', text: 'Geothermal power', isCorrect: false),
        ],
        correctAnswerId: 're_1_a',
        explanation: 'Solar power is the fastest-growing renewable energy source globally, with costs decreasing rapidly.',
        points: 10,
      ),
      QuizQuestion(
        id: 're_2',
        question: 'What is the main advantage of renewable energy over fossil fuels?',
        answers: [
          QuizAnswer(id: 're_2_a', text: 'Lower cost', isCorrect: false),
          QuizAnswer(id: 're_2_b', text: 'No greenhouse gas emissions', isCorrect: true),
          QuizAnswer(id: 're_2_c', text: 'Always available', isCorrect: false),
          QuizAnswer(id: 're_2_d', text: 'Easier to transport', isCorrect: false),
        ],
        correctAnswerId: 're_2_b',
        explanation: 'Renewable energy sources produce little to no greenhouse gas emissions during operation.',
        points: 10,
      ),
      QuizQuestion(
        id: 're_3',
        question: 'Which country leads in wind energy production?',
        answers: [
          QuizAnswer(id: 're_3_a', text: 'United States', isCorrect: false),
          QuizAnswer(id: 're_3_b', text: 'China', isCorrect: true),
          QuizAnswer(id: 're_3_c', text: 'Germany', isCorrect: false),
          QuizAnswer(id: 're_3_d', text: 'Denmark', isCorrect: false),
        ],
        correctAnswerId: 're_3_b',
        explanation: 'China leads the world in wind energy production and installed capacity.',
        points: 10,
      ),
    ];
  }

  static List<QuizQuestion> _getCarbonFootprintQuestions() {
    return [
      QuizQuestion(
        id: 'cf_1',
        question: 'What is a carbon footprint?',
        answers: [
          QuizAnswer(id: 'cf_1_a', text: 'The size of your shoe', isCorrect: false),
          QuizAnswer(id: 'cf_1_b', text: 'Total greenhouse gas emissions caused by your activities', isCorrect: true),
          QuizAnswer(id: 'cf_1_c', text: 'The amount of carbon in your body', isCorrect: false),
          QuizAnswer(id: 'cf_1_d', text: 'Your carbon credit score', isCorrect: false),
        ],
        correctAnswerId: 'cf_1_b',
        explanation: 'A carbon footprint is the total greenhouse gas emissions caused by an individual, organization, or activity.',
        points: 10,
      ),
      QuizQuestion(
        id: 'cf_2',
        question: 'Which activity has the highest carbon footprint?',
        answers: [
          QuizAnswer(id: 'cf_2_a', text: 'Walking', isCorrect: false),
          QuizAnswer(id: 'cf_2_b', text: 'Taking public transport', isCorrect: false),
          QuizAnswer(id: 'cf_2_c', text: 'Flying long distances', isCorrect: true),
          QuizAnswer(id: 'cf_2_d', text: 'Eating vegetables', isCorrect: false),
        ],
        correctAnswerId: 'cf_2_c',
        explanation: 'Flying long distances has one of the highest carbon footprints per passenger kilometer.',
        points: 10,
      ),
      QuizQuestion(
        id: 'cf_3',
        question: 'How can you reduce your carbon footprint?',
        answers: [
          QuizAnswer(id: 'cf_3_a', text: 'Use energy-efficient appliances', isCorrect: true),
          QuizAnswer(id: 'cf_3_b', text: 'Drive more often', isCorrect: false),
          QuizAnswer(id: 'cf_3_c', text: 'Use more plastic', isCorrect: false),
          QuizAnswer(id: 'cf_3_d', text: 'Leave lights on', isCorrect: false),
        ],
        correctAnswerId: 'cf_3_a',
        explanation: 'Using energy-efficient appliances is one of the most effective ways to reduce your carbon footprint.',
        points: 10,
      ),
    ];
  }

  static Future<void> addQuiz(Quiz quiz) async {
    try {
      await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());
    } catch (e) {
      print('Error adding quiz: $e');
    }
  }

  static Future<void> createSampleQuizzes() async {
    try {
      print('📚 Creating sample quizzes in Firebase...');

      final sampleQuizzes = _getSampleQuizzes();

      for (final quiz in sampleQuizzes) {
        await addQuiz(quiz);
        print('✅ Added quiz: ${quiz.title}');
      }

      print('🎉 Successfully created ${sampleQuizzes.length} sample quizzes in Firebase');
    } catch (e) {
      print('❌ Error creating sample quizzes: $e');
      rethrow;
    }
  }

  static Future<void> ensureSampleQuizzesExist() async {
    try {
      final snapshot = await _firestore.collection('quizzes').limit(1).get();

      if (snapshot.docs.isEmpty) {
        print('📝 No quizzes found in Firebase, creating sample quizzes...');
        await createSampleQuizzes();
      } else {
        print('✅ Quizzes already exist in Firebase');
      }
    } catch (e) {
      print('❌ Error checking quizzes: $e');
      await createSampleQuizzes();
    }
  }

  static Future<void> updateQuizRating(String quizId, double newRating) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).update({
        'rating': newRating,
      });
    } catch (e) {
      print('Error updating quiz rating: $e');
    }
  }


  static List<QuizQuestion> _getSampleQuestions() {
    return [
      QuizQuestion(
        id: 'sample_1',
        question: 'What is climate change?',
        answers: [
          QuizAnswer(id: 'sample_1_a', text: 'A long-term change in global weather patterns', isCorrect: true),
          QuizAnswer(id: 'sample_1_b', text: 'A short-term weather event', isCorrect: false),
          QuizAnswer(id: 'sample_1_c', text: 'A seasonal change', isCorrect: false),
          QuizAnswer(id: 'sample_1_d', text: 'A daily temperature change', isCorrect: false),
        ],
        correctAnswerId: 'sample_1_a',
        explanation: 'Climate change refers to long-term changes in global weather patterns and average temperatures.',
        points: 10,
      ),
    ];
  }

  static Future<void> createTestQuiz() async {
    try {
      print('🧪 Creating test quiz...');

      final testQuiz = Quiz(
        id: 'test-quiz',
        title: 'Test Quiz',
        description: 'A simple test quiz to verify scoring',
        author: 'Test',
        category: 'Test',
        questionCount: 2,
        timeLimit: 60,
        points: 20,
        rating: 5.0,
        imageUrl: '',
        videoUrl: '',
        questions: [
          QuizQuestion(
            id: 'test_1',
            question: 'What is 2 + 2?',
            answers: [
              QuizAnswer(id: 'test_1_a', text: '3', isCorrect: false),
              QuizAnswer(id: 'test_1_b', text: '4', isCorrect: true),
              QuizAnswer(id: 'test_1_c', text: '5', isCorrect: false),
            ],
            correctAnswerId: 'test_1_b',
            explanation: '2 + 2 = 4',
            points: 10,
          ),
          QuizQuestion(
            id: 'test_2',
            question: 'What is 3 + 3?',
            answers: [
              QuizAnswer(id: 'test_2_a', text: '5', isCorrect: false),
              QuizAnswer(id: 'test_2_b', text: '6', isCorrect: true),
              QuizAnswer(id: 'test_2_c', text: '7', isCorrect: false),
            ],
            correctAnswerId: 'test_2_b',
            explanation: '3 + 3 = 6',
            points: 10,
          ),
        ],
        createdAt: DateTime.now(),
      );

      await addQuiz(testQuiz);
      print('✅ Test quiz created successfully');
    } catch (e) {
      print('❌ Error creating test quiz: $e');
    }
  }
}