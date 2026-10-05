class GreenCommuteData {
  final int stepsToday;
  final int dailyGoal;
  final int streakDays;
  final DateTime lastActiveDate;
  final int claimedKarmaCoins;
  final bool isInsideCampus;
  final double distanceFromCampusMeters;
  final String campusName;

  const GreenCommuteData({
    required this.stepsToday,
    this.dailyGoal = 3000,
    required this.streakDays,
    required this.lastActiveDate,
    required this.claimedKarmaCoins,
    required this.isInsideCampus,
    required this.distanceFromCampusMeters,
    required this.campusName,
  });

  /// Every 1,500 campus walking steps equates to ~1 km of non-motorized mobility
  double get distanceKm => stepsToday / 1500.0;

  /// Each km offsets 0.12 kg CO2e compared to an internal combustion two-wheeler
  double get co2SavedKg => distanceKm * 0.12;

  /// Grams of CO2e avoided
  double get co2SavedGrams => co2SavedKg * 1000.0;

  /// Tailpipe petrol fuel avoided (assuming 35 km/L on short cold-start campus trips)
  double get petrolSavedLiters => distanceKm * 0.035;

  /// Typical campus micro-trips (hostels <-> departments <-> canteens are ~800m)
  double get microTripsReplaced => distanceKm / 0.8;

  /// Students earn 1 Karma Coin for every 500 green steps
  int get totalKarmaEligible => stepsToday ~/ 500;

  /// Karma coins ready to be claimed to user wallet
  int get unclaimedKarma => (totalKarmaEligible - claimedKarmaCoins).clamp(0, 9999);

  /// Progress towards daily green commute goal (0.0 to 1.0)
  double get progressFraction => (stepsToday / dailyGoal).clamp(0.0, 1.0);

  GreenCommuteData copyWith({
    int? stepsToday,
    int? dailyGoal,
    int? streakDays,
    DateTime? lastActiveDate,
    int? claimedKarmaCoins,
    bool? isInsideCampus,
    double? distanceFromCampusMeters,
    String? campusName,
  }) {
    return GreenCommuteData(
      stepsToday: stepsToday ?? this.stepsToday,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      claimedKarmaCoins: claimedKarmaCoins ?? this.claimedKarmaCoins,
      isInsideCampus: isInsideCampus ?? this.isInsideCampus,
      distanceFromCampusMeters: distanceFromCampusMeters ?? this.distanceFromCampusMeters,
      campusName: campusName ?? this.campusName,
    );
  }
}
