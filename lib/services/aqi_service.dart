import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class CityHubInfo {
  final String name;
  final String state;
  final double latitude;
  final double longitude;
  final int fallbackAqi;
  final double fallbackPm25;
  final double fallbackPm10;
  final String fallbackAdvisory;

  const CityHubInfo({
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.fallbackAqi,
    required this.fallbackPm25,
    required this.fallbackPm10,
    required this.fallbackAdvisory,
  });
}

class CityAqiData {
  final String cityName;
  final String state;
  final int aqi;
  final double pm25;
  final double pm10;
  final String status;
  final String advisory;
  final DateTime lastUpdated;
  final bool isLive;

  const CityAqiData({
    required this.cityName,
    required this.state,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.status,
    required this.advisory,
    required this.lastUpdated,
    this.isLive = false,
  });

  /// Neo-Brutalist color-coded AQI badge:
  /// Good (0-100): Mint (sageGreen)
  /// Moderate (101-200): Yellow (butterYellow)
  /// Severe (201+): Coral (dustyCoral)
  Color get badgeColor {
    if (aqi <= 100) return AppColors.sageGreen;
    if (aqi <= 200) return AppColors.butterYellow;
    return AppColors.dustyCoral;
  }

  Color get textColor => AppColors.solidBlack;

  String get categoryLabel {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }

  IconData get statusIcon {
    if (aqi <= 100) return Icons.sentiment_satisfied_alt_rounded;
    if (aqi <= 200) return Icons.sentiment_neutral_rounded;
    return Icons.masks_rounded;
  }
}

class AqiService {
  static final AqiService _instance = AqiService._internal();
  factory AqiService() => _instance;
  AqiService._internal();

  static const String _cityPrefKey = 'greenyuva_selected_city';

  static const List<CityHubInfo> supportedCities = [
    CityHubInfo(
      name: 'Pune',
      state: 'Maharashtra',
      latitude: 18.5204,
      longitude: 73.8567,
      fallbackAqi: 88,
      fallbackPm25: 29.4,
      fallbackPm10: 64.2,
      fallbackAdvisory: 'Campus air is moderately healthy. Ideal for outdoor sports, walking, and cycle commuting.',
    ),
    CityHubInfo(
      name: 'Mumbai',
      state: 'Maharashtra',
      latitude: 19.0760,
      longitude: 72.8777,
      fallbackAqi: 134,
      fallbackPm25: 48.6,
      fallbackPm10: 102.5,
      fallbackAdvisory: 'Moderate coastal humidity and suspended dust. Sensitive students should limit prolonged strenuous workouts outdoors.',
    ),
    CityHubInfo(
      name: 'Delhi',
      state: 'Delhi NCR',
      latitude: 28.6139,
      longitude: 77.2090,
      fallbackAqi: 274,
      fallbackPm25: 142.0,
      fallbackPm10: 235.0,
      fallbackAdvisory: 'Severe particulate index. Wear N95 masks when commuting across campus and prefer indoor library study hubs.',
    ),
    CityHubInfo(
      name: 'Bengaluru',
      state: 'Karnataka',
      latitude: 12.9716,
      longitude: 77.5946,
      fallbackAqi: 64,
      fallbackPm25: 19.8,
      fallbackPm10: 42.1,
      fallbackAdvisory: 'Clean garden city air quality. Perfect day for campus plantation drives and active eco-mobility!',
    ),
    CityHubInfo(
      name: 'Chennai',
      state: 'Tamil Nadu',
      latitude: 13.0827,
      longitude: 80.2707,
      fallbackAqi: 76,
      fallbackPm25: 24.3,
      fallbackPm10: 55.0,
      fallbackAdvisory: 'Favorable sea-breeze dispersion keeps campus air fresh and within CPCB safe standards.',
    ),
  ];

