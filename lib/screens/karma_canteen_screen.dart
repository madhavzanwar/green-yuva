import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reward_item.dart';
import '../models/user.dart';
import '../services/reward_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class KarmaCanteenScreen extends StatefulWidget {
  const KarmaCanteenScreen({super.key});

  @override
  State<KarmaCanteenScreen> createState() => _KarmaCanteenScreenState();
}

class _KarmaCanteenScreenState extends State<KarmaCanteenScreen> {
  final RewardService _rewardService = RewardService();
  final UserService _userService = UserService();

  AppUser? _user;
  List<RedeemedVoucher> _vouchers = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isRedeeming = false;

  final List<String> _categories = [
    'All',
    'Canteen',
    'YuvaSwap',
    'Campus Green',
    'Mobility',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    AppUser? user = _user;
    List<RedeemedVoucher> vouchers = _vouchers;
    try {
      user = await _userService.getLocalUser();
      vouchers = await _rewardService.getRedeemedVouchers();
    } catch (e) {
      debugPrint('Karma canteen load failed: $e');
    }
    if (mounted) {
      setState(() {
        _user = user;
        _vouchers = vouchers;
        _isLoading = false;
      });
    }
  }

  List<RewardItem> get _filteredRewards {
    if (_selectedCategory == 'All') {
      return _rewardService.availableRewards;
    }
    return _rewardService.availableRewards
        .where((r) => r.category == _selectedCategory)
        .toList();
  }

  Future<void> _handleRedeem(RewardItem perk) async {
    if (_user == null || _isRedeeming) return;
    if (_user!.points < perk.karmaCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${perk.karmaCost - _user!.points} more Karma to redeem this perk!',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.solidBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: perk.accentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.5),
              ),
              child: Icon(perk.icon, color: AppColors.solidBlack, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Redeem Perk?',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.solidBlack),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(perk.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.solidBlack)),
            const SizedBox(height: 10),
            Text(
              'This will deduct ${perk.karmaCost} Karma Coins from your balance and generate an official GreenYuva Campus Voucher.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.solidBlack.withValues(alpha: 0.8), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.butterYellow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.solidBlack, size: 18),
                  const SizedBox(width: 8),
                  Text('Cost: ${perk.karmaCost} Karma Coins', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.solidBlack)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dustyCoral,
              foregroundColor: AppColors.solidBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.solidBlack, width: 1.5)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm & Claim', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _user != null && !_isRedeeming) {
      _isRedeeming = true; // prevent double-spend from rapid repeated taps
      try {
        final voucher = await _rewardService.redeemReward(_user!, perk);
        if (voucher != null) {
          await _loadData();
          if (mounted) {
            _showVoucherClaimedDialog(voucher);
          }
        }
      } finally {
        _isRedeeming = false;
      }
    }
  }

