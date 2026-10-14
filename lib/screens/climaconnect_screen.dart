import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/school.dart';
import '../models/user.dart';
import '../services/school_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'community_screen.dart';
import '../widgets/school_card.dart';
import 'main_screen.dart';

class ClimaConnectScreen extends StatefulWidget {
  final AppUser user;

  const ClimaConnectScreen({super.key, required this.user});

  @override
  State<ClimaConnectScreen> createState() => _ClimaConnectScreenState();
}

class _ClimaConnectScreenState extends State<ClimaConnectScreen>
    with WidgetsBindingObserver {
  final SchoolService _schoolService = SchoolService();
  final UserService _userService = UserService();

  List<School> _schools = [];
  bool _isLoading = true;
  String? _joinedSchoolId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _joinedSchoolId = widget.user.joinedSchoolId;
    _fetchSchools();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshUserData();
  }

  @override
  void didUpdateWidget(ClimaConnectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.joinedSchoolId != widget.user.joinedSchoolId) {
      setState(() {
        _joinedSchoolId = widget.user.joinedSchoolId;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final schools = await _schoolService.getSchools();
      if (mounted) {
        setState(() {
          _schools = schools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinSchool(String schoolId) async {
    try {
      await _userService.joinSchool(widget.user.id, schoolId);
      if (!mounted) return;
      setState(() {
        _joinedSchoolId = schoolId;
      });

      final matches = _schools.where((s) => s.id == schoolId);
      final schoolName = matches.isNotEmpty ? matches.first.name : 'school';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.solidBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.butterYellow, width: 2.0),
            ),
            content: Text(
              'Joined $schoolName!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.solidBlack,
            content: Text('Failed to join school: $e'),
          ),
        );
      }
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final updatedUser = await _userService.getUserById(widget.user.id);
      if (updatedUser != null && mounted) {
        setState(() {
          _joinedSchoolId = updatedUser.joinedSchoolId;
        });
      }
    } catch (e) {
      // User data refresh error handled
    }
  }

  void _navigateHome() {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreenState != null) {
      mainScreenState.onItemTapped(0);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_joinedSchoolId != null && _joinedSchoolId!.isNotEmpty) {
      return CommunityScreen(
        user: widget.user,
        schoolId: _joinedSchoolId!,
        onSchoolLeft: () {
          setState(() {
            _joinedSchoolId = null;
            _isLoading = false;
          });
          _refreshUserData();
        },
      );
    }

    final filteredSchools = _schools.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: _navigateHome,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.sageGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: const Icon(Icons.forum_rounded, color: AppColors.solidBlack, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'YuvaVibe',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 50)],
      ),
      body: PaperGridBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.solidBlack))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                children: [
                  // Hero Header Banner
                  NeoCard(
                    color: AppColors.cardWhite,
                    radius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.butterYellow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.solidBlack, width: 1.5),
                              ),
                              child: Text(
                                'CAMPUS COMMUNITY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Join Your College Hub',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.solidBlack,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Connect with student eco-warriors across Pune campuses to share ideas, organize green drives, and collaborate.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Filter Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: AppColors.solidBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search campus hubs (PCCOE, IIT Bombay, COEP...)',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.solidBlack, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.solidBlack),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PUNE ENGINEERING COLLEGES (${filteredSchools.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (filteredSchools.isEmpty)
                    NeoCard(
                      radius: 18,
                      color: AppColors.cardWhite,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No colleges found matching "$_searchQuery"',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredSchools.map((school) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SchoolCard(
                          school: school,
                          joined: school.id == _joinedSchoolId,
                          onJoin: () => _joinSchool(school.id),
                        ),
                      );
                    }).toList(),
                ],
              ),
      ),
    );
  }
}
