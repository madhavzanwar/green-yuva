import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  static AppUser? _currentLocalUser;

  Future<void> saveCurrentLocalUser(AppUser user) async {
    _currentLocalUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_id', user.id);
      await prefs.setString('local_user_firstName', user.firstName);
      await prefs.setString('local_user_lastName', user.lastName);
      await prefs.setInt('local_user_points', user.points);
      await prefs.setInt('local_user_actions', user.actions);
      await prefs.setInt('local_user_streak', user.streak);
      await prefs.setInt('local_user_weekPoints', user.weekPoints);
      await prefs.setInt('local_user_weekGoal', user.weekGoal);
      if (user.joinedSchoolId != null) {
        await prefs.setString('local_user_schoolId', user.joinedSchoolId!);
      }
    } catch (e) {
      print('⚠️ Error saving local user: $e');
    }
  }

  Future<AppUser?> getLocalUser({bool createIfNull = true}) async {
    if (_currentLocalUser != null) return _currentLocalUser!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('local_user_id');
      if (id != null) {
        _currentLocalUser = AppUser(
          id: id,
          firstName: prefs.getString('local_user_firstName') ?? 'Climate',
          lastName: prefs.getString('local_user_lastName') ?? 'Hero',
          joinedSchoolId: prefs.getString('local_user_schoolId'),
          points: prefs.getInt('local_user_points') ?? 100,
          savedPosts: [],
          likedPosts: [],
          profilePic: null,
          actions: prefs.getInt('local_user_actions') ?? 1,
          streak: prefs.getInt('local_user_streak') ?? 1,
          weekPoints: prefs.getInt('local_user_weekPoints') ?? 50,
          weekGoal: prefs.getInt('local_user_weekGoal') ?? 800,
        );
        return _currentLocalUser!;
      }
    } catch (e) {
      print('⚠️ Error reading local user: $e');
    }

    if (!createIfNull) return null;

    _currentLocalUser = AppUser(
      id: 'local_default',
      firstName: 'Climate',
      lastName: 'Hero',
      points: 120,
      savedPosts: [],
      likedPosts: [],
      profilePic: null,
      actions: 2,
      streak: 1,
      weekPoints: 60,
      weekGoal: 800,
    );
    return _currentLocalUser!;
  }

  Future<void> clearLocalUser() async {
    _currentLocalUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_user_id');
      await prefs.remove('local_user_firstName');
      await prefs.remove('local_user_lastName');
      await prefs.remove('local_user_schoolId');
      await prefs.remove('local_user_points');
      await prefs.remove('local_user_actions');
      await prefs.remove('local_user_streak');
      await prefs.remove('local_user_weekPoints');
      await prefs.remove('local_user_weekGoal');
      print('✅ UserService: Cleared local user session');
    } catch (e) {
      print('⚠️ Error clearing local user: $e');
    }
  }

  Future<AppUser?> getUserById(String id) async {
    try {
      final doc = await usersCollection.doc(id).get().timeout(const Duration(seconds: 2));
      if (doc.exists && doc.data() != null) {
        final user = AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        _currentLocalUser = user;
        return user;
      }
    } catch (e) {
      print('⚠️ Firestore getUserById skipped/failed: $e');
    }
    return getLocalUser();
  }

  Future<void> addUser(AppUser user) async {
    await saveCurrentLocalUser(user);
    try {
      await usersCollection.doc(user.id).set(user.toMap());
    } catch (e) {
      print('⚠️ Firestore addUser skipped/failed: $e');
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    await usersCollection.doc(userId).update({'points': points});
  }

  Future<void> addUserPoints(String userId, int pointsToAdd) async {
    if (pointsToAdd == 0) return;

    final isDeduction = pointsToAdd < 0;

    // Immediately persist to local user state so points are never lost offline
    try {
      final local = await getLocalUser();
      if (local != null) {
        final updatedLocal = local.copyWith(
          points: (local.points + pointsToAdd).clamp(0, 9999999),
          // Do not penalize weekly action target when spending Karma Coins on perks
          weekPoints: isDeduction ? local.weekPoints : (local.weekPoints + pointsToAdd),
        );
        await saveCurrentLocalUser(updatedLocal);
        print('✅ UserService: Updated local points to ${updatedLocal.points} (${pointsToAdd >= 0 ? "+$pointsToAdd" : "$pointsToAdd"})');
      }
    } catch (e) {
      print('⚠️ UserService local points update error: $e');
    }

    // Also attempt to update Firestore if online
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final currentPoints = (userData['points'] as num?)?.toInt() ?? 0;
        final newPoints = (currentPoints + pointsToAdd).clamp(0, 9999999);

        final updates = <String, dynamic>{
          'points': newPoints,
        };

        if (!isDeduction) {
          final now = DateTime.now();
          final dayKey = 'points_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
          final currentDayPoints = (userData[dayKey] as num?)?.toInt() ?? 0;
          updates[dayKey] = currentDayPoints + pointsToAdd;

          final monthKey = 'points_${now.year}_${now.month.toString().padLeft(2, '0')}';
          final currentMonthPoints = (userData[monthKey] as num?)?.toInt() ?? 0;
          updates[monthKey] = currentMonthPoints + pointsToAdd;

          await usersCollection.doc(userId).update(updates);

          final newWeekPoints = await _calculateWeeklyPoints(userId, now);
          await usersCollection.doc(userId).update({
            'weekPoints': newWeekPoints,
          });
        } else {
          // Deducting points for rewards: only update wallet points
          await usersCollection.doc(userId).update(updates);
        }

        print('✅ UserService: Synced $pointsToAdd points to Firestore user $userId');
      }
    } catch (e) {
      print('ℹ️ Firestore addUserPoints skipped or offline: $e');
    }
  }

  Future<int> _calculateWeeklyPoints(String userId, DateTime referenceDate) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return 0;

      final userData = doc.data() as Map<String, dynamic>;
      int weeklyTotal = 0;

      for (int i = 0; i < 7; i++) {
        final date = referenceDate.subtract(Duration(days: i));
        final dayKey = 'points_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
        weeklyTotal += ((userData[dayKey] as num?)?.toInt() ?? 0);
      }

      return weeklyTotal;
    } catch (e) {
      print('❌ Error calculating weekly points: $e');
      return 0;
    }
  }

  Future<int> _calculateMonthlyPoints(String userId, DateTime referenceDate) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return 0;

      final userData = doc.data() as Map<String, dynamic>;
      int monthlyTotal = 0;

      final firstDayOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
      final lastDayOfMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0);

      for (int day = 1; day <= lastDayOfMonth.day; day++) {
        final date = DateTime(referenceDate.year, referenceDate.month, day);
        final dayKey = 'points_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
        monthlyTotal += ((userData[dayKey] as num?)?.toInt() ?? 0);
      }

      return monthlyTotal;
    } catch (e) {
      print('❌ Error calculating monthly points: $e');
      return 0;
    }
  }

  Future<int> getDailyPoints(String userId, DateTime date) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return 0;

      final userData = doc.data() as Map<String, dynamic>;
      final dayKey = 'points_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';

      return (userData[dayKey] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('❌ Error getting daily points: $e');
      return 0;
    }
  }

  Future<void> refreshWeeklyPointsForAllUsers() async {
    try {
      print('🔄 UserService: Refreshing weekly points for all users...');

      final snapshot = await usersCollection.get();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final userId = doc.id;
          final newWeekPoints = await _calculateWeeklyPoints(userId, DateTime.now());

          await usersCollection.doc(userId).update({
            'weekPoints': newWeekPoints,
          });

          updatedCount++;
          print('✅ Updated weekly points for user $userId: $newWeekPoints');
        } catch (e) {
          print('❌ Error updating weekly points for user ${doc.id}: $e');
        }
      }

      print('🎉 UserService: Successfully refreshed weekly points for $updatedCount users');
    } catch (e) {
      print('❌ Error refreshing weekly points: $e');
    }
  }

  Future<int> getWeeklyPoints(String userId) async {
    return await _calculateWeeklyPoints(userId, DateTime.now());
  }

  Future<int> getMonthlyPoints(String userId) async {
    return await _calculateMonthlyPoints(userId, DateTime.now());
  }

  Future<int> getWeeklyPointsForDate(String userId, DateTime endDate) async {
    return await _calculateWeeklyPoints(userId, endDate);
  }

  Future<int> getMonthlyPointsForDate(String userId, DateTime date) async {
    return await _calculateMonthlyPoints(userId, date);
  }

  Future<List<Map<String, dynamic>>> getDailyPointsHistory(String userId, int days) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return [];

      final userData = doc.data() as Map<String, dynamic>;
      final dailyHistory = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayKey = 'points_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
        final points = userData[dayKey] ?? 0;

        dailyHistory.add({
          'date': date,
          'points': points,
          'label': '${date.month}/${date.day}',
        });
      }

      return dailyHistory;
    } catch (e) {
      print('❌ Error getting daily points history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserHistoricalPoints(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return [];

      final userData = doc.data() as Map<String, dynamic>;
      final historicalPoints = <Map<String, dynamic>>[];

      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = 'points_${month.year}_${month.month.toString().padLeft(2, '0')}';

        final monthPoints = userData[monthKey] ?? 0;
        historicalPoints.add({
          'month': month,
          'points': monthPoints,
          'label': '${month.month}/${month.year}',
        });
      }

      return historicalPoints;
    } catch (e) {
      print('❌ Error getting user historical points: $e');
      return [];
    }
  }

  Future<void> updateUserStreakFromDailyActivity(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return;

      final userData = doc.data() as Map<String, dynamic>;
      final now = DateTime.now();
      int currentStreak = (userData['streak'] as num?)?.toInt() ?? 0;

      final today = DateTime(now.year, now.month, now.day);
      final dayKey = 'points_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
      final todayPoints = (userData[dayKey] as num?)?.toInt() ?? 0;

      if (todayPoints > 0) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey = 'points_${yesterday.year}_${yesterday.month.toString().padLeft(2, '0')}_${yesterday.day.toString().padLeft(2, '0')}';
        final yesterdayPoints = (userData[yesterdayKey] as num?)?.toInt() ?? 0;

        if (yesterdayPoints > 0) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      } else {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey = 'points_${yesterday.year}_${yesterday.month.toString().padLeft(2, '0')}_${yesterday.day.toString().padLeft(2, '0')}';
        final yesterdayPoints = (userData[yesterdayKey] as num?)?.toInt() ?? 0;

        if (yesterdayPoints == 0) {
          currentStreak = 0;
        }
      }

      await usersCollection.doc(userId).update({'streak': currentStreak});
      print('✅ UserService: Updated streak for user $userId to $currentStreak days');
    } catch (e) {
      print('❌ Error updating user streak: $e');
    }
  }

  Future<void> updateUserActions(String userId, int actions) async {
    await usersCollection.doc(userId).update({'actions': actions});
  }

  Future<void> addUserAction(String userId) async {
    try {
      final local = await getLocalUser();
      if (local != null) {
        final updatedLocal = local.copyWith(actions: local.actions + 1);
        await saveCurrentLocalUser(updatedLocal);
      }
    } catch (_) {}

    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        final currentActions = (doc.data() as Map<String, dynamic>)['actions'] ?? 0;
        await usersCollection.doc(userId).update({'actions': currentActions + 1});
      }
    } catch (_) {}
  }

  Future<void> updateUserStreak(String userId, int streak) async {
    await usersCollection.doc(userId).update({'streak': streak});
  }

  Future<void> updateWeekPoints(String userId, int weekPoints) async {
    await usersCollection.doc(userId).update({'weekPoints': weekPoints});
  }

  Future<void> addWeekPoints(String userId, int pointsToAdd) async {

    await addUserPoints(userId, pointsToAdd);
  }

  Future<void> joinSchool(String userId, String schoolId) async {
    await usersCollection.doc(userId).update({'joinedSchoolId': schoolId});
  }

  Future<void> updateUserProfilePic(String userId, String profilePicUrl) async {
    await usersCollection.doc(userId).update({'profilePic': profilePicUrl});
  }

  Future<void> ensureDummyUsersExist() async {
    try {
      print('🔍 UserService: Checking if dummy users exist...');
      final snapshot = await usersCollection.get();

      if (snapshot.docs.length < 3) {
        print('📝 UserService: Not enough users found. Please add users directly to Firebase Firestore.');
        print('📝 UserService: You can add users through the Firebase Console or create them programmatically.');
      } else {
        print('✅ UserService: Sufficient users already exist in Firebase');
      }
    } catch (e) {
      print('❌ UserService: Error checking users: $e');
      rethrow;
    }
  }
}