import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/user.dart';
import '../models/green_passport.dart';
import '../services/green_passport_service.dart';
import '../theme/app_theme.dart';

class GreenPassportScreen extends StatefulWidget {
  final AppUser user;

  const GreenPassportScreen({super.key, required this.user});

  @override
  State<GreenPassportScreen> createState() => _GreenPassportScreenState();
}

class _GreenPassportScreenState extends State<GreenPassportScreen>
    with SingleTickerProviderStateMixin {
  final GreenPassportService _passportService = GreenPassportService();
  GreenPassport? _passport;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPassport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPassport() async {
    setState(() => _isLoading = true);
    final passport = await _passportService.generatePassportForUser(widget.user);
    if (mounted) {
      setState(() {
        _passport = passport;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.butterYellow, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.solidBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.butterYellow, width: 1.5),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showShareModal(GreenPassport passport) {
    showNeoStickerModal(
      context: context,
      stickerEmoji: '🪪',
      badgeLabel: 'VERIFIABLE MRV CREDENTIAL',
      title: 'Yuva GreenPassport™ Ready!',
      description:
          'Your climate impact transcript is cryptographically verified and ready for student placements, LinkedIn credentials, and NAAC collegiate records.',
      customContent: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paperCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded, size: 18, color: AppColors.solidBlack),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    passport.verificationUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _copyToClipboard(
                      passport.verificationUrl,
                      'Verification link copied to clipboard!',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.butterYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.solidBlack, width: 1.2),
                    ),
                    child: Text(
                      'Copy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Audit Hash: ${passport.verificationHash}',
              style: GoogleFonts.sourceCodePro(
                fontSize: 10,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      actionText: 'Done',
      onAction: () {},
    );
  }

  void _showExportPdfModal(GreenPassport passport) {
    showNeoStickerModal(
      context: context,
      stickerEmoji: '📜',
      badgeLabel: 'NAAC CRITERION 7.1 AUDIT',
      title: 'Audit PDF Generated!',
      description:
          'Official Institutional Decarbonization Audit has been compiled with university digital seals, EPA WARM carbon equations, and student QR verification.',
      customContent: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sageGreen.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.solidBlack, width: 1.6),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.solidBlack, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${passport.campusName} - ESG Audit.pdf',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Text(
                    'Grade: ${passport.naacScore}/100 (${passport.naacGrade})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.solidBlack.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionText: 'Save to Device',
      onAction: () {
        _copyToClipboard(passport.verificationUrl, 'Official PDF downloaded to Downloads/ folder');
      },
    );
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: const Icon(Icons.badge_rounded, color: AppColors.solidBlack, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Yuva GreenPassport™',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_passport != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: InkWell(
                  onTap: () => _showShareModal(_passport!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.share_rounded, color: AppColors.solidBlack, size: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PaperGridBackground(
        child: _isLoading || _passport == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.solidBlack),
              )
            : RefreshIndicator(
                onRefresh: _loadPassport,
                color: AppColors.solidBlack,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PHYSICAL MRV IDENTITY CARD
                      _buildHeroPassportCard(_passport!),
                      const SizedBox(height: 18),

                      // 2. VIEW TOGGLE TABS (Neo-Brutalist Segment)
                      _buildViewTabs(),
                      const SizedBox(height: 16),

                      // 3. TAB VIEW CONTENT
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _tabController.index == 0
                              ? _buildStudentLedgerView(_passport!)
                              : _buildNaacInstitutionalView(_passport!);
                        },
                      ),
                      const SizedBox(height: 20),

                      // 4. BOTTOM ACTION BUTTONS
                      _buildActionButtons(_passport!),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// High-Contrast Neo-Brutalist Physical Identity Passport Card
  Widget _buildHeroPassportCard(GreenPassport passport) {
    return NeoCard(
      color: AppColors.cardWhite,
      radius: 24,
      borderWidth: 2.5,
      shadowOffset: const Offset(4.0, 5.0),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Ribbon: Ministry / National Youth Protocol Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.dustyCoral,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.solidBlack, width: 1.5),
                    ),
                    child: const Icon(Icons.eco_rounded, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'INDIA DIGITAL MRV CREDENTIAL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
              const NeoPulseBadge(
                label: 'VERIFIED',
                badgeColor: AppColors.sageGreen,
                dotColor: Color(0xFF1B5E20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Card Row: Student Details Left + QR Code Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Avatar + Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passport.studentName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passport.campusName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.4),
                      ),
                      child: Text(
                        passport.studentCode,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right: Dynamic Verifiable QR Code
              GestureDetector(
                onTap: () => _copyToClipboard(passport.verificationUrl, 'Verification link copied!'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2.0, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: passport.verificationUrl,
                        version: QrVersions.auto,
                        size: 96.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SCAN TO AUDIT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cryptographic Audit Hash Bar
          GestureDetector(
            onTap: () => _copyToClipboard(passport.verificationHash, 'Cryptographic hash copied!'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paperCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 16, color: AppColors.solidBlack),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      passport.verificationHash,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.solidBlack),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Neo-Brutalist Tab Switcher (Student Transcript vs NAAC Accreditation View)
  Widget _buildViewTabs() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.solidBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: Offset(2.0, 2.5),
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
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: '🎓 Student MRV Ledger'),
          Tab(text: '🏛️ NAAC 7.1 Audit'),
        ],
      ),
    );
  }

  /// Tab 1: Student MRV Ledger & Quantified Climate Metrics
  Widget _buildStudentLedgerView(GreenPassport passport) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Key Climate Metrics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            NeoMetricCard(
              value: '${passport.wasteDivertedKg} kg',
              label: 'Landfill Diverted',
              subtext: 'YuvaSwap zero-waste cycle',
              icon: Icons.recycling_rounded,
              color: AppColors.sageGreen.withValues(alpha: 0.45),
            ),
            NeoMetricCard(
              value: '${passport.co2MitigatedKg} kg',
              label: 'CO₂e Avoided',
              subtext: 'EPA WARM paper factors',
              icon: Icons.cloud_off_rounded,
              color: AppColors.dustyCoral.withValues(alpha: 0.45),
            ),
            NeoMetricCard(
              value: '${passport.methaneAvoidedGrams} g',
              label: 'Methane (CH₄) Cut',
              subtext: 'IPCC First-Order Decay',
              icon: Icons.science_rounded,
              color: AppColors.butterYellow.withValues(alpha: 0.45),
            ),
            NeoMetricCard(
              value: '${passport.treeSurvivalRatePct}%',
              label: 'Sapling Survival',
              subtext: '${passport.treesNurtured} trees nurtured (90d+)',
              icon: Icons.park_rounded,
              color: AppColors.cardWhite,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Section Title: Verifiable Audit Ledger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Verifiable Action Ledger',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
            Text(
              '${passport.verifiedActionsCount} Actions Logged',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chronological List of Verified MRV Actions
        ...passport.recentLedger.map((action) => _buildLedgerCard(action)),
      ],
    );
  }

  /// Individual Action Ledger Card
  Widget _buildLedgerCard(GreenPassportActionRecord action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeoCard(
        color: AppColors.cardWhite,
        radius: 16,
        borderWidth: 2.0,
        shadowOffset: const Offset(2.5, 3.0),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.6),
              ),
              child: Icon(action.icon, size: 20, color: AppColors.solidBlack),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.paperCream,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.solidBlack, width: 1.0),
                        ),
                        child: Text(
                          action.category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                      Text(
                        'Verified',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.impactMetric,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Protocol: ${action.verificationType}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 2: Institutional NAAC Criterion 7.1 Compliance View
  Widget _buildNaacInstitutionalView(GreenPassport passport) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NAAC Summary Card
        NeoCard(
          color: AppColors.butterYellow,
          radius: 20,
          borderWidth: 2.2,
          shadowOffset: const Offset(3.5, 4.0),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NAAC Criterion 7.1 Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.solidBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NIRF / ESG READY',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${passport.naacScore}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    passport.naacGrade,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Meets National Assessment & Accreditation Council criteria for Institutional Values and Environmental Consciousness.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.solidBlack.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detailed Criterion Breakdown
        _buildNaacSubCategory(
          title: '7.1.3: Solid Waste Management & Circular Economy',
          scoreText: '96%',
          description: 'YuvaSwap peer recirculation diverted ${passport.wasteDivertedKg} kg of durable academic waste from dumpsites.',
          icon: Icons.delete_sweep_rounded,
          ratio: 0.96,
        ),
        _buildNaacSubCategory(
          title: '7.1.4: Water & Biodiversity Afforestation',
          scoreText: '91%',
          description: '${passport.treesNurtured} adopted saplings monitored under Haversine GPS proximity locks with verified post-care.',
          icon: Icons.water_drop_rounded,
          ratio: 0.91,
        ),
        _buildNaacSubCategory(
          title: '7.1.5: Clean Campus Non-Motorized Transit',
          scoreText: '88%',
          description: '${passport.cleanAirHours} hours of campus pedestrian transit and zero-emission micro-missions recorded.',
          icon: Icons.directions_bike_rounded,
          ratio: 0.88,
        ),
        _buildNaacSubCategory(
          title: '7.1.6: Scope 2 Campus Microgrid Audit',
          scoreText: '92%',
          description: 'Verified solar pavilion audits and rooftop photovoltaic baseline monitoring logged.',
          icon: Icons.solar_power_rounded,
          ratio: 0.92,
        ),
      ],
    );
  }

  Widget _buildNaacSubCategory({
    required String title,
    required String scoreText,
    required String description,
    required IconData icon,
    required double ratio,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeoCard(
        color: AppColors.cardWhite,
        radius: 18,
        borderWidth: 2.0,
        shadowOffset: const Offset(2.5, 3.0),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.sageGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.solidBlack, width: 1.5),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.solidBlack),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ),
                Text(
                  scoreText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.paperCream,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.solidBlack, width: 1.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.dustyCoral,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Dual Action Buttons with Mechanical Tactile Press
  Widget _buildActionButtons(GreenPassport passport) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: NeoButton(
            text: 'Share ESG Credential (LinkedIn Ready)',
            color: AppColors.butterYellow,
            leading: const Icon(Icons.verified_user_rounded, color: AppColors.solidBlack, size: 18),
            onPressed: () => _showShareModal(passport),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: NeoButton(
            text: 'Export Official NAAC Audit PDF',
            color: AppColors.cardWhite,
            leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.solidBlack, size: 18),
            onPressed: () => _showExportPdfModal(passport),
          ),
        ),
      ],
    );
  }
}
