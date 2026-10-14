import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String _getEnvVar(String key) {
    try {
      final dotenvValue = dotenv.env[key];
      if (dotenvValue != null && dotenvValue.isNotEmpty) {
        return dotenvValue;
      }
    } catch (_) {}
    // Fallback for builds that don't bundle a .env file:
    //   flutter build apk --dart-define=GEMINI_API_KEY=... (one per key)
    return _compileTimeEnv[key] ?? '';
  }

  static const Map<String, String> _compileTimeEnv = {
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
    'NEWS_API_KEY': String.fromEnvironment('NEWS_API_KEY'),
    'GNEWS_API_KEY': String.fromEnvironment('GNEWS_API_KEY'),
    'GOOGLE_MAPS_API_KEY': String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    'GEMINI_API_KEY': String.fromEnvironment('GEMINI_API_KEY'),
    'FIREBASE_WEB_API_KEY': String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    'FIREBASE_ANDROID_API_KEY': String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
  };

  static String get supabaseUrl => _getEnvVar('SUPABASE_URL');
  static String get supabaseAnonKey => _getEnvVar('SUPABASE_ANON_KEY');
  static bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get newsApiKey => _getEnvVar('NEWS_API_KEY');
  static String get gNewsApiKey => _getEnvVar('GNEWS_API_KEY');
  static bool get enableNewsApi => false;
  static bool get isNewsApiConfigured => newsApiKey.isNotEmpty && gNewsApiKey.isNotEmpty;

  static String get googleMapsApiKey => _getEnvVar('GOOGLE_MAPS_API_KEY');
  static bool get isGoogleMapsConfigured => googleMapsApiKey.isNotEmpty;

  static String get geminiApiKey => _getEnvVar('GEMINI_API_KEY');
  static bool get isAIConfigured => geminiApiKey.isNotEmpty;

  static String get firebaseWebApiKey => _getEnvVar('FIREBASE_WEB_API_KEY');
  static String get firebaseAndroidApiKey => _getEnvVar('FIREBASE_ANDROID_API_KEY');
}