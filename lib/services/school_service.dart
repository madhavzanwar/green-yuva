import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school.dart';

class SchoolService {
  final CollectionReference schoolsCollection = FirebaseFirestore.instance.collection('schools');
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  static List<School>? _cachedSchools;
  static DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static final List<School> _defaultIndianSchools = [
    School(id: 'pccoe', name: 'PCCOE — Pune', memberCount: 184),
    School(id: 'coep', name: 'COEP Technological University — Pune', memberCount: 245),
    School(id: 'vit_pune', name: 'VIT Pune — Vishwakarma Institute of Technology', memberCount: 210),
    School(id: 'pict', name: 'PICT — Pune Institute of Computer Technology', memberCount: 195),
    School(id: 'mit_wpu', name: 'MIT-WPU — Pune', memberCount: 220),
    School(id: 'viit', name: 'VIIT — Pune', memberCount: 165),
    School(id: 'bits_pilani', name: 'BITS Pilani — Pilani', memberCount: 280),
    School(id: 'vit_vellore', name: 'VIT Vellore — Vellore', memberCount: 320),
    School(id: 'iit_bombay', name: 'IIT Bombay — Mumbai', memberCount: 290),
    School(id: 'dtu', name: 'Delhi Technological University (DTU) — Delhi', memberCount: 215),
  ];

  Future<List<School>> getSchools() async {
    if (_cachedSchools != null && _lastCacheTime != null) {
      final timeSinceLastCache = DateTime.now().difference(_lastCacheTime!);
      if (timeSinceLastCache < _cacheDuration) {
        return _cachedSchools!;
      }
    }

    try {
      print('🔍 Fetching schools from Firestore...');
      final snapshot = await schoolsCollection.get();
      print('📊 Found ${snapshot.docs.length} school documents');

      // Always ensure the 6 Pune colleges are returned in order
      final List<School> resultSchools = List.from(_defaultIndianSchools);

      // If Firestore contains school documents with custom images or member counts, merge them
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final idx = resultSchools.indexWhere((s) => s.id == doc.id || s.name.toLowerCase() == (data['name'] ?? '').toString().toLowerCase());
          if (idx != -1) {
            resultSchools[idx] = School(
              id: resultSchools[idx].id,
              name: resultSchools[idx].name,
              imageUrl: data['imageUrl'] ?? resultSchools[idx].imageUrl,
              memberCount: data['memberCount'] ?? resultSchools[idx].memberCount,
            );
          }
        }
      }

      await _calculateMemberCounts(resultSchools);
      _cachedSchools = resultSchools;
      _lastCacheTime = DateTime.now();
      return resultSchools;
    } catch (e) {
      print('Error fetching schools: $e. Returning 6 Pune colleges.');
      _cachedSchools = _defaultIndianSchools;
      return _defaultIndianSchools;
    }
  }

  Future<void> _calculateMemberCounts(List<School> schools) async {
    try {
      print('👥 Calculating real member counts for ${schools.length} schools...');

      for (int i = 0; i < schools.length; i++) {
        final school = schools[i];

        final usersSnapshot = await usersCollection
            .where('joinedSchoolId', isEqualTo: school.id)
            .get();

        final memberCount = usersSnapshot.docs.length;
        print('🏫 ${school.name}: ${memberCount} members');

        schools[i] = School(
          id: school.id,
          name: school.name,
          imageUrl: school.imageUrl,
          memberCount: memberCount,
        );
      }

      print('✅ Member counts calculated successfully');
    } catch (e) {
      print('❌ Error calculating member counts: $e');

    }
  }

  Future<void> addSchool(School school) async {
    try {
      await schoolsCollection.doc(school.id).set(school.toMap());
      _cachedSchools = null;
      _lastCacheTime = null;
    } catch (e) {
      print('Error adding school: $e');
      rethrow;
    }
  }

  Future<School?> getSchoolById(String id) async {
    try {
      final doc = await schoolsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null || data.isEmpty) {
          return School(
            id: doc.id,
            name: doc.id,
            imageUrl: null,
            memberCount: 0,
          );
        }

        String schoolName = '';
        for (String fieldName in data.keys) {
          if (fieldName != 'imageUrl' && fieldName != 'createdAt' && fieldName != 'updatedAt' && fieldName != 'name') {
            schoolName = fieldName.replaceAll(':', '').trim();
            break;
          }
        }

        if (schoolName.isEmpty) {
          schoolName = data['name'] ?? doc.id;
        }

        final usersSnapshot = await usersCollection
            .where('joinedSchoolId', isEqualTo: id)
            .get();

        final memberCount = usersSnapshot.docs.length;

        return School(
          id: doc.id,
          name: schoolName,
          imageUrl: data['imageUrl'],
          memberCount: memberCount,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching school by ID: $e');
      rethrow;
    }
  }

  static void clearCache() {
    _cachedSchools = null;
    _lastCacheTime = null;
  }

  Future<void> updateSchoolData(String schoolId, String schoolName, String? imageUrl) async {
    try {
      await schoolsCollection.doc(schoolId).set({
        'name': schoolName,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ School data updated for: $schoolId');
    } catch (e) {
      print('❌ Error updating school data: $e');
      rethrow;
    }
  }

  Future<void> setupSchoolsFromFirestore() async {
    try {

      final schoolsSnapshot = await schoolsCollection.get();

      if (schoolsSnapshot.docs.isEmpty) {
        print('⚠️ No schools found in Firestore');
        return;
      }

      print('📋 Found ${schoolsSnapshot.docs.length} schools in Firestore');

      for (final doc in schoolsSnapshot.docs) {
        final data = doc.data();
        final schoolId = doc.id;

        String schoolName = '';
        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          for (String fieldName in dataMap.keys) {
            if (fieldName != 'imageUrl' && fieldName != 'createdAt' && fieldName != 'updatedAt' && fieldName != 'name') {
              schoolName = fieldName.replaceAll(':', '').trim();
              break;
            }
          }

          if (schoolName.isEmpty) {
            schoolName = dataMap['name'] ?? schoolId;
          }
        } else {
          schoolName = schoolId;
        }

        String? imageUrl;
        switch (schoolId) {
          case 'daegu-gongsan':
            imageUrl = 'assets/images/school1.png';
            break;
          case 'jungheung':
            imageUrl = 'assets/images/school2.png';
            break;
          case 'nam-samsung':
            imageUrl = 'assets/images/school3.png';
            break;
          case 'posan':
            imageUrl = 'assets/images/school4.png';
            break;
          case 'yangdong':
            imageUrl = 'assets/images/school5.png';
            break;
          default:
            imageUrl = null;
        }

        await schoolsCollection.doc(schoolId).set({
          'name': schoolName,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Updated school: $schoolId -> "$schoolName" (image: $imageUrl)');
      }

      print('✅ All schools updated with proper Firestore structure');
    } catch (e) {
      print('❌ Error setting up schools from Firestore: $e');
      rethrow;
    }
  }
}