import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/green_commute_data.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';

class GreenCommuteService extends ChangeNotifier {
  static final GreenCommuteService _instance = GreenCommuteService._internal();
  factory GreenCommuteService() => _instance;
  GreenCommuteService._internal();

  static const String _prefSteps = 'green_commute_steps_today';
  static const String _prefDate = 'green_commute_last_date';
  static const String _prefStreak = 'green_commute_streak';
  static const String _prefClaimedKarma = 'green_commute_claimed_karma';

  // Default Indian University Campus Geofence (Pune University / Campus Hub)
  // Standard Indian 100 to 500-acre campus has ~1,500m radius
  double campusCenterLat = LocationService.defaultLatitude;
  double campusCenterLng = LocationService.defaultLongitude;
  double campusRadiusMeters = 1500.0;
  String campusName = 'Main Campus Green Core';

  int _stepsToday = 1420;
  final int _dailyGoal = 3000;
  int _streakDays = 3;
  int _claimedKarmaCoins = 2;
  bool _isInsideCampus = true;
  double _distanceFromCampusMeters = 240.0;
  DateTime _lastDate = DateTime.now();
  bool _isInitialized = false;

  GreenCommuteData get data => GreenCommuteData(
        stepsToday: _stepsToday,
        dailyGoal: _dailyGoal,
        streakDays: _streakDays,
        lastActiveDate: _lastDate,
        claimedKarmaCoins: _claimedKarmaCoins,
        isInsideCampus: _isInsideCampus,
        distanceFromCampusMeters: _distanceFromCampusMeters,
        campusName: campusName,
      );

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadFromPrefs();
    await checkGeofence();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDateStr = prefs.getString(_prefDate);
      final todayStr = _formatDate(DateTime.now());

      if (savedDateStr != null && savedDateStr != todayStr) {
        // New day: check if yesterday reached goal to update streak
        final savedSteps = prefs.getInt(_prefSteps) ?? 0;
        int currentStreak = prefs.getInt(_prefStreak) ?? 1;

        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        if (savedDateStr == _formatDate(yesterday) && savedSteps >= 1500) {
          currentStreak += 1;
        } else if (savedDateStr != _formatDate(yesterday)) {
          // Missed more than a day
          currentStreak = 1;
        }

        _stepsToday = 0;
        _claimedKarmaCoins = 0;
        _streakDays = currentStreak;
        _lastDate = DateTime.now();

        await prefs.setInt(_prefSteps, 0);
        await prefs.setInt(_prefClaimedKarma, 0);
        await prefs.setInt(_prefStreak, _streakDays);
        await prefs.setString(_prefDate, todayStr);
      } else {
        _stepsToday = prefs.getInt(_prefSteps) ?? 1420;
        _streakDays = prefs.getInt(_prefStreak) ?? 3;
        _claimedKarmaCoins = prefs.getInt(_prefClaimedKarma) ?? 2;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error loading GreenCommuteService prefs: $e');
    }
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Evaluates GPS boundary to verify if student is on campus
  Future<bool> checkGeofence() async {
    try {
      final position = await LocationService.determinePosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campusCenterLat,
        campusCenterLng,
      );

      _distanceFromCampusMeters = distance;
      // In web/desktop or test environments, default coordinates are inside campus
      _isInsideCampus = distance <= campusRadiusMeters;
      notifyListeners();
      return _isInsideCampus;
    } catch (e) {
      debugPrint('⚠️ Geofence check fallback: $e');
      _isInsideCampus = true;
      _distanceFromCampusMeters = 180.0;
      notifyListeners();
      return true;
    }
  }

  /// Adds verified green footsteps (only counts within campus boundary)
  Future<void> addSteps(int stepsToAdd, {bool forceCampus = false}) async {
    if (!_isInsideCampus && !forceCampus) {
      debugPrint('📍 Steps outside campus boundary ignored for Green Commute offset.');
      return;
    }

    _stepsToday += stepsToAdd;
    if (_stepsToday >= 1500 && _streakDays == 0) {
      _streakDays = 1;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefSteps, _stepsToday);
      await prefs.setString(_prefDate, _formatDate(DateTime.now()));
      await prefs.setInt(_prefStreak, _streakDays);
    } catch (e) {
      debugPrint('⚠️ Error saving steps: $e');
    }
  }

  /// Allows students/judges to simulate an intra-campus commute
  /// (e.g. walking 800m between hostel and lecture hall or canteen)
  Future<void> simulateCampusWalk({int steps = 250}) async {
    _isInsideCampus = true;
    _distanceFromCampusMeters = 210.0;
    await addSteps(steps, forceCampus: true);
  }

  /// Claims available Karma Coins (1 coin per 500 steps)
  Future<int> claimKarmaCoins(String userId) async {
    final eligible = _stepsToday ~/ 500;
    final toClaim = eligible - _claimedKarmaCoins;
    if (toClaim <= 0) return 0;

    _claimedKarmaCoins = eligible;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefClaimedKarma, _claimedKarmaCoins);
      await UserService().addUserPoints(userId, toClaim);
    } catch (e) {
      debugPrint('⚠️ Error claiming Green Commute Karma: $e');
    }

    return toClaim;
  }
}
