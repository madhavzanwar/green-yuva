import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user.dart';
import '../models/activity.dart';
import '../models/quiz.dart';
import '../models/ecore.dart';
import '../models/school.dart';
import '../services/activity_service.dart';
import '../services/location_service.dart';
import '../services/quiz_service.dart';
import '../services/climagame_service.dart';
import '../services/school_service.dart';

import 'profile_screen.dart';
import 'main_screen.dart';
import 'quiz_detail_screen.dart';
import 'activity_detail_screen.dart';
import 'climaconnect_screen.dart';
import 'notifications_screen.dart';

import '../utils/transitions.dart';
import '../theme/app_theme.dart';
import 'yuvaswap_screen.dart';
import '../widgets/green_rush_radar_map.dart';
import '../services/language_service.dart';
import 'karma_canteen_screen.dart';
import 'green_passport_screen.dart';
import 'green_commute_screen.dart';
import '../services/green_commute_service.dart';
import '../services/aqi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
  });

  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Activity? _latestActivity;
  Quiz? _latestQuiz;
  List<Ecore> _visibleEcores = [];
  Map<String, dynamic> _gameStats = {};
  Position? _currentPosition;
  bool _mapInitialized = false;
  Set<Marker> _cachedMarkers = {};

  bool get isMapInitialized => _mapInitialized;
  Set<Marker> get cachedMarkers => _cachedMarkers;

  final SchoolService _schoolService = SchoolService();
  School? _userSchool;
  final AqiService _aqiService = AqiService();
  CityAqiData? _cityAqi;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _currentPosition = LocationService.getDefaultPosition();
    _mapInitialized = true;
    _visibleEcores = ClimaGameService.getDefaultCampusEcores();
    _gameStats = {
      'conqueredEcores': 2,
      'inProgressEcores': 3,
      'totalEcores': 5,
    };
    _generateMarkers();

    _loadData();
    _loadAqi();
    _getCurrentLocation();
    _loadUserSchool();
    GreenCommuteService().init();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadAqi();
    try {
      final results = await Future.wait([
        _loadLatestActivity(),
        _loadLatestQuiz(),
        _loadGameData(),
      ]);

      if (mounted) {
        setState(() {
          _latestActivity = results[0] as Activity?;
          _latestQuiz = results[1] as Quiz?;
          _visibleEcores = results[2] as List<Ecore>;
        });
        _generateMarkers();
      }
    } catch (e) {
      // Non-critical data loading error
    }
  }

  Future<void> _loadAqi() async {
    final cityName = await _aqiService.getSelectedCity();
    final aqiData = await _aqiService.fetchCityAqi(cityName);
    if (mounted) {
      setState(() {
        _cityAqi = aqiData;
      });
    }
  }

  void _showCitySwitchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paperCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.solidBlack, width: 2.0),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.solidBlack.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.butterYellow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        ),
                        child: const Icon(Icons.location_city_rounded, color: AppColors.solidBlack, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Select Student Hub',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...AqiService.supportedCities.map((city) {
                    final isCurrent = (_cityAqi?.cityName.toLowerCase() == city.name.toLowerCase());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NeoCard(
                        color: isCurrent ? AppColors.butterYellow : AppColors.cardWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _aqiService.setSelectedCity(city.name);
                          _loadAqi();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                                Text(
                                  city.state,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.solidBlack,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Active Hub',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppColors.solidBlack),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Activity?> _loadLatestActivity() async {
    try {
      if (widget.user.joinedSchoolId != null) {
        final activities = await ActivityService().getActivities(widget.user.joinedSchoolId!);
        return activities.isNotEmpty ? activities.first : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Quiz?> _loadLatestQuiz() async {
    try {
      final quizzes = await QuizService.getQuizzes();
      return quizzes.isNotEmpty ? quizzes.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Ecore>> _loadGameData() async {
    try {
      final ecores = await ClimaGameService.getVisibleEcores();
      final conqueredCount = ecores.where((e) => e.isConquered).length;
      final inProgressCount = ecores.where((e) => !e.isConquered && !e.isInCoolingTime).length;

      if (mounted) {
        setState(() {
          _gameStats = {
            'conqueredEcores': conqueredCount,
            'inProgressEcores': inProgressCount,
            'totalEcores': ecores.length,
          };
        });
      }

      return ecores;
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadUserSchool() async {
    try {
      if (widget.user.joinedSchoolId != null) {
        final school = await _schoolService.getSchoolById(widget.user.joinedSchoolId!);
        if (mounted) {
          setState(() {
            _userSchool = school;
          });
        }
      }
    } catch (e) {
      // Ignored non-critical school load error
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.determinePosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _mapInitialized = true;
      });
      _generateMarkers();
    }
  }

  void _generateMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Your Campus Location',
            snippet: 'Active in Green Yuva',
          ),
        ),
      );
    }

    for (final ecore in _visibleEcores.take(5)) {
      markers.add(
        Marker(
          markerId: MarkerId('ecore_${ecore.id}'),
          position: LatLng(ecore.latitude, ecore.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            ecore.isConquered ? BitmapDescriptor.hueGreen : (ecore.isInCoolingTime ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed),
          ),
          infoWindow: InfoWindow(
            title: ecore.name,
            snippet: ecore.isConquered ? 'Conquered' : 'Active Core',
          ),
        ),
      );
    }

    final campuses = [
      {'name': 'IIT Delhi Action Hub', 'lat': 28.5450, 'lng': 77.1926, 'status': 'Active'},
      {'name': 'DTU Circular Core', 'lat': 28.7499, 'lng': 77.1170, 'status': 'Conquered'},
      {'name': 'IIT Bombay Green Hub', 'lat': 19.1334, 'lng': 72.9133, 'status': 'Active'},
      {'name': 'BITS Pilani Hub', 'lat': 15.3911, 'lng': 73.8782, 'status': 'Cooling'},
    ];

    for (int i = 0; i < campuses.length; i++) {
      final c = campuses[i];
      final isConquered = c['status'] == 'Conquered';
      final isCooling = c['status'] == 'Cooling';
      markers.add(
        Marker(
          markerId: MarkerId('hub_$i'),
          position: LatLng(c['lat'] as double, c['lng'] as double),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isConquered ? BitmapDescriptor.hueGreen : (isCooling ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed),
          ),
          infoWindow: InfoWindow(
            title: c['name'] as String,
            snippet: 'Status: ${c['status']}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _cachedMarkers = markers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.solidBlack,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 115),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopAppBar(),
                    const SizedBox(height: 18),
                    _buildGreetingHeader(),
                    const SizedBox(height: 18),
                    _buildStatCardsRow(),
                    const SizedBox(height: 16),
                    _buildWeeklyProgressCard(),
                    const SizedBox(height: 16),
                    _buildGreenCommuteBanner(),
                    const SizedBox(height: 16),
                    _buildGreenPassportBanner(),
                    const SizedBox(height: 16),
                    _buildKarmaCanteenBanner(),
                    const SizedBox(height: 22),
                    _buildFeatureShowcaseGrid(),
                    const SizedBox(height: 22),
                    _buildCoreMapSection(),
                    const SizedBox(height: 22),
                    _buildCommunityActivitySection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top App Bar matching reference (Avatar left, Hero Brand Logo center, Language Switcher + Bell right)
  Widget _buildTopAppBar() {
    final bool isHindi = LanguageService.instance.isHindi;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar circle with 2px solid black border
        GestureDetector(
          onTap: () {
            context.navigateWithSlideFromRight(ProfileScreen(user: widget.user));
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.butterYellow,
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.solidBlack,
                  offset: Offset(2.0, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: widget.user.profilePic?.isNotEmpty == true
                ? ClipOval(child: Image.network(widget.user.profilePic!, fit: BoxFit.cover))
                : const Icon(Icons.person, color: AppColors.solidBlack, size: 22),
          ),
        ),

        // Prominent Hero Brand Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.solidBlack, width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(2.0, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.solidBlack, size: 20),
              const SizedBox(width: 6),
              Text(
                'Green Yuva'.tr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // Right actions: Language Switcher and Notification Bell
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Language Switcher Button (EN | हिं)
            GestureDetector(
              onTap: () async {
                await LanguageService.instance.toggleLanguage();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.solidBlack,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.butterYellow, width: 2.0),
                    ),
                    content: Text(
                      LanguageService.instance.isHindi
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
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isHindi ? AppColors.butterYellow : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2.0, 2.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate_rounded, size: 15, color: AppColors.solidBlack),
                      const SizedBox(width: 3),
                      Text(
                        isHindi ? 'हिं' : 'EN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Right Notification Bell with 2px black border (Tapping opens NotificationsScreen)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
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
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.solidBlack, size: 20),
                onPressed: () async {
                  final targetIndex = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  if (targetIndex != null && mounted) {
                    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                    mainScreenState?.onItemTapped(targetIndex);
                  }
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Greeting "Hello, Edward." style from reference with localization
  Widget _buildGreetingHeader() {
    final bool isHindi = LanguageService.instance.isHindi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'नमस्ते, ${widget.user.displayName}!' : 'Hello, ${widget.user.displayName}.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(Icons.school_outlined, size: 14, color: AppColors.solidBlack),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                _userSchool?.name ?? 'Eco Campus Champion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.solidBlack.withValues(alpha: 0.75),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getCurrentDate(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Live CPCB / AQI City Indicator Neo-Brutalist Badge
        GestureDetector(
          onTap: _showCitySwitchSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _cityAqi?.badgeColor ?? AppColors.sageGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.solidBlack,
                  offset: Offset(2.5, 3.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.solidBlack, width: 1.5),
                  ),
                  child: Icon(
                    _cityAqi?.statusIcon ?? Icons.air_rounded,
                    color: AppColors.solidBlack,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_cityAqi?.cityName ?? "Pune"} AQI Index',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solidBlack,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solidBlack, width: 1.0),
                            ),
                            child: Text(
                              _cityAqi?.isLive == true ? 'CPCB LIVE' : 'CPCB DATA',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AQI ${_cityAqi?.aqi ?? 88} • ${_cityAqi?.categoryLabel ?? "Good"} (${_cityAqi?.status ?? "Clean Air"})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.solidBlack.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.solidBlack, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hubs',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, size: 14, color: AppColors.solidBlack),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2-Column Stat Cards matching reference ("Today / Streak" and "All / GreenKarma")
  Widget _buildStatCardsRow() {
    return Row(
      children: [
        // Left Card (Sage Green) - "Today / Streak"
        Expanded(
          child: NeoCard(
            color: AppColors.sageGreen,
            radius: 20,
            borderWidth: 2.0,
            shadowOffset: const Offset(3.5, 4.0),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solidBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.user.streak > 0 ? widget.user.streak : 5}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day Streak 🔥',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.solidBlack.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Right Card (Butter Yellow) - "All / GreenKarma"
        Expanded(
          child: NeoCard(
            color: AppColors.butterYellow,
            radius: 20,
            borderWidth: 2.0,
            shadowOffset: const Offset(3.5, 4.0),
            padding: const EdgeInsets.all(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KarmaCanteenScreen()),
              );
              if (mounted) {
                _loadData();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solidBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.user.points}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Karma Coins 🪙',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.solidBlack.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.solidBlack),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Weekly Progress Card with Smooth Animation and Live User Metrics
  Widget _buildWeeklyProgressCard() {
    final int targetGoal = widget.user.weekGoal > 0 ? widget.user.weekGoal : 500;
    final int currentPoints = widget.user.weekPoints > 0
        ? widget.user.weekPoints
        : (widget.user.streak > 0 ? widget.user.streak * 75 : 250);
    final double targetRatio = (currentPoints / targetGoal).clamp(0.05, 1.0);
    final int tasksCount = widget.user.actions > 0
        ? widget.user.actions
        : (widget.user.streak > 0 ? widget.user.streak : 3);

    return NeoCard(
      color: AppColors.butterYellow,
      radius: 22,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(18),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: targetRatio),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, child) {
          final int pct = (animatedValue * 100).round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Text(
                    '$pct% Completed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$pct%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$tasksCount actions logged this week • Target: $targetGoal Karma Coins',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.solidBlack.withValues(alpha: 0.75),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Feature 5: Intra-Campus "Step-to-Karma" Green Commute Tracker Banner
  Widget _buildGreenCommuteBanner() {
    final commuteData = GreenCommuteService().data;

    return NeoCard(
      color: AppColors.cardWhite,
      radius: 20,
      borderWidth: 2.2,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GreenCommuteScreen(user: widget.user)),
        );
        if (mounted) {
          _loadData();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeoPulseBadge(
                label: commuteData.isInsideCampus ? 'GEOFENCE ACTIVE • ON CAMPUS' : 'CAMPUS PERIMETER',
                badgeColor: commuteData.isInsideCampus ? AppColors.electricMint : AppColors.butterYellow,
                dotColor: commuteData.isInsideCampus ? const Color(0xFF1B5E20) : AppColors.solidBlack,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Text(
                  '🔥 ${commuteData.streakDays}-Day Streak',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                ),
                child: const Icon(Icons.directions_walk_rounded, color: AppColors.solidBlack, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step-to-Karma Green Commute',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${commuteData.stepsToday} steps today • ${(commuteData.co2SavedKg).toStringAsFixed(2)} kg CO2e saved vs. petrol motorbike',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.solidBlack.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.paperCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.solidBlack),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.paperCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.solidBlack, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 14, color: AppColors.solidBlack),
                    const SizedBox(width: 4),
                    Text(
                      '1 Karma Coin / 500 Steps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Redeem at Canteen ☕',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.leafGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hero GreenPassport Verifiable Digital MRV & NAAC Audit Banner
  Widget _buildGreenPassportBanner() {
    return NeoCard(
      color: AppColors.butterYellow,
      radius: 20,
      borderWidth: 2.2,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GreenPassportScreen(user: widget.user)),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
            ),
            child: const Icon(Icons.badge_rounded, color: AppColors.solidBlack, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Yuva GreenPassport™',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const NeoPulseBadge(
                      label: 'MRV',
                      badgeColor: AppColors.sageGreen,
                      dotColor: Color(0xFF1B5E20),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Verifiable Student Climate Transcript, Dynamic QR & NAAC 7.1 Score',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.solidBlack.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.solidBlack, width: 1.8),
            ),
            child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.solidBlack),
          ),
        ],
      ),
    );
  }

  /// Dedicated Karma Canteen & Rewards Store Promo Banner
  Widget _buildKarmaCanteenBanner() {
    return NeoCard(
      color: AppColors.paperCream,
      radius: 20,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KarmaCanteenScreen()),
        );
        if (mounted) {
          _loadData();
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.butterYellow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.solidBlack, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Karma Canteen & Perks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dustyCoral,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.solidBlack, width: 1.0),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Redeem tea in steel tumblers, cycle passes, 15% book barter discounts & tree plaques!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.solidBlack.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.solidBlack, width: 1.8),
            ),
            child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.solidBlack),
          ),
        ],
      ),
    );
  }

  /// Showcase Grid for the 4 core modules with rich imagery
  Widget _buildFeatureShowcaseGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Green Yuva Hubs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
            Text(
              'Interactive Modules',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.88,
          children: [
            _buildIllustratedModuleCard(
              title: 'YuvaSwap',
              subtitle: 'Campus Marketplace',
              badgeText: '♻️ Circular',
              imagePath: 'assets/images/yuva_swap.png',
              fallbackIcon: Icons.recycling_rounded,
              pillColor: AppColors.dustyCoral,
              onTap: _openYuvaSwap,
            ),
            _buildIllustratedModuleCard(
              title: 'GreenRush',
              subtitle: 'GPS Action Map',
              badgeText: '${_gameStats['inProgressEcores'] ?? 4} Hubs',
              imagePath: 'assets/images/green_rush.png',
              fallbackIcon: Icons.explore_rounded,
              pillColor: AppColors.sageGreen,
              onTap: _openClimaGames,
            ),
            _buildIllustratedModuleCard(
              title: 'YuvaSense',
              subtitle: 'Disaster & Quizzes',
              badgeText: _latestQuiz != null ? 'Quiz Ready' : 'Intel Map',
              imagePath: 'assets/images/yuva_sense.png',
              fallbackIcon: Icons.shield_rounded,
              pillColor: AppColors.butterYellow,
              onTap: () {
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  mainScreenState.onItemTapped(4);
                } else if (_latestQuiz != null) {
                  _openQuiz(_latestQuiz!);
                }
              },
            ),
            _buildIllustratedModuleCard(
              title: 'YuvaVibe',
              subtitle: 'Campus Social Feed',
              badgeText: '💬 Community',
              imagePath: 'assets/images/yuva_vibe.png',
              fallbackIcon: Icons.diversity_3_rounded,
              pillColor: AppColors.dustyCoral,
              onTap: _openClimaConnect,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIllustratedModuleCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required String imagePath,
    required IconData fallbackIcon,
    required Color pillColor,
    required VoidCallback onTap,
  }) {
    return NeoCard(
      radius: 18,
      color: AppColors.cardWhite,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.0, 3.5),
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top thumbnail image with 2px black border
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: pillColor,
                        child: Center(
                          child: Icon(fallbackIcon, size: 36, color: AppColors.solidBlack),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.solidBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCoreMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, color: AppColors.solidBlack, size: 22),
                const SizedBox(width: 8),
                Text(
                  'GreenRush Live Radar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _openClimaGames,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
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
                child: Text(
                  'Full Map →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NeoCard(
          radius: 20,
          borderWidth: 2.0,
          shadowOffset: const Offset(3.5, 4.0),
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: 210,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GreenRushRadarMap(
                      ecores: _visibleEcores.isNotEmpty
                          ? _visibleEcores
                          : ClimaGameService.getDefaultCampusEcores(),
                      userLocation: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : const LatLng(18.5204, 73.8567),
                      isCompact: true,
                      onOpenFullMap: _openClimaGames,
                    ),
                  ),

                  // Overlay status card
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.solidBlack, width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(2.0, 2.0),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_gameStats['inProgressEcores'] ?? 3}/${_gameStats['totalEcores'] ?? 5} Hubs Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Action Radar • India',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.solidBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_gameStats['conqueredEcores'] ?? 2} Cores Conquered',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.leafGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // "Action Hub" button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _openClimaGames,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.butterYellow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.solidBlack, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.solidBlack,
                              offset: Offset(2.0, 2.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Action Hub',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.solidBlack,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: AppColors.solidBlack,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Community Activities Section
  Widget _buildCommunityActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Campus Community Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
            GestureDetector(
              onTap: _openClimaConnect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
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
                child: Text(
                  'YuvaVibe →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_latestActivity != null)
          _buildActivityCard(_latestActivity!)
        else
          _buildEmptyActivityCard(),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return NeoCard(
      radius: 20,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(14),
      onTap: () {
        context.navigateWithCard(ActivityDetailScreen(
          activity: activity,
          user: widget.user,
          schoolId: widget.user.joinedSchoolId ?? '',
        ));
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildActivityImage(activity),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.4),
                      ),
                      child: Text(
                        '+${activity.points} Karma Coins',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(activity.date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activity.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.solidBlack.withValues(alpha: 0.75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityCard() {
    return NeoCard(
      radius: 20,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.5, 4.0),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.butterYellow,
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.solidBlack,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Community Activities',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.solidBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join a campus or initiate an activity to earn Karma Coins!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openQuiz(Quiz quiz) {
    context.navigateWithCard(QuizDetailScreen(quiz: quiz, user: widget.user));
  }

  void _openClimaGames() {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreenState != null) {
      mainScreenState.onItemTapped(3);
    }
  }

  void _openClimaConnect() {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreenState != null) {
      mainScreenState.onItemTapped(1);
    } else {
      context.navigateWithSlideFromRight(ClimaConnectScreen(user: widget.user));
    }
  }

  void _openYuvaSwap() {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreenState != null) {
      mainScreenState.onItemTapped(5);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const YuvaSwapScreen()));
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildActivityImage(Activity activity) {
    if (activity.imageUrl == null || activity.imageUrl!.isEmpty) {
      return Container(
        color: AppColors.paperCream,
        child: const Icon(Icons.event, size: 36, color: AppColors.solidBlack),
      );
    }

    if (activity.imageUrl!.startsWith('assets/images/')) {
      return Image.asset(
        activity.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.paperCream,
          child: const Icon(Icons.broken_image, size: 36, color: AppColors.solidBlack),
        ),
      );
    }

    if (activity.imageUrl!.startsWith('http://') || activity.imageUrl!.startsWith('https://')) {
      return Image.network(
        activity.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.paperCream,
          child: const Icon(Icons.broken_image, size: 36, color: AppColors.solidBlack),
        ),
      );
    }

    return Container(
      color: AppColors.paperCream,
      child: const Icon(Icons.event, size: 36, color: AppColors.solidBlack),
    );
  }
}
