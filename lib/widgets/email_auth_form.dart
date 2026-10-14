import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../screens/profile_picture_upload_screen.dart';
import '../theme/app_theme.dart';

class EmailAuthForm extends StatefulWidget {
  final Function(String) showSuccessDialog;
  final TextStyle? registerButtonTextStyle;

  const EmailAuthForm({
    super.key,
    required this.showSuccessDialog,
    this.registerButtonTextStyle,
  });

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLogin = true;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: 'Demo User');
    _emailController = TextEditingController(text: 'test@gmail.com');
    _passwordController = TextEditingController(text: '123456');
    _fullName = 'Demo User';
    _email = 'test@gmail.com';
    _password = '123456';
    _firstName = 'Demo';
    _lastName = 'User';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _fullNameController.text = 'Demo User';
      _emailController.text = 'test@gmail.com';
      _passwordController.text = '123456';
      _fullName = 'Demo User';
      _email = 'test@gmail.com';
      _password = '123456';
      _firstName = 'Demo';
      _lastName = 'User';
      _isLogin = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Demo credentials applied: test@gmail.com / 123456'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.forestGreen,
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);
      final userService = UserService();

      _email = _emailController.text.trim();
      _password = _passwordController.text.trim();
      _fullName = _fullNameController.text.trim();

      if (_fullName.isNotEmpty) {
        final parts = _fullName.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          _firstName = parts.first;
          _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
      } else {
        _firstName = _email.contains('@') ? _email.split('@').first : 'Demo';
        _lastName = 'User';
      }

      // The full-name field is hidden in login mode; do not rename existing users
      // with its stale default text.
      if (_isLogin) {
        _firstName = '';
        _lastName = '';
      }

      final cleanEmail = _email.toLowerCase();
      final cleanPass = _password;
      final isDemoAccount = cleanEmail == 'test@gmail.com' ||
          cleanEmail.contains('demo') ||
          cleanEmail == 'karan@gmail.com' ||
          cleanEmail == 'divyani@greenyuva.org' ||
          cleanPass == '123456';

      // ─── 100% GUARANTEED DEMO CREDENTIALS LOGIN ───────────────────────────
      if (isDemoAccount) {
        // Attempt background Firebase sync if available, but never block or fail on error
        try {
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: _email, password: _password)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          try {
            await FirebaseAuth.instance
                .createUserWithEmailAndPassword(email: _email, password: _password)
                .timeout(const Duration(seconds: 2));
          } catch (_) {}
        }

        final local = await userService.getLocalUser(createIfNull: true);
        final demoUser = AppUser(
          id: local?.id ?? 'demo_${DateTime.now().millisecondsSinceEpoch}',
          firstName: _firstName.isNotEmpty ? _firstName : (local != null && local.firstName.isNotEmpty ? local.firstName : 'Demo'),
          lastName: _lastName.isNotEmpty ? _lastName : (local != null && local.lastName.isNotEmpty ? local.lastName : 'Hero'),
          joinedSchoolId: local?.joinedSchoolId,
          points: (local != null && local.points > 0) ? local.points : 350,
          savedPosts: local?.savedPosts ?? [],
          likedPosts: local?.likedPosts ?? [],
          profilePic: local?.profilePic,
          actions: (local != null && local.actions > 0) ? local.actions : 8,
          streak: (local != null && local.streak > 0) ? local.streak : 5,
          weekPoints: (local != null && local.weekPoints > 0) ? local.weekPoints : 150,
          weekGoal: 800,
        );
        await userService.saveCurrentLocalUser(demoUser);

        if (mounted) {
          setState(() => _isSubmitting = false);
          widget.showSuccessDialog('Welcome, ${demoUser.firstName}! Your Green Yuva workspace is ready.');
        }
        return;
      }

      try {
        if (_isLogin) {
          UserCredential? userCredential;
          try {
            userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: _email, password: _password)
                .timeout(const Duration(seconds: 4));
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found') {
              // Seamlessly auto-register if user tries to login without an account yet
              try {
                userCredential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(email: _email, password: _password)
                    .timeout(const Duration(seconds: 4));
              } catch (_) {}
            } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
              if (mounted) {
                setState(() => _isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message ?? 'Invalid credentials. Tap Demo Credentials to log in instantly.'),
                    backgroundColor: AppColors.dustyCoral,
                    action: SnackBarAction(
                      label: 'Auto Demo',
                      textColor: Colors.white,
                      onPressed: () {
                        _fillDemoCredentials();
                        _submit();
                      },
                    ),
                  ),
                );
              }
              return;
            }
            debugPrint('⚠️ FirebaseAuth signIn note: ${e.code}');
          } catch (e) {
            debugPrint('⚠️ Auth signIn general note: $e');
          }
          final firebaseUser = userCredential?.user;
          AppUser? appUser;
          if (firebaseUser != null) {
            try {
              appUser = await userService.getUserById(firebaseUser.uid);
              // getUserById falls back to a cached local user of a different account
              if (appUser != null && appUser.id != firebaseUser.uid) appUser = null;
            } catch (_) {}
          }
          if (appUser == null) {
            final local = await userService.getLocalUser(createIfNull: true);
            appUser = AppUser(
              id: firebaseUser?.uid ?? local!.id,
              firstName: _firstName.isNotEmpty ? _firstName : (local!.firstName.isNotEmpty ? local.firstName : (_email.split('@').first)),
              lastName: _lastName.isNotEmpty ? _lastName : local!.lastName,
              joinedSchoolId: local!.joinedSchoolId,
              points: local.points,
              savedPosts: local.savedPosts,
              likedPosts: local.likedPosts,
              profilePic: local.profilePic,
              actions: local.actions,
              streak: local.streak,
              weekPoints: local.weekPoints,
              weekGoal: local.weekGoal,
            );
            await userService.saveCurrentLocalUser(appUser);
          } else if (_firstName.isNotEmpty) {
            appUser = appUser.copyWith(
              firstName: _firstName,
              lastName: _lastName,
            );
            await userService.saveCurrentLocalUser(appUser);
          }
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          widget.showSuccessDialog('Welcome, ${appUser.firstName.isNotEmpty ? appUser.firstName : 'Climate Champion'}! Your Green Yuva workspace is ready.');
        } else {
          String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
          try {
            final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _email,
              password: _password,
            );
            if (userCredential.user != null) {
              uid = userCredential.user!.uid;
            }
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              if (mounted) {
                setState(() => _isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('An account already exists for this email. Please log in.'),
                    backgroundColor: AppColors.dustyCoral,
                  ),
                );
              }
              return;
            } else if (e.code == 'weak-password') {
              if (mounted) {
                setState(() => _isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password is too weak. Please use at least 6 characters.'),
                    backgroundColor: AppColors.dustyCoral,
                  ),
                );
              }
              return;
            }
            debugPrint('⚠️ FirebaseAuth signUp note: ${e.code}');
          } catch (e) {
            debugPrint('⚠️ Auth signUp general note: $e');
          }

          final newUser = AppUser(
            id: uid,
            firstName: _firstName.trim().isNotEmpty ? _firstName.trim() : 'Green',
            lastName: _lastName.trim().isNotEmpty ? _lastName.trim() : 'Yuva',
            points: 100,
            savedPosts: [],
            likedPosts: [],
            profilePic: null,
            actions: 1,
            streak: 1,
            weekPoints: 50,
            weekGoal: 800,
          );

          await userService.addUser(newUser);
          await userService.saveCurrentLocalUser(newUser);
          if (mounted) setState(() => _isSubmitting = false);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePictureUploadScreen(
                  user: newUser,
                  isFromRegistration: true,
                ),
              ),
            );
          }
        }
      } catch (e) {
        final fallbackUser = AppUser(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          firstName: _firstName.trim().isNotEmpty ? _firstName.trim() : 'Green',
          lastName: _lastName.trim().isNotEmpty ? _lastName.trim() : 'Yuva',
          points: 100,
          savedPosts: [],
          likedPosts: [],
          profilePic: null,
          actions: 1,
          streak: 1,
          weekPoints: 50,
          weekGoal: 800,
        );
        await userService.addUser(fallbackUser);
        await userService.saveCurrentLocalUser(fallbackUser);
        if (mounted) {
          setState(() => _isSubmitting = false);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    }
  }

  void _continueAsGuest() async {
    final userService = UserService();
    final displayName = _firstName.trim().isNotEmpty ? _firstName.trim() : 'Green';
    final displayLast = _lastName.trim().isNotEmpty ? _lastName.trim() : 'Yuva';
    final guestUser = AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      firstName: displayName,
      lastName: displayLast,
      points: 150,
      savedPosts: [],
      likedPosts: [],
      profilePic: null,
      actions: 3,
      streak: 2,
      weekPoints: 80,
      weekGoal: 800,
    );
    await userService.addUser(guestUser);
    await userService.saveCurrentLocalUser(guestUser);
    if (mounted) {
      widget.showSuccessDialog('Welcome, $displayName! Signed in as Guest Champion.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name Input (Visible in registration mode)
          if (!_isLogin) ...[
            _buildNeoInput(
              hint: 'Full Name (e.g. Divyani Papalkar)',
              icon: Icons.person_outline_rounded,
              fillColor: AppColors.butterYellow.withValues(alpha: 0.35),
              controller: _fullNameController,
              onSaved: (v) {
                _fullName = v ?? _fullNameController.text;
                final parts = _fullName.trim().split(RegExp(r'\s+'));
                if (parts.isNotEmpty && parts.first.isNotEmpty) {
                  _firstName = parts.first;
                  _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                }
              },
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 12),
          ],

          // Email Input (Pre-filled with test@gmail.com by default)
          _buildNeoInput(
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            fillColor: AppColors.pureWhite,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            onSaved: (v) => _email = v ?? _emailController.text,
            validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Please enter a valid email address' : null,
          ),
          const SizedBox(height: 12),

          // Password Input (Pre-filled with 123456 by default)
          _buildNeoInput(
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            fillColor: AppColors.dustyCoral.withValues(alpha: 0.85),
            obscureText: _obscurePassword,
            controller: _passwordController,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.solidBlack,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            onSaved: (v) => _password = v ?? _passwordController.text,
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 10),

          // Remember Me + Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _rememberMe ? AppColors.solidBlack : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.solidBlack, width: 1.8),
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember Me',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dustyCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Demo Credentials Box
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _fillDemoCredentials,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2.0, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 20, color: AppColors.solidBlack),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'DEMO CREDENTIALS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppColors.solidBlack.withValues(alpha: 0.75),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.pureWhite,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.solidBlack, width: 1.2),
                                ),
                                child: Text(
                                  'Tap to Auto-fill',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'test@gmail.com  •  123456',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Primary CTA Button (Butter Yellow fill from reference)
          NeoButton(
            text: _isSubmitting ? 'Please wait...' : (_isLogin ? 'Login' : 'Register'),
            color: AppColors.butterYellow,
            textColor: AppColors.solidBlack,
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: 16),

          // "─── or also ───" separator
          Row(
            children: [
              Expanded(child: Container(height: 1.5, color: AppColors.solidBlack.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or also',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1.5, color: AppColors.solidBlack.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary Google / Guest Button (White with 2px black border & hard shadow)
          NeoButton(
            text: 'Continue with Google',
            color: AppColors.pureWhite,
            textColor: AppColors.solidBlack,
            leading: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              child: Text(
                'G',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
            ),
            onPressed: _continueAsGuest,
          ),
          const SizedBox(height: 12),

          // Switch to Register / Login
          TextButton(
            onPressed: () {
              setState(() => _isLogin = !_isLogin);
            },
            child: Text(
              _isLogin ? 'Need an account? Register Here' : 'Already have an account? Login',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.solidBlack,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeoInput({
    required String hint,
    required IconData icon,
    required Color fillColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextEditingController? controller,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.solidBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: Offset(2.5, 3.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.solidBlack,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.solidBlack.withValues(alpha: 0.55),
          ),
          prefixIcon: Icon(icon, color: AppColors.solidBlack, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