  void _showVoucherClaimedDialog(RedeemedVoucher voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.sageGreen, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.solidBlack, width: 1.5)),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.solidBlack, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Voucher Unlocked!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.solidBlack)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(voucher.rewardTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.solidBlack)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paperCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: Column(
                children: [
                  Text('CLAIM CODE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedText)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(voucher.voucherCode, style: GoogleFonts.spaceMono(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.solidBlack)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.solidBlack),
                        tooltip: 'Copy code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: voucher.voucherCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher code copied!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('How to redeem:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.solidBlack)),
            const SizedBox(height: 4),
            Text(voucher.instructions, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.solidBlack.withValues(alpha: 0.8), height: 1.4)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.butterYellow,
              foregroundColor: AppColors.solidBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.solidBlack, width: 1.5)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showMyVouchersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paperCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.solidBlack, width: 2.0),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
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
                      Text(
                        'My Campus Vouchers',
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.solidBlack),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.butterYellow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        ),
                        child: Text(
                          '${_vouchers.length} Total',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.solidBlack),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _vouchers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.confirmation_number_outlined, size: 56, color: AppColors.mutedText),
                                const SizedBox(height: 12),
                                Text('No vouchers redeemed yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.solidBlack)),
                                const SizedBox(height: 6),
                                Text('Redeem canteen drinks, cycle passes & book discounts above!', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.mutedText)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _vouchers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final v = _vouchers[index];
                              return NeoCard(
                                color: AppColors.cardWhite,
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(v.rewardTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.solidBlack)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: AppColors.sageGreen, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.solidBlack, width: 1.2)),
                                          child: Text('${v.karmaSpent} Karma', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: AppColors.paperCream, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.solidBlack, width: 1.5)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(v.voucherCode, style: GoogleFonts.spaceMono(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.solidBlack)),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: v.voucherCode));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 1)));
                                            },
                                            child: const Row(
                                              children: [
                                                Icon(Icons.copy_rounded, size: 14, color: AppColors.solidBlack),
                                                SizedBox(width: 4),
                                                Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(v.instructions, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.solidBlack.withValues(alpha: 0.75), height: 1.3)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaperGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.solidBlack, width: 2)),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.solidBlack, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Karma Canteen & Perks', style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.solidBlack)),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.solidBlack, width: 2)),
                    child: const Icon(Icons.confirmation_number_rounded, color: AppColors.solidBlack, size: 20),
                  ),
                  onPressed: _showMyVouchersSheet,
                ),
                if (_vouchers.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.dustyCoral, shape: BoxShape.circle, border: Border.all(color: AppColors.solidBlack, width: 1.5)),
                      child: Text('${_vouchers.length}', style: const TextStyle(color: AppColors.solidBlack, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.solidBlack))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.solidBlack,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    NeoCard(
                      color: AppColors.butterYellow,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.solidBlack, width: 2.0)),
                                child: const Icon(Icons.stars_rounded, color: AppColors.solidBlack, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CAMPUS ECO-WALLET',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.solidBlack.withValues(alpha: 0.7)),
                                  ),
                                  Text(
                                    '${_user?.points ?? 0} Karma Coins',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.solidBlack),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Convert your sustainability actions into canteen drinks, bike passes, book credits & campus tree planting!',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.solidBlack.withValues(alpha: 0.85), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.dustyCoral : AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                                  boxShadow: isSelected ? const [BoxShadow(color: AppColors.solidBlack, offset: Offset(2, 2), blurRadius: 0)] : null,
                                ),
                                child: Text(category, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: AppColors.solidBlack)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._filteredRewards.map((perk) {
                      final hasEnough = (_user?.points ?? 0) >= perk.karmaCost;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NeoCard(
                          color: AppColors.cardWhite,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: perk.accentColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.solidBlack, width: 2.0)),
                                    child: Icon(perk.icon, color: AppColors.solidBlack, size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.paperCream, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.solidBlack, width: 1.2)),
                                          child: Text(perk.badgeLabel, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.solidBlack)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(perk.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.solidBlack, height: 1.25)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(perk.description, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.solidBlack.withValues(alpha: 0.8), height: 1.4)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.butterYellow, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.solidBlack, width: 1.8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stars_rounded, size: 16, color: AppColors.solidBlack),
                                        const SizedBox(width: 6),
                                        Text('${perk.karmaCost} Karma', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.solidBlack)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasEnough ? AppColors.sageGreen : AppColors.paperCream,
                                      foregroundColor: AppColors.solidBlack,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.solidBlack, width: 2.0)),
                                    ),
                                    onPressed: () => _handleRedeem(perk),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(hasEnough ? Icons.redeem_rounded : Icons.lock_outline_rounded, size: 16, color: AppColors.solidBlack),
                                        const SizedBox(width: 6),
                                        Text(hasEnough ? 'Redeem Perk' : 'Need ${perk.karmaCost - (_user?.points ?? 0)} more', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 120), // Padding for floating bottom navbar
                  ],
                ),
              ),
      ),
    );
  }
}