  Future<String> getSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cityPrefKey) ?? 'Pune';
    } catch (_) {
      return 'Pune';
    }
  }

  Future<void> setSelectedCity(String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityPrefKey, cityName);
    } catch (e) {
      print('⚠️ Error saving selected city: $e');
    }
  }

  CityHubInfo getCityInfo(String cityName) {
    return supportedCities.firstWhere(
      (c) => c.name.toLowerCase() == cityName.toLowerCase(),
      orElse: () => supportedCities.first,
    );
  }

  /// Fetches live AQI from Open-Meteo Air Quality API with 4s timeout and graceful fallback
  Future<CityAqiData> fetchCityAqi(String cityName) async {
    final info = getCityInfo(cityName);
    try {
      final url = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${info.latitude}&longitude=${info.longitude}&current=us_aqi,pm2_5,pm10',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        if (current != null) {
          final usAqi = (current['us_aqi'] as num?)?.toInt();
          final rawPm25 = (current['pm2_5'] as num?)?.toDouble();
          final rawPm10 = (current['pm10'] as num?)?.toDouble();
          final pm25 = rawPm25 ?? info.fallbackPm25;
          final pm10 = rawPm10 ?? info.fallbackPm10;
          // Category bands in this app are Indian CPCB bands, so derive a CPCB
          // AQI from PM values (US AQI uses different breakpoints).
          final aqi = (rawPm25 != null || rawPm10 != null)
              ? _cpcbAqi(pm25, pm10)
              : (usAqi ?? info.fallbackAqi);

          String advisory = info.fallbackAdvisory;
          if (aqi <= 100) {
            advisory = 'Clean air in ${info.name}. Great day for campus cycling and outdoor green activities!';
          } else if (aqi <= 200) {
            advisory = 'Moderate air quality in ${info.name}. Sensitive individuals should pace outdoor exertion.';
          } else {
            advisory = 'Severe pollution alert in ${info.name}. Wear N95 masks on campus and use indoor green spaces.';
          }

          return CityAqiData(
            cityName: info.name,
            state: info.state,
            aqi: aqi,
            pm25: pm25,
            pm10: pm10,
            status: _getStatusText(aqi),
            advisory: advisory,
            lastUpdated: DateTime.now(),
            isLive: true,
          );
        }
      }
    } catch (e) {
      print('⚠️ Live AQI fetch note (using calibrated CPCB baseline for ${info.name}): $e');
    }

    // Return calibrated CPCB baseline
    return CityAqiData(
      cityName: info.name,
      state: info.state,
      aqi: info.fallbackAqi,
      pm25: info.fallbackPm25,
      pm10: info.fallbackPm10,
      status: _getStatusText(info.fallbackAqi),
      advisory: info.fallbackAdvisory,
      lastUpdated: DateTime.now(),
      isLive: false,
    );
  }

  /// CPCB AQI = max of PM2.5 and PM10 sub-indices (linear interpolation).
  static int _cpcbAqi(double pm25, double pm10) {
    const pm25Bp = [
      [0.0, 30.0, 0.0, 50.0],
      [30.0, 60.0, 51.0, 100.0],
      [60.0, 90.0, 101.0, 200.0],
      [90.0, 120.0, 201.0, 300.0],
      [120.0, 250.0, 301.0, 400.0],
      [250.0, 500.0, 401.0, 500.0],
    ];
    const pm10Bp = [
      [0.0, 50.0, 0.0, 50.0],
      [50.0, 100.0, 51.0, 100.0],
      [100.0, 250.0, 101.0, 200.0],
      [250.0, 350.0, 201.0, 300.0],
      [350.0, 430.0, 301.0, 400.0],
      [430.0, 510.0, 401.0, 500.0],
    ];
    double sub(double c, List<List<double>> bp) {
      if (c <= 0) return 0;
      for (final b in bp) {
        if (c <= b[1]) {
          return (b[3] - b[2]) / (b[1] - b[0]) * (c - b[0]) + b[2];
        }
      }
      return 500;
    }

    final a = sub(pm25, pm25Bp);
    final b = sub(pm10, pm10Bp);
    return (a > b ? a : b).round();
  }

  String _getStatusText(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }
}
