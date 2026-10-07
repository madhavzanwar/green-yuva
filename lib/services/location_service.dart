import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Default campus coordinates (Pune University / Campus Hub)
  static const double defaultLatitude = 18.5204;
  static const double defaultLongitude = 73.8567;

  static Position getDefaultPosition() {
    return Position(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Tries to get the real device/browser location.
  /// Proactively requests permissions if not yet granted.
  /// Falls back to default campus coordinates if permission is denied, disabled, or times out.
  static Future<Position> determinePosition({
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    try {
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('⚠️ Location services are disabled. Using campus fallback.');
          return getDefaultPosition();
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied by user. Using campus fallback.');
          return getDefaultPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied forever. Using campus fallback.');
        return getDefaultPosition();
      }

      // Permission is granted, attempt to fetch position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
      );

      debugPrint('📍 Location acquired: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('⚠️ Error determining location ($e). Using campus fallback.');
      return getDefaultPosition();
    }
  }

  /// Request location permission explicitly from UI
  static Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Calculates geodesic distance in meters between two lat/long points
  static double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (_) {
      return 0.0;
    }
  }

  /// Formats meter distance into user-friendly text (e.g., '350 m away', '2.4 km away')
  static String formatDistance(double meters) {
    if (meters <= 0) return 'Nearby';
    if (meters < 1000) {
      return '${meters.round()}m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }
  }
}
