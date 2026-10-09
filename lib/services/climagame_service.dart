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
        name: 'PCCOE — Pimpri Chinchwad College of Engineering',
        latitude: 18.6517,
        longitude: 73.7616,
        missions: missions.take(4).toList(),
        totalPoints: 230,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'PCCOE — Akurdi/Nigdi, Pune',
        conqueredBySchoolId: 'pccoe',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Ecore(
        id: 'coep_core',
        name: 'COEP Technological University',
        latitude: 18.5293,
        longitude: 73.8565,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 215,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'COEP Tech University — Shivajinagar, Pune',
        conqueredBySchoolId: 'coep',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Ecore(
        id: 'vit_pune_core',
        name: 'VIT Pune — Vishwakarma Institute of Technology',
        latitude: 18.4636,
        longitude: 73.8682,
        missions: missions.skip(2).take(4).toList(),
        totalPoints: 240,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'VIT Pune — Bibwewadi, Pune',
        conqueredBySchoolId: 'vit_pune',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Ecore(
        id: 'pict_core',
        name: 'PICT — Pune Institute of Computer Technology',
        latitude: 18.4575,
        longitude: 73.8508,
        missions: missions.take(4).toList(),
        totalPoints: 225,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'PICT — Dhankawadi, Pune',
        conqueredBySchoolId: 'pict',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      Ecore(
        id: 'mit_wpu_core',
        name: 'MIT-WPU — World Peace University',
        latitude: 18.5178,
        longitude: 73.8151,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 250,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'MIT-WPU — Kothrud, Pune',
        conqueredBySchoolId: 'mit_wpu',
        createdAt: DateTime.now().subtract(const Duration(days: 11)),
      ),
      Ecore(
        id: 'sppu_core',
        name: 'SPPU — Savitribai Phule Pune University',
        latitude: 18.5529,
        longitude: 73.8262,
        missions: missions.take(4).toList(),
        totalPoints: 280,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'SPPU — Ganeshkhind, Pune',
        conqueredBySchoolId: 'sppu',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Ecore(
        id: 'fergusson_core',
        name: 'Fergusson College (Autonomous)',
        latitude: 18.5236,
        longitude: 73.8418,
        missions: missions.skip(2).take(4).toList(),
        totalPoints: 220,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'Fergusson College — FC Road, Pune',
        conqueredBySchoolId: 'fergusson',
        createdAt: DateTime.now().subtract(const Duration(days: 13)),
      ),
      Ecore(
        id: 'viit_core',
        name: 'VIIT — Vishwakarma Institute of Info Tech',
        latitude: 18.4601,
        longitude: 73.8824,
        missions: missions.skip(3).take(4).toList(),
        totalPoints: 210,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'VIIT — Kondhwa, Pune',
        conqueredBySchoolId: 'viit',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Ecore(
        id: 'symbiosis_core',
        name: 'Symbiosis International University',
        latitude: 18.5772,
        longitude: 73.9167,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 260,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'Symbiosis — Viman Nagar, Pune',
        conqueredBySchoolId: 'symbiosis',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Ecore(
        id: 'bvp_core',
        name: 'Bharati Vidyapeeth Deemed University',
        latitude: 18.4578,
        longitude: 73.8587,
        missions: missions.take(4).toList(),
        totalPoints: 235,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'Bharati Vidyapeeth — Katraj, Pune',
        conqueredBySchoolId: 'bvp',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      Ecore(
        id: 'dypatil_core',
        name: 'D.Y. Patil College of Engineering',
        latitude: 18.6448,
        longitude: 73.7588,
        missions: missions.skip(2).take(4).toList(),
        totalPoints: 225,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'DY Patil — Akurdi, Pune',
        conqueredBySchoolId: 'dypatil',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Ecore(
        id: 'cummins_core',
        name: 'MKSSS Cummins College of Engineering',
        latitude: 18.4899,
        longitude: 73.8174,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 245,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'Cummins College — Karve Nagar, Pune',
        conqueredBySchoolId: 'cummins',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Ecore(
        id: 'ait_core',
        name: 'Army Institute of Technology (AIT)',
        latitude: 18.6069,
        longitude: 73.8744,
        missions: missions.take(4).toList(),
        totalPoints: 230,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'AIT — Dighi, Pune',
        conqueredBySchoolId: 'ait',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Ecore(
        id: 'scoe_core',
        name: 'Sinhgad College of Engineering (SCOE)',
        latitude: 18.4655,
        longitude: 73.8370,
        missions: missions.skip(3).take(4).toList(),
        totalPoints: 215,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'SCOE — Vadgaon BK, Pune',
        conqueredBySchoolId: 'scoe',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Ecore(
        id: 'modern_core',
        name: 'Modern College of Arts, Science & Commerce',
        latitude: 18.5308,
        longitude: 73.8480,
        missions: missions.take(4).toList(),
        totalPoints: 210,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'Modern College — Shivajinagar, Pune',
        conqueredBySchoolId: 'modern',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Ecore(
        id: 'iitb_core',
        name: 'IIT Bombay — Indian Institute of Technology',
        latitude: 19.0760,
        longitude: 72.8777,
        missions: missions.take(4).toList(),
        totalPoints: 290,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'IIT Bombay — Powai, Mumbai',
        conqueredBySchoolId: 'iitb',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Ecore(
        id: 'vjti_core',
        name: 'VJTI — Veermata Jijabai Tech Institute',
        latitude: 19.0222,
        longitude: 72.8561,
        missions: missions.skip(1).take(4).toList(),
        totalPoints: 240,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'VJTI — Matunga, Mumbai',
        conqueredBySchoolId: 'vjti',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
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
        id: 'iitd_core',
        name: 'IIT Delhi — Clean Tech Hub',
        latitude: 28.5450,
        longitude: 77.1926,
        missions: missions.take(4).toList(),
        totalPoints: 285,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'IIT Delhi — Hauz Khas, New Delhi',
        conqueredBySchoolId: 'iitd',
        createdAt: DateTime.now().subtract(const Duration(days: 16)),
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
      Ecore(
        id: 'iisc_core',
        name: 'IISc Bangalore — Eco-Innovation Core',
        latitude: 13.0219,
        longitude: 77.5671,
        missions: missions.skip(3).take(4).toList(),
        totalPoints: 295,
        isActive: true,
        isDiscovered: true,
        conqueredBySchoolName: 'IISc — Malleshwaram, Bengaluru',
        conqueredBySchoolId: 'iisc',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
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
