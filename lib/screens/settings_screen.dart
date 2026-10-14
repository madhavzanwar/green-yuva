import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/language_service.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';
import 'support_screen.dart';
import 'contact_screen.dart';
import 'auth_screen.dart';
import 'verification_history_screen.dart';
import 'admin_access_screen.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import 'main_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser user;

  const SettingsScreen({
    super.key,
    required this.user,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English(US)';
  final NotificationService _notificationService = NotificationService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final notificationsEnabled = await _notificationService.isNotificationsEnabled();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _selectedLanguage = _languageService.currentLanguageName;
      });
    } catch (e) {
      // Non-critical settings load error
    }
  }

  @override
  void dispose() {
    _newsletterEmailController.dispose();
    super.dispose();
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
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('ACCOUNT'),
              const SizedBox(height: 8),
              NeoCard(
                color: AppColors.cardWhite,
                radius: 18,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.person_rounded,
                      iconBg: AppColors.butterYellow,
                      title: 'Edit Profile',
                      subtitle: 'Change name, photo, and school affiliation',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('PREFERENCES & SECURITY'),
              const SizedBox(height: 8),
              NeoCard(
                color: AppColors.cardWhite,
                radius: 18,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleItem(
                      icon: Icons.notifications_rounded,
                      iconBg: AppColors.sageGreen,
                      title: 'Notifications',
                      subtitle: 'Receive alerts about local swaps and hubs',
                      value: _notificationsEnabled,
                      onChanged: (value) => _toggleNotifications(value),
                    ),
                    const Divider(height: 1, thickness: 1.5, color: AppColors.solidBlack),
                    _buildSettingItem(
                      icon: Icons.lock_rounded,
                      iconBg: AppColors.dustyCoral,
                      title: 'Privacy & Permissions',
                      subtitle: 'Data usage and location sharing preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, thickness: 1.5, color: AppColors.solidBlack),
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      iconBg: AppColors.butterYellow,
                      title: 'Language',
                      subtitle: _selectedLanguage,
                      onTap: () => _showLanguageDialog(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('COMMUNITY & VERIFICATION'),
              const SizedBox(height: 8),
              NeoCard(
                color: AppColors.cardWhite,
                radius: 18,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.verified_user_rounded,
                      iconBg: AppColors.sageGreen,
                      title: 'Verification History',
                      subtitle: 'Track campus action proofs and review logs',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationHistoryScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, thickness: 1.5, color: AppColors.solidBlack),
                    _buildSettingItem(
                      icon: Icons.admin_panel_settings_rounded,
                      iconBg: AppColors.dustyCoral,
                      title: 'Admin Access',
                      subtitle: 'Review student action proofs (Admins only)',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminAccessScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('SUPPORT & FEEDBACK'),
              const SizedBox(height: 8),
              NeoCard(
                color: AppColors.cardWhite,
                radius: 18,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.favorite_rounded,
                      iconBg: AppColors.butterYellow,
                      title: 'Support Us',
                      subtitle: 'Learn how to contribute to open climate initiatives',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SupportScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, thickness: 1.5, color: AppColors.solidBlack),
                    _buildSettingItem(
                      icon: Icons.support_agent_rounded,
                      iconBg: AppColors.sageGreen,
                      title: 'Contact Us',
                      subtitle: 'Get help or submit campus partnership requests',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('NEWSLETTER & COMMUNITY DIGEST'),
              const SizedBox(height: 8),
              _buildNewsletterCard(),
              const SizedBox(height: 32),

              // Logout Button in NeoButton style
              NeoButton(
                text: 'Log Out of Green Yuva',
                leading: const Icon(Icons.logout_rounded, color: AppColors.solidBlack, size: 20),
                color: AppColors.dustyCoral,
                textColor: AppColors.solidBlack,
                height: 52,
                onPressed: _handleLogout,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.solidBlack,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
        ),
        child: Icon(icon, color: AppColors.solidBlack, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.solidBlack,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.solidBlack, size: 22),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
        ),
        child: Icon(icon, color: AppColors.solidBlack, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.solidBlack,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.butterYellow,
        activeTrackColor: AppColors.solidBlack,
        inactiveThumbColor: AppColors.cardWhite,
        inactiveTrackColor: Colors.grey[300],
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      if (value) {
        await _notificationService.enableNotifications();
      } else {
        await _notificationService.disableNotifications();
      }
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = value;
      });
    } catch (e) {
      // Notification error handled
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paperCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
        title: Text(
          'Select Language'.tr,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.solidBlack),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Hindi (हिंदी)'].map((lang) {
            final isSelected = _selectedLanguage.contains('Hindi')
                ? lang.contains('Hindi')
                : (!lang.contains('Hindi'));
            return ListTile(
              title: Text(
                lang,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.solidBlack,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.leafGreen)
                  : null,
              onTap: () async {
                await _languageService.setLanguage(lang);
                if (!mounted) return;
                setState(() => _selectedLanguage = _languageService.currentLanguageName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.solidBlack,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.butterYellow, width: 2.0),
                    ),
                    content: Text(
                      _languageService.isHindi
                          ? 'भाषा बदलकर हिंदी कर दी गई है 🇮🇳'
                          : 'Language switched to English 🌿',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paperCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
        title: Text(
          'Log Out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.solidBlack),
        ),
        content: Text(
          'Are you sure you want to log out of Green Yuva?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey[800]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.solidBlack),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dustyCoral,
              foregroundColor: AppColors.solidBlack,
              elevation: 0,
              side: const BorderSide(color: AppColors.solidBlack, width: 1.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await UserService().clearLocalUser();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      } catch (e) {
        try {
          await UserService().clearLocalUser();
        } catch (_) {}
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  bool _isSubscribedToNewsletter = false;
  final TextEditingController _newsletterEmailController = TextEditingController();

  Widget _buildNewsletterCard() {
    return NeoCard(
      color: AppColors.butterYellow,
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: AppColors.solidBlack, size: 24),
              const SizedBox(width: 10),
              Text(
                'Climate Youth Digest 📰',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Weekly highlights on student eco-innovations, campus leaderboards, and green breakthroughs.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          if (_isSubscribedToNewsletter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.electricMint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.solidBlack, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Subscribed to Green Yuva Digest 🌿',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newsletterEmailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.solidBlack, width: 1.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.solidBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: () {
                    final email = _newsletterEmailController.text.trim();
                    if (email.contains('@')) {
                      setState(() => _isSubscribedToNewsletter = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.solidBlack,
                          content: Text('Subscribed $email to Green Yuva Digest! 📩'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Subscribe',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
