import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/resilience_tab.dart';
import '../widgets/quiz_tab.dart';
import 'cases_screen.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import '../services/aqi_service.dart';

class ClimaSightsScreen extends StatefulWidget {
  final AppUser user;

  const ClimaSightsScreen({super.key, required this.user});

  @override
  State<ClimaSightsScreen> createState() => _ClimaSightsScreenState();
}

class _ClimaSightsScreenState extends State<ClimaSightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AqiService _aqiService = AqiService();
  CityAqiData? _cityAqi;
  String _selectedCity = 'Pune';
  bool _isLoadingAqi = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _loadAqiData();
  }

  int _aqiRequestId = 0;

  Future<void> _loadAqiData([String? city]) async {
    if (!mounted) return;
    final requestId = ++_aqiRequestId;
    setState(() => _isLoadingAqi = true);
    String targetCity = city ?? _selectedCity;
    CityAqiData? data;
    try {
      targetCity = city ?? await _aqiService.getSelectedCity();
      data = await _aqiService.fetchCityAqi(targetCity);
    } catch (e) {
      debugPrint('AQI load failed: $e');
    }
    // Ignore stale responses when the user switched city again meanwhile
    if (mounted && requestId == _aqiRequestId) {
      setState(() {
        _selectedCity = targetCity;
        _cityAqi = data ?? _cityAqi;
        _isLoadingAqi = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                color: AppColors.dustyCoral,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.solidBlack, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'YuvaSense',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 48),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Live CPCB AQI'),
                  Tab(text: 'Topic Quizzes'),
                  Tab(text: 'Disaster Tracker'),
                  Tab(text: 'Case Studies'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PaperGridBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLiveAqiTab(),
            QuizTab(user: widget.user),
            ResilienceTab(),
            const CasesScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAqiTab() {
    if (_isLoadingAqi) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.solidBlack),
      );
    }

    final aqiData = _cityAqi;

    return RefreshIndicator(
      onRefresh: () => _loadAqiData(_selectedCity),
      color: AppColors.solidBlack,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          // City Selector Horizontal Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AqiService.supportedCities.map((city) {
                final isSelected = _selectedCity.toLowerCase() == city.name.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () async {
                      await _aqiService.setSelectedCity(city.name);
                      _loadAqiData(city.name);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.butterYellow : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.solidBlack,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isSelected ? AppColors.solidBlack : AppColors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            city.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Main Hero CPCB Live Monitor Card
          NeoCard(
            color: aqiData?.badgeColor ?? AppColors.sageGreen,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sensors_rounded, size: 13, color: AppColors.solidBlack),
                          const SizedBox(width: 4),
                          Text(
                            aqiData?.isLive == true ? 'CPCB LIVE MONITOR' : 'CPCB CALIBRATED DATA',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${aqiData?.state ?? "Maharashtra"} Hub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.solidBlack.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${aqiData?.aqi ?? 88}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AIR QUALITY INDEX',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.solidBlack.withValues(alpha: 0.7),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              aqiData?.statusIcon ?? Icons.sentiment_satisfied_alt_rounded,
                              color: AppColors.solidBlack,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              aqiData?.categoryLabel ?? 'Satisfactory',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.solidBlack, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.solidBlack),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aqiData?.advisory ??
                              'Air quality is in the safe range for campus sports and active mobility.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.solidBlack,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Particulate Pollutants Breakdown Row (PM2.5 & PM10)
          Row(
            children: [
              Expanded(
                child: NeoCard(
                  color: AppColors.cardWhite,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PM2.5',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paperCream,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solidBlack, width: 1.0),
                            ),
                            child: const Text(
                              'Fine Dust',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${aqiData?.pm25.toStringAsFixed(1) ?? "29.4"} µg/m³',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CPCB Limit: 60 µg/m³',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedText,
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PM10',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.solidBlack,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paperCream,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solidBlack, width: 1.0),
                            ),
                            child: const Text(
                              'Coarse',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${aqiData?.pm10.toStringAsFixed(1) ?? "64.2"} µg/m³',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CPCB Limit: 100 µg/m³',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // National Student Hubs Comparison List
          NeoCard(
            color: AppColors.cardWhite,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded, color: AppColors.solidBlack, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Indian Student Hubs Live AQI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...AqiService.supportedCities.map((city) {
                  final isCurrent = _selectedCity.toLowerCase() == city.name.toLowerCase();
                  Color tagColor = AppColors.sageGreen;
                  String tagLabel = 'Good';
                  if (city.fallbackAqi > 200) {
                    tagColor = AppColors.dustyCoral;
                    tagLabel = 'Severe';
                  } else if (city.fallbackAqi > 100) {
                    tagColor = AppColors.butterYellow;
                    tagLabel = 'Moderate';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        _aqiService.setSelectedCity(city.name);
                        _loadAqiData(city.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.paperCream : AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? AppColors.solidBlack : AppColors.solidBlack.withValues(alpha: 0.15),
                            width: isCurrent ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  city.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${city.state})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tagColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.solidBlack, width: 1.2),
                              ),
                              child: Text(
                                'AQI ${city.fallbackAqi} • $tagLabel',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 100), // padding for floating nav bar
        ],
      ),
    );
  }
}
