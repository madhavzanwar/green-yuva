import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import '../services/quiz_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt? attempt;
  final AppUser? user;

  const QuizDetailScreen({
    Key? key,
    required this.quiz,
    this.attempt,
    this.user,
  }) : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  bool _isLoading = false;
  String? _userId;
  bool _isPerfectlyCompleted = false;
  late Quiz _currentQuiz;

  @override
  void initState() {
    super.initState();
    _currentQuiz = widget.quiz;
    _hydrateQuizIfNeeded();
    _getCurrentUser();
  }

  Future<void> _hydrateQuizIfNeeded() async {
    if (_currentQuiz.questions.isEmpty) {
      try {
        final hydrated = await QuizService.getQuizById(_currentQuiz.id);
        if (hydrated != null && hydrated.questions.isNotEmpty) {
          if (mounted) setState(() { _currentQuiz = hydrated; });
          return;
        }
        final jsonList = await QuizService.loadQuizzesFromJSON();
        final match = jsonList.firstWhere(
          (q) => q.id == _currentQuiz.id || q.title.toLowerCase().trim() == _currentQuiz.title.toLowerCase().trim(),
          orElse: () => jsonList.isNotEmpty ? jsonList.first : _currentQuiz,
        );
        if (match.questions.isNotEmpty && mounted) {
          setState(() { _currentQuiz = match; });
        }
      } catch (e) {
        print('Error hydrating quiz: $e');
      }
    }
  }

  Future<void> _getCurrentUser() async {
    if (widget.user != null) {
      if (mounted) {
        setState(() {
          _userId = widget.user!.id;
        });
      }
      _checkPerfectCompletion();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _userId = user.uid;
        });
      }
    } else {
      final local = await UserService().getLocalUser();
      if (mounted) {
        setState(() {
          _userId = local?.id;
        });
      }
    }
    _checkPerfectCompletion();
  }

  Future<void> _checkPerfectCompletion() async {
    if (_userId != null) {
      final isPerfect = await QuizService.hasUserCompletedQuizPerfectly(_userId!, _currentQuiz.id);
      if (mounted) {
        setState(() {
          _isPerfectlyCompleted = isPerfect;
        });
      }
    }
  }

  Future<void> _startQuiz() async {
    if (_userId == null) {
      await _getCurrentUser();
    }
    if (_userId == null) {
      _userId = 'local_user_${DateTime.now().millisecondsSinceEpoch}';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure questions are populated
      if (_currentQuiz.questions.isEmpty) {
        final jsonList = await QuizService.loadQuizzesFromJSON();
        final match = jsonList.firstWhere(
          (q) => q.id == _currentQuiz.id || q.title.toLowerCase().trim() == _currentQuiz.title.toLowerCase().trim(),
          orElse: () => jsonList.isNotEmpty ? jsonList.first : _currentQuiz,
        );
        if (match.questions.isNotEmpty) {
          _currentQuiz = match;
        }
      }

      final totalQuestions = _currentQuiz.questions.isNotEmpty ? _currentQuiz.questions.length : 10;
      QuizAttempt attempt;

      if (widget.attempt != null) {
        attempt = widget.attempt!;
      } else {
        final latestAttempt = await QuizService.getUserLatestAttempt(_userId!, _currentQuiz.id);
        if (latestAttempt != null && !latestAttempt.isCompleted && latestAttempt.totalQuestions == totalQuestions) {
          attempt = latestAttempt;
        } else {
          attempt = await QuizService.createQuizAttempt(
            _userId!,
            _currentQuiz.id,
            totalQuestions,
          );
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizTakingScreen(
              quiz: _currentQuiz,
              attempt: attempt,
            ),
          ),
        );
      }
    } catch (e) {
      print('Failed to start quiz error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start quiz: $e'),
            backgroundColor: AppColors.dustyCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.solidBlack, width: 2.0),
          ),
          child: Text(
            'YUVASENSE QUIZ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.solidBlack,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Quiz Hero Card
            NeoCard(
              color: AppColors.cardWhite,
              radius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricMint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solidBlack, width: 1.4),
                        ),
                        child: Text(
                          widget.quiz.category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.butterYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solidBlack, width: 1.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, size: 14, color: AppColors.solidBlack),
                            const SizedBox(width: 4),
                            Text(
                              '+${widget.quiz.points} Karma Coins',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.quiz.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.quiz.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.solidBlack.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick Parameters Grid
            Row(
              children: [
                Expanded(
                  child: NeoCard(
                    color: AppColors.softSky,
                    radius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 22, color: AppColors.solidBlack),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentQuiz.questions.isNotEmpty ? _currentQuiz.questions.length : 10} Questions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                        Text(
                          '4 options each',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.solidBlack.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeoCard(
                    color: AppColors.butterYellow,
                    radius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.timer_outlined, size: 22, color: AppColors.solidBlack),
                        const SizedBox(height: 4),
                        Text(
                          '15 Minutes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                        Text(
                          'Active countdown',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.solidBlack.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeoCard(
                    color: AppColors.sageGreen,
                    radius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.military_tech_outlined, size: 22, color: AppColors.solidBlack),
                        const SizedBox(height: 4),
                        Text(
                          'Karma Bonus',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                        Text(
                          'Auto credited',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.solidBlack.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Instructions Card
            NeoCard(
              color: AppColors.cardWhite,
              radius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RULES & FORMAT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRuleRow('⏱️', '15:00 Active Countdown', 'Quiz will automatically submit your selected answers when timer hits 00:00.'),
                  const SizedBox(height: 8),
                  _buildRuleRow('🎯', 'One Correct Choice', 'Each question has 4 options (A, B, C, D) with 1 verified correct answer.'),
                  const SizedBox(height: 8),
                  _buildRuleRow('💡', 'Instant Explanations', 'Learn why each answer is correct with educational scientific debriefs upon completion.'),
                  const SizedBox(height: 8),
                  _buildRuleRow('🪙', 'Karma Coins Reward', 'Earn points toward your campus GreenKarma ranking for scoring 50% or higher.'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start Quiz Button
            NeoButton(
              text: _isLoading
                  ? 'Initializing...'
                  : _isPerfectlyCompleted
                      ? 'Retake Quiz (15 Mins)'
                      : 'Start 15-Minute Quiz',
              color: AppColors.electricMint,
              textColor: AppColors.solidBlack,
              height: 52,
              onPressed: _isLoading ? null : _startQuiz,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.solidBlack,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.solidBlack.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt attempt;

  const QuizTakingScreen({
    Key? key,
    required this.quiz,
    required this.attempt,
  }) : super(key: key);

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isSubmitting = false;
  DateTime _questionStartTime = DateTime.now();
  late QuizAttempt _currentAttempt;

  // 15-Minute Countdown Timer
  Timer? _countdownTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _currentAttempt = widget.attempt;
    _currentQuestionIndex = widget.attempt.questionResults.length;
    if (_currentQuestionIndex >= widget.quiz.questions.length) {
      _currentQuestionIndex = 0;
    }
    _questionStartTime = DateTime.now();

    // Default to 900 seconds (15 minutes) or quiz timeLimit
    final limit = widget.quiz.timeLimit > 0 ? widget.quiz.timeLimit : 900;
    _remainingSeconds = limit;

    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⏰ Time's up (15:00)! Automatically submitting your quiz..."),
        backgroundColor: AppColors.dustyCoral,
        duration: Duration(seconds: 3),
      ),
    );

    // If an answer was selected for current question, submit it
    if (_selectedAnswer != null) {
      try {
        final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
        final isCorrect = _selectedAnswer == currentQuestion.correctAnswerId;
        final timeSpent = DateTime.now().difference(_questionStartTime).inSeconds;

        await QuizService.submitAnswerToAttempt(
          _currentAttempt,
          currentQuestion.id,
          _selectedAnswer!,
          isCorrect,
          timeSpent,
        );
      } catch (e) {
        print('Error auto-submitting last question: $e');
      }
    }

    final latestAttempt = await QuizService.getUserLatestAttempt(
      _currentAttempt.userId,
      _currentAttempt.quizId,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            quiz: widget.quiz,
            attempt: latestAttempt ?? _currentAttempt,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
      final isCorrect = _selectedAnswer == currentQuestion.correctAnswerId;
      final questionTimeSpent = DateTime.now().difference(_questionStartTime).inSeconds;

      await QuizService.submitAnswerToAttempt(
        _currentAttempt,
        currentQuestion.id,
        _selectedAnswer!,
        isCorrect,
        questionTimeSpent,
      );

      final updatedAttempt = await QuizService.getUserLatestAttempt(
        _currentAttempt.userId,
        _currentAttempt.quizId,
      );
      if (updatedAttempt != null) {
        _currentAttempt = updatedAttempt;
      }

      if (_currentQuestionIndex + 1 >= widget.quiz.questions.length) {
        _countdownTimer?.cancel();
        final latestAttempt = await QuizService.getUserLatestAttempt(
          _currentAttempt.userId,
          _currentAttempt.quizId,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuizResultScreen(
                quiz: widget.quiz,
                attempt: latestAttempt ?? _currentAttempt,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
          _questionStartTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit answer: $e'),
            backgroundColor: AppColors.dustyCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatTimer() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty || _currentQuestionIndex >= widget.quiz.questions.length) {
      return const Scaffold(
        backgroundColor: AppColors.paperCream,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.solidBlack, strokeWidth: 2.5),
        ),
      );
    }
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final isLowTime = _remainingSeconds < 120; // Less than 2 minutes left

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
                    ),
                    title: Text(
                      'Leave Quiz?',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    content: Text(
                      'Your active 15:00 countdown is running. Are you sure you want to exit now?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Resume',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Exit',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLowTime ? AppColors.dustyCoral : AppColors.butterYellow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.solidBlack, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(1.5, 1.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLowTime ? Icons.warning_amber_rounded : Icons.timer_outlined,
                size: 16,
                color: AppColors.solidBlack,
              ),
              const SizedBox(width: 5),
              Text(
                '⏱ ${_formatTimer()} remaining',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Progress Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUESTION ${_currentQuestionIndex + 1} OF ${widget.quiz.questions.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${((_currentQuestionIndex + 1) / widget.quiz.questions.length * 100).toInt()}% Done',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Segmented / Neo Progress Bar
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.solidBlack, width: 1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.electricMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Question Statement Card
              NeoCard(
                color: AppColors.cardWhite,
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Text(
                  currentQuestion.question,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4 Options
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.answers.length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion.answers[index];
                    final isSelected = _selectedAnswer == option.id;
                    final letter = String.fromCharCode(65 + index); // A, B, C, D

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeoCard(
                        color: isSelected ? AppColors.butterYellow : AppColors.cardWhite,
                        radius: 16,
                        borderWidth: 2.0,
                        shadowOffset: isSelected ? const Offset(1.5, 1.5) : const Offset(3.0, 3.0),
                        padding: const EdgeInsets.all(12),
                        onTap: () {
                          setState(() {
                            _selectedAnswer = option.id;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.solidBlack : AppColors.paperCream,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.solidBlack, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? AppColors.pureWhite : AppColors.solidBlack,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: AppColors.solidBlack,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: AppColors.solidBlack,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Submit & Next Button
              NeoButton(
                text: _isSubmitting
                    ? 'Submitting...'
                    : _currentQuestionIndex + 1 >= widget.quiz.questions.length
                        ? 'Finish Quiz & View Results'
                        : 'Submit & Next Question →',
                color: _selectedAnswer == null ? AppColors.paperCream : AppColors.electricMint,
                textColor: AppColors.solidBlack,
                height: 52,
                onPressed: _selectedAnswer == null || _isSubmitting ? null : _submitAnswer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt attempt;

  const QuizResultScreen({
    Key? key,
    required this.quiz,
    required this.attempt,
  }) : super(key: key);

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _pointsAwarded = false;

  @override
  void initState() {
    super.initState();
    _awardPoints();
  }

  Future<void> _awardPoints() async {
    if (_pointsAwarded) return;

    try {
      String targetUserId = widget.attempt.userId;
      if (targetUserId.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          targetUserId = user.uid;
        } else {
          final local = await UserService().getLocalUser();
          if (local == null) return; // No user available — skip awarding points
          targetUserId = local.id;
        }
      }

      final userService = UserService();
      final score = widget.attempt.finalScore;
      int pointsToAward = 0;

      if (score >= 90) {
        pointsToAward = widget.quiz.points;
      } else if (score >= 70) {
        pointsToAward = (widget.quiz.points * 0.8).round();
      } else if (score >= 50) {
        pointsToAward = (widget.quiz.points * 0.5).round();
      }

      if (pointsToAward > 0) {
        await userService.addUserPoints(targetUserId, pointsToAward);
        await userService.addUserAction(targetUserId);
        if (mounted) {
          setState(() {
            _pointsAwarded = true;
          });
        }
      }
    } catch (e) {
      print('Error awarding points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.attempt.finalScore;
    final totalQuestions = widget.quiz.questions.length;
    final correctAnswers = widget.attempt.correctAnswers;
    final isPassed = score >= 50;

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.solidBlack, width: 2.0),
          ),
          child: Text(
            'QUIZ SCORECARD',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.solidBlack,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Score Banner Card
            NeoCard(
              color: isPassed ? AppColors.electricMint : AppColors.dustyCoral,
              radius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    isPassed ? '🎉 QUIZ COMPLETED!' : 'KEEP PRACTICING!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$score%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Text(
                    '$correctAnswers out of $totalQuestions Correct',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.solidBlack, width: 1.5),
                    ),
                    child: Text(
                      isPassed
                          ? '+$score Karma Coins Credited!'
                          : 'Scored below 50% threshold. Retake to earn full coins.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'QUESTION BREAKDOWN & EXPLANATIONS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Questions list with explanations
            ...widget.quiz.questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final question = entry.value;

              final userResult = widget.attempt.questionResults.firstWhere(
                (r) => r.questionId == question.id,
                orElse: () => QuestionResult(
                  questionId: question.id,
                  selectedAnswerId: '',
                  isCorrect: false,
                  timeSpent: 0,
                  answeredAt: DateTime.now(),
                ),
              );

              final isCorrect = userResult.isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeoCard(
                  color: AppColors.cardWhite,
                  radius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCorrect ? AppColors.electricMint : AppColors.dustyCoral,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solidBlack, width: 1.2),
                            ),
                            child: Text(
                              isCorrect ? 'CORRECT ✓' : 'INCORRECT ✗',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Q${idx + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.question,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      if (question.explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.paperCream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.solidBlack, width: 1.0),
                          ),
                          child: Text(
                            '💡 ${question.explanation}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.solidBlack.withValues(alpha: 0.8),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 14),

            NeoButton(
              text: 'Back to YuvaSense',
              color: AppColors.butterYellow,
              textColor: AppColors.solidBlack,
              height: 52,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
