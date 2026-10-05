import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/green_commute_data.dart';
import '../models/user.dart';
import '../services/green_commute_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'karma_canteen_screen.dart';

class GreenCommuteScreen extends StatefulWidget {
  final AppUser user;

  const GreenCommuteScreen({
    super.key,
    required this.user,
  });

  @override
  State<GreenCommuteScreen> createState() => _GreenCommuteScreenState();
}

class _GreenCommuteScreenState extends State<GreenCommuteScreen> {
  final GreenCommuteService _commuteService = GreenCommuteService();
  final UserService _userService = UserService();
  late AppUser _currentUser;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _commuteService.init();
    _commuteService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _commuteService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleClaimKarma(int unclaimed) async {
    if (unclaimed <= 0 || _isClaiming) return;

    setState(() => _isClaiming = true);
    HapticFeedback.heavyImpact();

    final claimed = await _commuteService.claimKarmaCoins(_currentUser.id);
    final updatedUser = await _userService.getUserById(_currentUser.id);

    if (mounted) {
      setState(() {
        _isClaiming = false;
        if (updatedUser != null) _currentUser = updatedUser;
      });

      showNeoStickerModal(
        context: context,
        stickerEmoji: '🪙',
        badgeLabel: 'GREEN COMMUTE PAYOUT',
        title: '+$claimed KARMA COINS!',
        description: 'Your intra-campus walking steps have been converted into Karma Coins. Enjoy an afternoon iced lemon tea or samosa at the Karma Canteen!',
        actionText: 'Visit Karma Canteen ☕',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KarmaCanteenScreen()),
          );
        },
      );
    }
  }

  Future<void> _handleSimulateWalk() async {
    HapticFeedback.lightImpact();
    await _commuteService.simulateCampusWalk(steps: 250);
  }

  @override
  Widget build(BuildContext context) {
    final data = _commuteService.data;

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.butterYellow,
            borderRadius: BorderRadius.circular(14),
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
              const Icon(Icons.directions_walk_rounded, size: 16, color: AppColors.solidBlack),
              const SizedBox(width: 6),
              Text(
                'STEP-TO-KARMA TRACKER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Live Geofence Banner
            _buildGeofenceBanner(data),
            const SizedBox(height: 16),

            // Hero Pedometer Progress Dial Card
            _buildPedometerCard(data),
            const SizedBox(height: 16),

            // Tailpipe Carbon Offset Math Grid
            _buildCarbonOffsetGrid(data),
            const SizedBox(height: 16),

            // Karma Payout & Canteen Perk Redemption Card
            _buildKarmaClaimCard(data),
            const SizedBox(height: 16),

            // Daily Green Transit Streak Card
            _buildTransitStreakCard(data),
            const SizedBox(height: 16),

            // Intra-Campus Micro-Trip Routes
            _buildCampusRoutesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceBanner(GreenCommuteData data) {
    return NeoCard(
      color: AppColors.cardWhite,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeoPulseBadge(
                label: data.isInsideCampus ? 'GEOFENCE ACTIVE • ON CAMPUS' : 'OUTSIDE CAMPUS BOUNDARY',
                badgeColor: data.isInsideCampus ? AppColors.electricMint : AppColors.dustyCoral,
                dotColor: data.isInsideCampus ? Colors.green[800]! : Colors.red[800]!,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Text(
                  '${data.distanceFromCampusMeters.toInt()}m from core',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.isInsideCampus
                ? '📍 Geofenced Pedometer actively recording steps within ${data.campusName}. Non-motorized footsteps offset tailpipe petrol trips!'
                : '📍 Steps outside the 1,500m campus boundary are paused to maintain verified institutional carbon accounting.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedometerCard(GreenCommuteData data) {
    final pct = (data.progressFraction * 100).toInt();

    return NeoCard(
      color: AppColors.cardWhite,
      radius: 20,
      borderWidth: 2.5,
      shadowOffset: const Offset(4.0, 4.5),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAMPUS WALKING STEPS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily Goal: ${data.dailyGoal} steps (2 km)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.solidBlack, width: 1.5),
                ),
                child: Text(
                  '$pct% OF GOAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Steps Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${data.stepsToday}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'steps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // High-contrast Neo-Brutalist Progress Bar
          Container(
            height: 18,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.paperCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: data.progressFraction,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.electricMint,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Simulation Button (Allows instant demo testing of 250 campus steps)
          GestureDetector(
            onTap: _handleSimulateWalk,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_walk_rounded, size: 18, color: AppColors.solidBlack),
                  const SizedBox(width: 6),
                  Text(
                    'Simulate +250 Campus Steps (Hostel ↔ Dept)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
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
    );
  }

  Widget _buildCarbonOffsetGrid(GreenCommuteData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TAILPIPE CARBON OFFSET MATH (1,500 STEPS ≈ 1 KM)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: NeoMetricCard(
                value: '${data.co2SavedKg.toStringAsFixed(2)} kg',
                label: 'CO2e Avoided',
                subtext: 'vs. 2-wheeler petrol',
                icon: Icons.energy_savings_leaf_rounded,
                color: AppColors.cardWhite,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeoMetricCard(
                value: '${data.petrolSavedLiters.toStringAsFixed(2)} L',
                label: 'Petrol Saved',
                subtext: '35 km/L campus standard',
                icon: Icons.local_gas_station_rounded,
                color: AppColors.cardWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NeoMetricCard(
                value: '${data.distanceKm.toStringAsFixed(2)} km',
                label: 'Active Mobility',
                subtext: 'Non-motorized transit',
                icon: Icons.route_rounded,
                color: AppColors.cardWhite,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeoMetricCard(
                value: '${data.microTripsReplaced.toStringAsFixed(1)} Trips',
                label: 'Trips Replaced',
                subtext: '800m hostel-to-dept',
                icon: Icons.moped_rounded,
                color: AppColors.cardWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKarmaClaimCard(GreenCommuteData data) {
    final unclaimed = data.unclaimedKarma;

    return NeoCard(
      color: AppColors.butterYellow,
      radius: 18,
      borderWidth: 2.5,
      shadowOffset: const Offset(4.0, 4.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 22, color: AppColors.solidBlack),
                  const SizedBox(width: 6),
                  Text(
                    'DAILY GREEN TRANSIT KARMA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Text(
                  '1 Coin / 500 Steps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Total Karma earned today: ${data.totalKarmaEligible} Coins. Seamlessly redeemable for afternoon iced lemon tea or hot samosas at Karma Canteen!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          if (unclaimed > 0)
            NeoButton(
              text: 'Claim +$unclaimed Karma Coins 🪙',
              color: AppColors.electricMint,
              textColor: AppColors.solidBlack,
              onPressed: () => _handleClaimKarma(unclaimed),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.solidBlack, width: 1.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.leafGreen),
                  const SizedBox(width: 6),
                  Text(
                    'All Available Karma Claimed (${data.claimedKarmaCoins} Credited)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Direct Canteen Link Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KarmaCanteenScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
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
                  const Icon(Icons.fastfood_rounded, size: 16, color: AppColors.solidBlack),
                  const SizedBox(width: 6),
                  Text(
                    'Redeem for Iced Lemon Tea & Samosa at Canteen ☕',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
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
    );
  }

  Widget _buildTransitStreakCard(GreenCommuteData data) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final currentDayIndex = DateTime.now().weekday - 1;

    return NeoCard(
      color: AppColors.cardWhite,
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, size: 20, color: AppColors.dustyCoral),
                  const SizedBox(width: 6),
                  Text(
                    '${data.streakDays}-DAY GREEN TRANSIT STREAK',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Text(
                  '≥1,500 Steps/Day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your non-motorized habit alive! Walk across campus daily to power zero-emission campus decarbonization.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // 7-Day Bubble Matrix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == currentDayIndex;
              final isPast = i < currentDayIndex;
              final isCompleted = isPast || (isToday && data.stepsToday >= 1500);

              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.electricMint
                          : (isToday ? AppColors.butterYellow : AppColors.paperCream),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.solidBlack, width: 1.8),
                      boxShadow: isCompleted || isToday
                          ? const [
                              BoxShadow(
                                color: AppColors.solidBlack,
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : (isToday ? Icons.directions_walk_rounded : Icons.circle_outlined),
                        size: 16,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isToday ? AppColors.solidBlack : AppColors.mutedText,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusRoutesCard() {
    final routes = [
      {
        'title': 'Hostel 4 ➔ Dept. of Computer Science',
        'steps': '1,200 steps (~800m)',
        'offset': '0.096 kg CO2e saved',
        'icon': Icons.school_rounded,
      },
      {
        'title': 'Central Canteen ➔ Main Library',
        'steps': '900 steps (~600m)',
        'offset': '0.072 kg CO2e saved',
        'icon': Icons.local_library_rounded,
      },
      {
        'title': 'Sports Ground ➔ Innovation Core',
        'steps': '1,500 steps (~1,000m)',
        'offset': '0.120 kg CO2e saved',
        'icon': Icons.sports_tennis_rounded,
      },
    ];

    return NeoCard(
      color: AppColors.cardWhite,
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAMPUS MICRO-TRIP GREEN CORRIDORS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...routes.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.paperCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.2),
                      ),
                      child: Icon(r['icon'] as IconData, size: 16, color: AppColors.solidBlack),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solidBlack,
                            ),
                          ),
                          Text(
                            '${r['steps']} • ${r['offset']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.leafGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
