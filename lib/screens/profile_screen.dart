import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../services/quiz_service.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import '../services/user_service.dart';
import '../utils/transitions.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'karma_canteen_screen.dart';
import 'green_passport_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _userActions = [];
  bool _isLoading = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _currentUser = widget.user;
    _loadUserData();
    _loadUserActions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userService = UserService();
      final freshUser = await userService.getUserById(widget.user.id);
      if (freshUser != null && mounted) {
        setState(() {
          _currentUser = freshUser;
        });
      }
    } catch (e) {
      // Non-critical profile load error
    }
  }

  Future<void> _loadUserActions() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final results = await Future.wait([
        _loadUserActivities(),
        _loadUserQuizSubmissions(),
      ]);

      final activities = results[0] as List<Activity>;
      final quizSubmissions = results[1] as List<Map<String, dynamic>>;

      final allActions = <Map<String, dynamic>>[];

      for (final activity in activities) {
        allActions.add({
          'type': 'Campus Action',
          'title': activity.title,
          'points': activity.points,
          'date': activity.date,
          'icon': Icons.eco_rounded,
          'color': AppColors.sageGreen,
        });
      }

      for (final quiz in quizSubmissions) {
        allActions.add({
          'type': 'Climate Quiz',
          'title': quiz['title'],
          'points': quiz['points'],
          'date': quiz['date'],
          'icon': Icons.quiz_rounded,
          'color': AppColors.dustyCoral,
        });
      }

      allActions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _userActions = allActions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Activity>> _loadUserActivities() async {
    try {
      if (widget.user.joinedSchoolId != null) {
        final activities = await ActivityService().getActivities(widget.user.joinedSchoolId!);
        return activities.take(5).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadUserQuizSubmissions() async {
    try {
      final userProgress = await QuizService.getUserQuizProgress(widget.user.id);
      final quizSubmissions = <Map<String, dynamic>>[];

      for (final progress in userProgress) {
        final quiz = await QuizService.getQuizById(progress.quizId);
        if (quiz != null) {
          final score = (progress.correctAnswers / progress.totalQuestions * 100).round();
          int pointsEarned = 0;

          if (score >= 90) {
            pointsEarned = quiz.points;
          } else if (score >= 70) {
            pointsEarned = (quiz.points * 0.8).round();
          } else if (score >= 50) {
            pointsEarned = (quiz.points * 0.5).round();
          }

          quizSubmissions.add({
            'title': quiz.title,
            'points': pointsEarned,
            'date': progress.completedAt ?? DateTime.now(),
            'score': score,
          });
        }
      }

      return quizSubmissions;
    } catch (e) {
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                  mainScreenState?.onItemTapped(0);
                }
              },
            ),
          ),
        ),
        title: Text(
          'Your Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: () {
                  context.navigateWithSlideFromRight(SettingsScreen(user: widget.user));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.settings_outlined, color: AppColors.solidBlack, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: PaperGridBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadUserData();
            await _loadUserActions();
          },
          color: AppColors.solidBlack,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildUserInfo(),
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActionsTab(),
                    _buildStatsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = _currentUser ?? widget.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: NeoCard(
        color: AppColors.cardWhite,
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with 2.5px solid black border & edit badge
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      AppTransitions.cardTransition(EditProfileScreen(user: user)),
                    );
                    if (result == true) {
                      _loadUserData();
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.butterYellow,
                          border: Border.all(color: AppColors.solidBlack, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.solidBlack,
                              offset: Offset(2.5, 3.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: user.profilePic?.isNotEmpty == true
                            ? ClipOval(child: Image.network(user.profilePic!, fit: BoxFit.cover))
                            : const Icon(Icons.person, color: AppColors.solidBlack, size: 40),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.dustyCoral,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.solidBlack, width: 1.8),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solidBlack, width: 1.2),
                        ),
                        child: Text(
                          'Eco Campus Champion',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KarmaCanteenScreen()),
                      );
                      _loadUserData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.solidBlack, width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.solidBlack, size: 20),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.points}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Karma Coins',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.solidBlack.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.open_in_new_rounded, size: 10, color: AppColors.solidBlack),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.solidBlack, width: 1.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: AppColors.solidBlack, size: 20),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.streak > 0 ? user.streak : 5} Days',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.solidBlack,
                              ),
                            ),
                            Text(
                              'Streak',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.solidBlack.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dedicated Karma Canteen & Rewards Store entry banner
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KarmaCanteenScreen()),
                );
                _loadUserData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.paperCream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.solidBlack, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Karma Canteen & Perks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.dustyCoral,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.solidBlack, width: 1),
                                ),
                                child: Text(
                                  'Redeem',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Claim canteen drinks, cycle passes & sapling plaques',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.solidBlack.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.solidBlack, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dedicated Yuva GreenPassport Hero Banner
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GreenPassportScreen(user: user)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: const Icon(Icons.badge_rounded, color: AppColors.solidBlack, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Yuva GreenPassport™',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.sageGreen,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.solidBlack, width: 1),
                                ),
                                child: Text(
                                  'MRV LEDGER',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verifiable Digital Transcript & NAAC Criterion 7.1 Score',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.solidBlack.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.solidBlack, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.solidBlack, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.solidBlack, width: 2.0),
          ),
          labelColor: AppColors.solidBlack,
          unselectedLabelColor: AppColors.solidBlack.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Actions History'),
            Tab(text: 'Impact Stats'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.solidBlack),
        ),
      );
    }

    if (_userActions.isEmpty) {
      return Center(
        child: NeoCard(
          radius: 18,
          padding: const EdgeInsets.all(24),
          color: AppColors.cardWhite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded, size: 48, color: AppColors.solidBlack),
              const SizedBox(height: 12),
              Text(
                'No Actions Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete activities and quizzes to build your sustainability log.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      itemCount: _userActions.length,
      itemBuilder: (context, index) {
        final action = _userActions[index];
        final date = action['date'] as DateTime;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeoCard(
            radius: 18,
            color: AppColors.cardWhite,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.solidBlack, width: 1.8),
                  ),
                  child: Icon(action['icon'] as IconData, color: AppColors.solidBlack, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paperCream,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solidBlack, width: 1.0),
                            ),
                            child: Text(
                              action['type'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(date),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.butterYellow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solidBlack, width: 1.2),
                            ),
                            child: Text(
                              '+${action['points']} Karma Coins',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    final user = _currentUser ?? widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Karma Hero Card
          NeoCard(
            color: AppColors.butterYellow,
            radius: 20,
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL KARMA COINS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.points}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: AppColors.solidBlack, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Weekly Progress in Sage Green
          NeoCard(
            color: AppColors.sageGreen,
            radius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Target',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    Text(
                      '${user.weekPoints}/${user.weekGoal > 0 ? user.weekGoal : 500} pts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.solidBlack, width: 1.5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: user.weekGoal > 0 ? (user.weekPoints / user.weekGoal).clamp(0.05, 1.0) : 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.dustyCoral,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Impact highlights
          Row(
            children: [
              Expanded(
                child: NeoCard(
                  color: AppColors.cardWhite,
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.solidBlack, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        '${user.actions}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      Text(
                        'Actions Taken',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoCard(
                  color: AppColors.cardWhite,
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.solidBlack, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        '${user.streak > 0 ? user.streak : 5}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      Text(
                        'Streak Days',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
