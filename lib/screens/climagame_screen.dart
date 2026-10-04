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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _visibleEcores = ClimaGameService.getDefaultCampusEcores();
    if (_visibleEcores.isNotEmpty) {
      _selectedEcore = _visibleEcores.first;
    }
    _loadData();
    _tryGetRealLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _tryGetRealLocation() async {
    try {
      final pos = await LocationService.determinePosition();
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(pos.latitude, pos.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 14.0),
        );
      }
    } catch (_) {}
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
      print('Error loading GreenRush data: $e');
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
                  Tab(text: 'Action Map & Radar'),
                  Tab(text: 'Campus Leaderboard'),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(ecore.latitude, ecore.longitude), 15.0),
                      );
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
                            Text(
                              '${ecore.missions.length} Action Quests',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.solidBlack.withValues(alpha: 0.7),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openMissionModal(ecore),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.electricMint,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.solidBlack, width: 1.6),
                                ),
                                child: Text(
                                  'View Missions →',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
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
