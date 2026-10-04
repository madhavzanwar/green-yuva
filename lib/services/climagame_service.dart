import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ecore.dart';
import '../services/user_service.dart';
import '../utils/ecore_setup.dart';

class ClimaGameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final UserService _userService = UserService();

  static List<Ecore> _cachedDefaultEcores = [];

  static List<Ecore> getDefaultCampusEcores() {
    if (_cachedDefaultEcores.isNotEmpty) return _cachedDefaultEcores;

    final missions = EcoreSetup.getAllMissions();

    _cachedDefaultEcores = [
      Ecore(
        id: 'pccoe_core',
        name: 'PCCOE Green Action Hub',
        latitude: 18.6517,
        longitude: 73.7616,
        missions: missions.take(4).toList(),
        totalPoints: 230,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'PCCOE — Pune',
        conqueredBySchoolId: 'pccoe',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Ecore(
        id: 'coep_core',
        name: 'COEP Hydro Action Hub',
        latitude: 18.5293,
        longitude: 73.8565,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 215,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'COEP Technological University — Pune',
        conqueredBySchoolId: 'coep',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Ecore(
        id: 'vit_pune_core',
        name: 'VIT Pune Solar Microgrid Hub',
        latitude: 18.4636,
        longitude: 73.8682,
        missions: missions.skip(2).take(4).toList(),
        totalPoints: 240,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'VIT Pune — Vishwakarma Institute of Technology',
        conqueredBySchoolId: 'vit_pune',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Ecore(
        id: 'pict_core',
        name: 'PICT Smart Campus E-Core',
        latitude: 18.4575,
        longitude: 73.8508,
        missions: missions.take(4).toList(),
        totalPoints: 225,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'PICT — Pune Institute of Computer Technology',
        conqueredBySchoolId: 'pict',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      Ecore(
        id: 'mit_wpu_core',
        name: 'MIT-WPU Eco-Resilience Hub',
        latitude: 18.5178,
        longitude: 73.8151,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 250,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'MIT-WPU — Pune',
        conqueredBySchoolId: 'mit_wpu',
        createdAt: DateTime.now().subtract(const Duration(days: 11)),
      ),
      Ecore(
        id: 'viit_core',
        name: 'VIIT Clean Stream Hub',
        latitude: 18.4601,
        longitude: 73.8824,
        missions: missions.skip(3).take(4).toList(),
        totalPoints: 210,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'VIIT — Pune',
        conqueredBySchoolId: 'viit',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Ecore(
        id: 'bits_core',
        name: 'BITS Pilani Renewable Station',
        latitude: 28.3639,
        longitude: 75.5870,
        missions: missions.skip(2).take(4).toList(),
        totalPoints: 260,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'BITS Pilani — Pilani',
        conqueredBySchoolId: 'bits_pilani',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Ecore(
        id: 'vit_core',
        name: 'VIT Vellore Clean Air Core',
        latitude: 12.9692,
        longitude: 79.1559,
        missions: missions.take(4).toList(),
        totalPoints: 270,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'VIT Vellore — Vellore',
        conqueredBySchoolId: 'vit_vellore',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];
    return _cachedDefaultEcores;
  }

  static Future<List<Ecore>> getVisibleEcores() async {
    try {
      print('🗺️ Fetching visible ecores from Firebase...');
      final snapshot = await _firestore
          .collection('ecores')
          .where('isActive', isEqualTo: true)
          .where('isDiscovered', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 3));

      final ecores = <Ecore>[];
      for (final doc in snapshot.docs) {
        try {
          final ecore = Ecore.fromMap(doc.id, doc.data());
          ecores.add(ecore);
        } catch (e) {
          print('❌ Error processing ecore ${doc.id}: $e');
        }
      }

      if (ecores.isNotEmpty) {
        print('✅ Found ${ecores.length} visible ecores from Firestore');
        return ecores;
      }
      return getDefaultCampusEcores();
    } catch (e) {
      print('ℹ️ Using default campus ecores: $e');
      return getDefaultCampusEcores();
    }
  }

  static Future<List<Ecore>> getAllEcores() async {
    return getVisibleEcores();
  }

  static Future<List<Ecore>> checkAndDiscoverEcores({
    required String userId,
    required double userLatitude,
    required double userLongitude,
    double proximityThreshold = 100.0,
  }) async {
    return [];
  }

  static Future<Ecore?> getEcoreById(String ecoreId) async {
    final list = await getVisibleEcores();
    try {
      return list.firstWhere((e) => e.id == ecoreId);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSchoolRankings() async {
    try {
      final snapshot = await _firestore.collection('schools').get();
      if (snapshot.docs.isNotEmpty) {
        final rankings = <Map<String, dynamic>>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          rankings.add({
            'schoolId': doc.id,
            'schoolName': data['name'] ?? doc.id,
            'conqueredEcores': data['conqueredCount'] ?? (10 - rankings.length),
          });
        }
        rankings.sort((a, b) => ((b['conqueredEcores'] as num?)?.toInt() ?? 0).compareTo((a['conqueredEcores'] as num?)?.toInt() ?? 0));
        return rankings;
      }
    } catch (_) {}

    return [
      {'schoolId': 'pccoe', 'schoolName': 'PCCOE — Pune', 'conqueredEcores': 14},
      {'schoolId': 'iit_bombay', 'schoolName': 'IIT Bombay — Mumbai', 'conqueredEcores': 11},
      {'schoolId': 'coep', 'schoolName': 'COEP Technological University — Pune', 'conqueredEcores': 9},
      {'schoolId': 'bits_pilani', 'schoolName': 'BITS Pilani — Pilani', 'conqueredEcores': 8},
      {'schoolId': 'vit_vellore', 'schoolName': 'VIT Vellore — Vellore', 'conqueredEcores': 7},
      {'schoolId': 'dtu', 'schoolName': 'Delhi Technological University (DTU)', 'conqueredEcores': 6},
      {'schoolId': 'nit_trichy', 'schoolName': 'NIT Trichy — Tiruchirappalli', 'conqueredEcores': 5},
      {'schoolId': 'manipal', 'schoolName': 'Manipal Institute of Technology', 'conqueredEcores': 4},
    ];
  }

  static Future<bool> canUserDoMission(String userId) async {
    return true; // Always allow participating in campus missions
  }

  static Future<int> getUserDailyMissionCount(String userId) async {
    try {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final doc = await _firestore.collection('users').doc(userId).collection('dailyMissions').doc(todayKey).get();
      if (doc.exists) {
        return doc.data()?['missionCount'] ?? 1;
      }
    } catch (_) {}
    return 1;
  }

  static Future<bool> completeMission({
    required String userId,
    required String userName,
    required String ecoreId,
    required String missionId,
    String? proofImageUrl,
  }) async {
    try {
      print('🎯 Completing mission $missionId in ecore $ecoreId');
      // Update local and remote points
      try {
        await _userService.addUserPoints(userId, 50);
        await _userService.addUserAction(userId);
      } catch (_) {}
      return true;
    } catch (e) {
      print('Error completing mission: $e');
      return true;
    }
  }

  static Future<Map<String, dynamic>> getGameStats() async {
    final ecores = await getVisibleEcores();
    final conquered = ecores.where((e) => e.isConquered).length;
    return {
      'totalEcores': ecores.length,
      'conqueredEcores': conquered,
      'inProgressEcores': ecores.length - conquered,
    };
  }
}
