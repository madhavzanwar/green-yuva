import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ecore.dart';
import '../models/user.dart';
import '../services/climagame_service.dart';
import '../services/location_service.dart';
import '../widgets/ecore_mission_modal.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/green_rush_radar_map.dart';

class ClimaGameScreen extends StatefulWidget {
  final AppUser user;

  const ClimaGameScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ClimaGameScreen> createState() => _ClimaGameScreenState();
}

class _ClimaGameScreenState extends State<ClimaGameScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  LatLng _initialPosition = const LatLng(18.5204, 73.8567); // Pune center
  int _userDailyMissionCount = 1;

  List<Ecore> _visibleEcores = [];
  List<Map<String, dynamic>> _schoolRankings = [];
  Ecore? _selectedEcore;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _sortByNearest = true;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _visibleEcores = ClimaGameService.getDefaultCampusEcores();
    if (_visibleEcores.isNotEmpty) {
      _selectedEcore = _visibleEcores.first;
    }
    _loadData();
    _tryGetRealLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _tryGetRealLocation({bool showFeedback = false}) async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
    });

    try {
      final pos = await LocationService.determinePosition();
      if (mounted) {
        final newLatLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _initialPosition = newLatLng;
          _isLocating = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 14.5),
        );

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.solidBlack,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.electricMint, width: 2.0),
              ),
              content: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, color: AppColors.electricMint, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GPS Locked: ${newLatLng.latitude.toStringAsFixed(4)}° N, ${newLatLng.longitude.toStringAsFixed(4)}° E',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final ecores = await ClimaGameService.getVisibleEcores();
      final rankings = await ClimaGameService.getSchoolRankings();
      final missionCount = await ClimaGameService.getUserDailyMissionCount(widget.user.id);

      if (mounted) {
        setState(() {
          _visibleEcores = ecores;
          _schoolRankings = rankings;
          _userDailyMissionCount = missionCount;
          if (_selectedEcore == null && ecores.isNotEmpty) {
            _selectedEcore = ecores.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading GreenRush data: $e');
    }
  }

  List<Ecore> _getFilteredEcores() {
    final query = _searchQuery.trim().toLowerCase();
    var list = _visibleEcores.where((e) {
      final matchesQuery = query.isEmpty ||
          e.name.toLowerCase().contains(query) ||
          (e.conqueredBySchoolName ?? '').toLowerCase().contains(query);

      final matchesCat = _selectedCategory == 'all' ||
          (_selectedCategory == 'eng' &&
              (e.name.contains('Engineering') ||
                  e.name.contains('Tech') ||
                  e.name.contains('COEP') ||
                  e.name.contains('PICT') ||
                  e.name.contains('VIT') ||
                  e.name.contains('PCCOE') ||
                  e.name.contains('AIT') ||
                  e.name.contains('SCOE') ||
                  e.name.contains('VJTI'))) ||
          (_selectedCategory == 'uni' &&
              (e.name.contains('University') ||
                  e.name.contains('WPU') ||
                  e.name.contains('SPPU') ||
                  e.name.contains('BITS') ||
                  e.name.contains('Symbiosis') ||
                  e.name.contains('Bharati') ||
                  e.name.contains('IIT') ||
                  e.name.contains('IISc'))) ||
          (_selectedCategory == 'green' && e.isConquered);

      return matchesQuery && matchesCat;
    }).toList();

    if (_sortByNearest) {
      list.sort((a, b) {
        final distA = LocationService.calculateDistanceInMeters(
          _initialPosition.latitude,
          _initialPosition.longitude,
          a.latitude,
          a.longitude,
        );
        final distB = LocationService.calculateDistanceInMeters(
          _initialPosition.latitude,
          _initialPosition.longitude,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });
    }

    return list;
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openMissionModal(Ecore ecore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EcoreMissionModal(
        ecore: ecore,
        user: widget.user,
        onMissionCompleted: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.solidBlack,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.butterYellow, width: 2.0),
              ),
              content: Text(
                'Mission Completed! +50 Karma Coins earned 🌟',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  NeoBackButton(
                    onPressed: () {
                      final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                      if (mainScreenState != null) {
                        mainScreenState.onItemTapped(0);
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butterYellow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore_rounded, color: AppColors.solidBlack, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'GreenRush',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.electricMint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.solidBlack, width: 1.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: AppColors.solidBlack),
                        const SizedBox(width: 4),
                        Text(
                          'Daily: $_userDailyMissionCount/5',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
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

            // Tab Bar
            Container(
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
                ),
                labelColor: AppColors.solidBlack,
                unselectedLabelColor: AppColors.solidBlack.withValues(alpha: 0.6),
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: const [
                  Tab(text: 'Campus Locator'),
                  Tab(text: 'Satellite & Radar'),
                  Tab(text: 'Campus Leaderboard'),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLocatorTab(),
                  _buildMapTab(),
                  _buildRankingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocatorTab() {
    final filtered = _getFilteredEcores();
    final pos = _initialPosition;

    return PaperGridBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 780;

          final headerAndFilters = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.solidBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search college, university, or area (e.g. PCCOE, COEP, Pune, VIT)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.solidBlack, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.solidBlack),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Filter Chips & GPS Auto-Detect Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Auto Locate GPS Button
                      GestureDetector(
                        onTap: () => _tryGetRealLocation(showFeedback: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: _isLocating ? AppColors.butterYellow : AppColors.electricMint,
                            borderRadius: BorderRadius.circular(12),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLocating
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.solidBlack,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded, size: 14, color: AppColors.solidBlack),
                              const SizedBox(width: 5),
                              Text(
                                _isLocating ? 'Scanning GPS...' : 'Auto-Locate GPS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Category Pills
                      ...[
                        {'id': 'all', 'label': 'All Campuses (${_visibleEcores.length})'},
                        {'id': 'eng', 'label': '🏛️ Engineering'},
                        {'id': 'uni', 'label': '🎓 Universities'},
                        {'id': 'green', 'label': '🌿 Green Cells'},
                      ].map((cat) {
                        final isSel = _selectedCategory == cat['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat['id']!;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.solidBlack : AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.solidBlack, width: 1.6),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.solidBlack,
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              cat['label']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : AppColors.solidBlack,
                              ),
                            ),
                          ),
                        );
                      }),

                      // Nearest Sort Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sortByNearest = !_sortByNearest;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _sortByNearest ? AppColors.butterYellow : AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.solidBlack, width: 1.6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _sortByNearest ? Icons.check_circle_rounded : Icons.sort_rounded,
                                size: 13,
                                color: AppColors.solidBlack,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Closest First',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filtered.length} Verified Institutions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'GPS: ${pos.latitude.toStringAsFixed(3)}°, ${pos.longitude.toStringAsFixed(3)}°',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.leafGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          );

          if (isWide) {
            // Desktop 2-column Bento: Left = List, Right = Map
            return Column(
              children: [
                headerAndFilters,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (List)
                        Expanded(
                          flex: 5,
                          child: filtered.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 80, right: 8),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    return _buildCampusCard(filtered[index], pos);
                                  },
                                ),
                        ),
                        const SizedBox(width: 14),
                        // Right Column (Map)
                        Expanded(
                          flex: 7,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppColors.solidBlack, width: 2.2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.solidBlack,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: GreenRushRadarMap(
                                ecores: filtered.isNotEmpty ? filtered : _visibleEcores,
                                userLocation: pos,
                                selectedEcore: _selectedEcore,
                                onLocationUpdated: (newPos) {
                                  setState(() {
                                    _initialPosition = newPos;
                                  });
                                },
                                onEcoreTap: (ecore) {
                                  setState(() {
                                    _selectedEcore = ecore;
                                  });
                                  _openMissionModal(ecore);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile: Top Mini Map Preview + Scrollable List
            return Column(
              children: [
                headerAndFilters,
                // Mini Map preview
                Container(
                  height: 190,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GreenRushRadarMap(
                    ecores: filtered.isNotEmpty ? filtered : _visibleEcores,
                    userLocation: pos,
                    selectedEcore: _selectedEcore,
                    isCompact: true,
                    onLocationUpdated: (newPos) {
                      setState(() {
                        _initialPosition = newPos;
                      });
                    },
                    onEcoreTap: (ecore) {
                      setState(() {
                        _selectedEcore = ecore;
                      });
                      _openMissionModal(ecore);
                    },
                  ),
                ),
                // Campuses list
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildCampusCard(filtered[index], pos);
                          },
                        ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              'No campuses matched your search',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.solidBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different college name or reset your category filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusCard(Ecore ecore, LatLng pos) {
    final isSelected = _selectedEcore?.id == ecore.id;
    final dist = LocationService.calculateDistanceInMeters(
      pos.latitude,
      pos.longitude,
      ecore.latitude,
      ecore.longitude,
    );
    final distStr = LocationService.formatDistance(dist);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: NeoCard(
        color: isSelected ? AppColors.butterYellow : AppColors.cardWhite,
        radius: 18,
        borderWidth: 2.0,
        shadowOffset: const Offset(3, 3),
        padding: const EdgeInsets.all(14),
        onTap: () {
          setState(() {
            _selectedEcore = ecore;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + Status Badge + Distance Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ecore.isConquered ? AppColors.electricMint : AppColors.softSky,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.solidBlack, width: 1.4),
                  ),
                  child: Text(
                    ecore.isConquered ? 'VERIFIED GREEN CELL' : 'ACTIVE CORE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ),
                const Spacer(),
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.pureWhite : AppColors.butterYellow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.solidBlack, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, size: 11, color: AppColors.solidBlack),
                      const SizedBox(width: 3),
                      Text(
                        distStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // College Name
            Text(
              ecore.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.solidBlack,
              ),
            ),
            if (ecore.conqueredBySchoolName != null) ...[
              const SizedBox(height: 3),
              Text(
                ecore.conqueredBySchoolName!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Quests and Points Row
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 14, color: AppColors.solidBlack),
                const SizedBox(width: 4),
                Text(
                  '${ecore.missions.length} Missions • +${ecore.totalPoints} Karma Coins',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Action Buttons: Get Directions & Missions
            Row(
              children: [
                // Google Maps Directions (SchemeSetu / Samarth style)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openDirections(ecore.latitude, ecore.longitude),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_rounded, size: 14, color: AppColors.solidBlack),
                          const SizedBox(width: 4),
                          Text(
                            'Get Directions ↗',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Quests Modal Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMissionModal(ecore),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.electricMint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag_rounded, size: 13, color: AppColors.solidBlack),
                          const SizedBox(width: 4),
                          Text(
                            'Start Missions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        // Interactive GreenRush Tactical Radar & Map
        Positioned.fill(
          child: GreenRushRadarMap(
            ecores: _visibleEcores.isNotEmpty
                ? _visibleEcores
                : ClimaGameService.getDefaultCampusEcores(),
            userLocation: _initialPosition,
            selectedEcore: _selectedEcore,
            isCompact: false,
            onLocationUpdated: (newPos) {
              setState(() {
                _initialPosition = newPos;
              });
            },
            onEcoreTap: (ecore) {
              setState(() {
                _selectedEcore = ecore;
              });
              _openMissionModal(ecore);
            },
          ),
        ),

        // Action Hub Horizontal Carousel at Bottom
        Positioned(
          bottom: 105, // Elevated above floating bottom navbar
          left: 0,
          right: 0,
          child: SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _visibleEcores.length,
              itemBuilder: (context, index) {
                final ecore = _visibleEcores[index];
                final isSelected = _selectedEcore?.id == ecore.id;

                return Container(
                  width: 270,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: NeoCard(
                    color: isSelected ? AppColors.butterYellow : AppColors.pureWhite,
                    radius: 18,
                    borderWidth: 2.0,
                    shadowOffset: const Offset(3, 3),
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      setState(() {
                        _selectedEcore = ecore;
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ecore.isConquered ? AppColors.electricMint : AppColors.dustyCoral,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.solidBlack, width: 1.4),
                              ),
                              child: Text(
                                ecore.isConquered ? 'CONQUERED' : 'ACTIVE CORE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${ecore.totalPoints} Karma Coins',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          ecore.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${ecore.missions.length} Quests',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.solidBlack.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardWhite,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.solidBlack, width: 1.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me_rounded, size: 10, color: AppColors.solidBlack),
                                      const SizedBox(width: 2),
                                      Text(
                                        LocationService.formatDistance(
                                          LocationService.calculateDistanceInMeters(
                                            _initialPosition.latitude,
                                            _initialPosition.longitude,
                                            ecore.latitude,
                                            ecore.longitude,
                                          ),
                                        ),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.solidBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final url = 'https://www.google.com/maps/dir/?api=1&destination=${ecore.latitude},${ecore.longitude}';
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.butterYellow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.solidBlack, width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.directions_rounded, size: 12, color: AppColors.solidBlack),
                                        const SizedBox(width: 2),
                                        Text(
                                          'GPS',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.solidBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _openMissionModal(ecore),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.electricMint,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.solidBlack, width: 1.5),
                                    ),
                                    child: Text(
                                      'Missions →',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.solidBlack,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTab() {
    return PaperGridBackground(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _schoolRankings.length,
        itemBuilder: (context, index) {
          final school = _schoolRankings[index];
          final conquered = school['conqueredEcores'] ?? 0;
          final isTop3 = index < 3;

          Color rankColor() {
            switch (index) {
              case 0: return AppColors.butterYellow;
              case 1: return AppColors.pureWhite;
              case 2: return AppColors.dustyCoral;
              default: return AppColors.pureWhite;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: NeoCard(
              color: rankColor(),
              radius: 16,
              borderWidth: 2.0,
              shadowOffset: const Offset(2.5, 3),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isTop3 ? AppColors.solidBlack : AppColors.paperCream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.solidBlack, width: 1.8),
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isTop3 ? Colors.white : AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      school['schoolName'] ?? 'Unknown Campus',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.solidBlack, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: AppColors.solidBlack),
                        const SizedBox(width: 4),
                        Text(
                          '$conquered Cores',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
