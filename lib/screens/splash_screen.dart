import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkCurrentUser();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _logoController.forward();
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
  }

  _checkCurrentUser() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (!mounted) return;

      if (user != null) {
        try {
          await UserService().ensureDummyUsersExist().timeout(const Duration(seconds: 2), onTimeout: () {});
        } catch (e) {
          print('⚠️ Warning: Could not create dummy users: $e');
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Check if a real saved local user session exists
        final localUser = await UserService().getLocalUser(createIfNull: false);
        if (!mounted) return;
        if (localUser != null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      print('⚠️ FirebaseAuth unavailable or timed out: $e');
      if (mounted) {
        final localUser = await UserService().getLocalUser(createIfNull: false);
        if (!mounted) return;
        if (localUser != null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.electricMint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.solidBlack, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: const Offset(5, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Image.asset(
                  AppConstants.appLogoPath,
                  height: 110,
                  errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded, size: 80, color: AppColors.solidBlack),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textFade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'Green Yuva',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _textFade,
              child: Text(
                AppConstants.appTagline,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.solidBlack.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}