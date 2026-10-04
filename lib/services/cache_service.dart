import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'greenyuva_cache_';
  static const Duration _defaultExpiry = Duration(minutes: 10);

  static Future<void> setData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': (expiry ?? _defaultExpiry).inMilliseconds,
      };

      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      print('Error setting cache data: $e');
    }
  }

  static Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_cachePrefix$key');

      if (cachedString == null) return null;

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = (cacheData['timestamp'] as num?)?.toInt() ?? 0;
      final expiry = (cacheData['expiry'] as num?)?.toInt() ?? _defaultExpiry.inMilliseconds;

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;

      if (age > expiry) {
        await prefs.remove('$_cachePrefix$key');
        return null;
      }

      return cacheData['data'];
    } catch (e) {
      print('Error getting cache data: $e');
      return null;
    }
  }

  static Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
    } catch (e) {
      print('Error removing cache data: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  static Future<bool> hasData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_cachePrefix$key');
    } catch (e) {
      print('Error checking cache data: $e');
      return false;
    }
  }

  static Future<DateTime?> getLastUpdated(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_cachePrefix$key');

      if (cachedString == null) return null;

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = (cacheData['timestamp'] as num?)?.toInt();
      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting last updated: $e');
      return null;
    }
  }
}