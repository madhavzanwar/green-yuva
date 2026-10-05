import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_item.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  static const String _vouchersPrefKey = 'greenyuva_redeemed_vouchers';

  final List<RewardItem> availableRewards = const [
    RewardItem(
      id: 'reward_samosa_tea_50',
      title: 'Afternoon Iced Lemon Tea & Samosa Combo',
      description: 'Redeem your Green Commute steps for a refreshing iced lemon tea and crispy vegetable samosa at the campus Karma Canteen. Zero tailpipe, zero guilt!',
      karmaCost: 50,
      icon: Icons.fastfood_rounded,
      category: 'Canteen',
      badgeLabel: 'Green Commute Perk',
      voucherInstructions: 'Present this digital voucher QR code at the Karma Canteen beverage counter between 12:00 PM and 6:00 PM.',
      accentColor: AppColors.butterYellow,
    ),
    RewardItem(
      id: 'reward_tea_100',
      title: 'Free Steel Tumbler Tea at Campus Canteen',
      description: 'Enjoy a freshly brewed tea or coffee at the college canteen in an eco-friendly reusable steel tumbler. Eliminates single-use paper cups!',
      karmaCost: 100,
      icon: Icons.coffee_rounded,
      category: 'Canteen',
      badgeLabel: 'Campus Canteen Partner',
      voucherInstructions: 'Present this digital voucher to the cashier at the Main Campus Canteen to redeem your beverage in a clean steel tumbler.',
      accentColor: AppColors.butterYellow,
    ),
    RewardItem(
      id: 'reward_cycle_150',
      title: '1-Day Free Campus EV/Cycle Pass',
      description: 'Zero-emission campus commute! Get unlimited unlocks for campus rental cycles and EV shuttle zones for 24 hours.',
      karmaCost: 150,
      icon: Icons.pedal_bike_rounded,
      category: 'Mobility',
      badgeLabel: 'Active Mobility',
      voucherInstructions: 'Scan this voucher QR code at the Campus Mobility Kiosk or show to the security coordinator.',
      accentColor: AppColors.dustyCoral,
    ),
    RewardItem(
      id: 'reward_book_250',
      title: '15% Off Eco-Textbooks on YuvaSwap',
      description: 'Get instant 15% discount credit and priority borrower-to-donor matching on peer-to-peer textbook barter.',
      karmaCost: 250,
      icon: Icons.menu_book_rounded,
      category: 'YuvaSwap',
      badgeLabel: 'Circular Barter Waiver',
      voucherInstructions: 'Enter this voucher code during any textbook exchange on YuvaSwap to claim your fee waiver.',
      accentColor: AppColors.skyBlue,
    ),
    RewardItem(
      id: 'reward_tote_350',
      title: 'Upcycled Green Yuva Canvas Tote Bag',
      description: 'Handcrafted durable tote bag made from upcycled campus canvas banners and textile scraps. Replaces 500+ plastic bags!',
      karmaCost: 350,
      icon: Icons.shopping_bag_rounded,
      category: 'Campus Green',
      badgeLabel: 'Eco-Merchandise',
      voucherInstructions: 'Show this voucher at the Green Yuva Eco-Desk (Student Activity Center Room 204) to collect your bag.',
      accentColor: AppColors.butterYellow,
    ),
    RewardItem(
      id: 'reward_tree_500',
      title: 'Name Plaque on a Sapling Planted by Green Yuva',
      description: 'Green Yuva will plant an indigenous tree sapling on campus with your engraved name plaque, GPS coordinates, and a digital impact certificate.',
      karmaCost: 500,
      icon: Icons.park_rounded,
      category: 'Campus Green',
      badgeLabel: 'Living Impact Legacy',
      voucherInstructions: 'Voucher registered! You will receive an invitation to the next weekend plantation drive with your tree GPS pin.',
      accentColor: AppColors.sageGreen,
    ),
  ];

  Future<List<RedeemedVoucher>> getRedeemedVouchers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_vouchersPrefKey);
      if (raw == null || raw.isEmpty) return [];
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => RedeemedVoucher.fromMap(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      print('⚠️ Error loading vouchers: $e');
      return [];
    }
  }

  Future<RedeemedVoucher?> redeemReward(AppUser user, RewardItem perk) async {
    if (user.points < perk.karmaCost) {
      return null;
    }

    // Deduct points
    final userService = UserService();
    await userService.addUserPoints(user.id, -perk.karmaCost);

    // Generate unique voucher code
    final rnd = Random();
    final code = 'GY-${perk.category.substring(0, min(perk.category.length, 3)).toUpperCase()}-${rnd.nextInt(9000) + 1000}';

    final voucher = RedeemedVoucher(
      id: 'vch_${DateTime.now().millisecondsSinceEpoch}',
      rewardId: perk.id,
      rewardTitle: perk.title,
      voucherCode: code,
      karmaSpent: perk.karmaCost,
      redeemedAt: DateTime.now(),
      instructions: perk.voucherInstructions,
    );

    // Persist voucher
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getRedeemedVouchers();
      existing.insert(0, voucher);
      final encoded = jsonEncode(existing.map((v) => v.toMap()).toList());
      await prefs.setString(_vouchersPrefKey, encoded);
    } catch (e) {
      print('⚠️ Error saving redeemed voucher: $e');
    }

    return voucher;
  }
}
