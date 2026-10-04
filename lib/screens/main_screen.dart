import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'climaconnect_screen.dart';
import 'leaderboard_screen.dart';
import 'climasights_screen.dart';
import 'climagame_screen.dart';
import 'yuvaswap_screen.dart';
import 'create_swap_item_screen.dart';
import 'ai_chat_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  AppUser? _appUser;
  bool _loadingUser = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadUser();

    // Safety watchdog: Guarantee loading screen dismisses in max 1.5 seconds under all conditions
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _loadingUser) {
        setState(() {
          _appUser ??= AppUser(
            id: 'green_yuva_hero',
            firstName: 'Climate',
            lastName: 'Hero',
            points: 120,
            savedPosts: [],
            likedPosts: [],
            actions: 3,
            streak: 1,
            weekPoints: 60,
            weekGoal: 800,
          );
          _loadingUser = false;
        });
      }
    });
  }

  Future<void> _loadUser() async {
    AppUser? user;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        user = await UserService().getUserById(firebaseUser.uid).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (e) {
        print('Error loading user from Firebase: $e');
      }
    }
    if (user == null) {
      try {
        user = await UserService().getLocalUser().timeout(
          const Duration(seconds: 1),
          onTimeout: () => null,
        );
      } catch (e) {
        print('Error loading local user: $e');
      }
    }
    if (user == null) {
      user = AppUser(
        id: firebaseUser?.uid ?? 'green_yuva_hero',
        firstName: firebaseUser?.displayName?.split(' ').first ?? 'Climate',
        lastName: firebaseUser?.displayName?.split(' ').skip(1).join(' ') ?? 'Hero',
        points: 120,
        savedPosts: [],
        likedPosts: [],
        actions: 3,
        streak: 1,
        weekPoints: 60,
        weekGoal: 800,
      );
    }
    if (mounted) {
      setState(() {
        _appUser = user;
        _loadingUser = false;
      });
    }
  }

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = index;
        });
        _animationController.forward();

        if (index == 1) {
          _loadUser();
        }
      });
    }
  }

  void _onItemTapped(int index) => onItemTapped(index);

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return Scaffold(
        body: EcoBackground(
          child: Center(
            child: GlassCard(
              radius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulseWidget(
                    child: Icon(Icons.eco_rounded, size: 56, color: AppColors.leafGreen),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Green Yuva',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Loading your sustainability space...',
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.leafGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _appUser ??= AppUser(
                            id: 'green_yuva_hero',
                            firstName: 'Climate',
                            lastName: 'Hero',
                            points: 120,
                            savedPosts: const [],
                            likedPosts: const [],
                            actions: 3,
                            streak: 1,
                            weekPoints: 60,
                            weekGoal: 800,
                          );
                          _loadingUser = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.forestGreen),
                    label: Text(
                      'Enter Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_animationController.isAnimating && _animationController.value == 0.0) {
      _animationController.forward();
    }

    return Scaffold(
      extendBody: true, // Allows content to show gracefully behind floating glass nav
      body: EcoBackground(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _getScreen(_selectedIndex),
        ),
      ),
      bottomNavigationBar: _buildFloatingGlassNavBar(),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return HomeScreen(user: _appUser!);
      case 1:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return ClimaConnectScreen(user: _appUser!);
      case 2:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return LeaderboardScreen(user: _appUser!);
      case 3:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return ClimaGameScreen(user: _appUser!);
      case 4:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return ClimaSightsScreen(user: _appUser!);
      case 5:
        return const YuvaSwapScreen();
      case 6:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return AIChatScreen(user: _appUser!);
      default:
        if (_appUser == null) return const Center(child: Text('User not found'));
        return HomeScreen(user: _appUser!);
    }
  }

  /// Neo-Brutalist Bottom Navigation Bar (white pill, 2px solid black border, 0-blur hard shadow, horizontal sliding support)
  Widget _buildFloatingGlassNavBar() {
    return SafeArea(
      child: Center(
        heightFactor: 1.0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: NeoCard(
            radius: 26,
            color: AppColors.pureWhite,
            borderWidth: 2.0,
            shadowOffset: const Offset(0, 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(0, 'assets/icons/home_active.svg', 'assets/icons/home_inactive.svg', 'Home'.tr),
                  const SizedBox(width: 4),
                  _buildNavItem(1, 'assets/icons/climaconnect_active.svg', 'assets/icons/climaconnect_inactive.svg', 'YuvaVibe'.tr),
                  const SizedBox(width: 4),
                  _buildIconNavItem(5, Icons.recycling_rounded, 'YuvaSwap'.tr),
                  const SizedBox(width: 6),
                  _buildCenterActionFab(),
                  const SizedBox(width: 6),
                  _buildNavItem(3, 'assets/icons/climagame_active.svg', 'assets/icons/climagame_inactive.svg', 'GreenRush'.tr),
                  const SizedBox(width: 4),
                  _buildNavItem(4, 'assets/icons/climasights_active.svg', 'assets/icons/climasights_inactive.svg', 'YuvaSense'.tr),
                  const SizedBox(width: 4),
                  _buildIconNavItem(6, Icons.smart_toy_outlined, 'YuvaSathi'.tr),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Coral Action Button with 2px solid black border and hard offset shadow (matching reference "+")
  Widget _buildCenterActionFab() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSwapItemScreen()),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.dustyCoral,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.solidBlack, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2.0, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String activeIcon, String inactiveIcon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 7,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.butterYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.solidBlack, width: 1.8)
              : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(1.5, 2.0),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isSelected ? activeIcon : inactiveIcon,
              width: 20,
              height: 20,
              colorFilter: isSelected
                  ? const ColorFilter.mode(AppColors.solidBlack, BlendMode.srcIn)
                  : ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.solidBlack : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 7,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.butterYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.solidBlack, width: 1.8)
              : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(1.5, 2.0),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.solidBlack : Colors.grey[600],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.solidBlack : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}