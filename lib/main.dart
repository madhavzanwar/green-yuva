import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'utils/google_maps_loader.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/climasights_screen.dart';
import 'screens/quiz_detail_screen.dart';
import 'screens/profile_picture_upload_screen.dart';
import 'screens/climagame_test_screen.dart';
import 'models/quiz.dart';
import 'theme/app_theme.dart';
import 'screens/yuvaswap_screen.dart';
import 'utils/supabase_config.dart';
import 'utils/env_config.dart';
import 'utils/transitions.dart';
import 'utils/memory_optimizer.dart';
import 'utils/performance_optimizer.dart';
import 'utils/android_optimizer.dart';
import 'utils/performance_monitor.dart';
import 'utils/android_map_optimizer.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.instance.init();

  FlutterError.onError = (FlutterErrorDetails details) {
    print('🚨 Flutter Error: ${details.exception}');
    print('🚨 Stack trace: ${details.stack}');
  };

  if (!kIsWeb) {
    try {
      ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler('error', (ByteData? data) async {
        print('🚨 Platform Error Handler');
        return null;
      });
      MemoryOptimizer.initialize();
      PerformanceOptimizer.initialize();
      AndroidOptimizer.initialize();
      AndroidMapOptimizer.initialize();
      PerformanceMonitor.startMonitoring();
    } catch (e) {
      print('⚠️ Platform optimizer warning: $e');
    }
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    try {
      await dotenv.load();
    } catch (e2) {}
  }

  if (kIsWeb && EnvConfig.isGoogleMapsConfigured) {
    try {
      initGoogleMapsWeb(EnvConfig.googleMapsApiKey);
    } catch (e) {
      print('⚠️ Google Maps loader warning: $e');
    }
  }

  try {
    if (EnvConfig.isSupabaseConfigured) {
      await SupabaseConfig.initialize();
    }
  } catch (e) {

  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('⚠️ Firebase initialization skipped or failed: $e');
  }

  runApp(const GreenYuvaApp());

}

class GreenYuvaApp extends StatelessWidget {
  const GreenYuvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Green Yuva',
          locale: Locale(LanguageService.instance.currentLanguageCode),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return AppTransitions.fadeTransition(SplashScreen());
          case '/auth':
            return AppTransitions.slideFromRight(AuthScreen());
          case '/home':
            return AppTransitions.slideFromRight(MainScreen());
          case '/yuvaswap':
            return AppTransitions.slideFromRight(const YuvaSwapScreen());
          case '/quiz-detail':
            final args = settings.arguments;
            Widget quizScreen;
            if (args is Map<String, dynamic>) {
              quizScreen = QuizDetailScreen(
                quiz: args['quiz'],
                attempt: args['attempt'],
                user: args['user'],
              );
            } else if (args is Quiz) {
              quizScreen = QuizDetailScreen(quiz: args);
            } else {
              quizScreen = Scaffold(
                appBar: AppBar(title: Text('Error')),
                body: Center(child: Text('Invalid quiz data')),
              );
            }
            return AppTransitions.cardTransition(quizScreen);
          case '/profile-picture-upload':
            final args = settings.arguments;
            Widget uploadScreen;
            if (args is Map<String, dynamic>) {
              uploadScreen = ProfilePictureUploadScreen(
                user: args['user'],
                isFromRegistration: args['isFromRegistration'] ?? false,
              );
            } else {
              uploadScreen = Scaffold(
                appBar: AppBar(title: Text('Error')),
                body: Center(child: Text('Invalid user data')),
              );
            }
            return AppTransitions.modalTransition(uploadScreen);
          case '/climasights':
            final args = settings.arguments;
            Widget climasightsScreen;
            if (args is Map<String, dynamic> && args['user'] != null) {
              climasightsScreen = ClimaSightsScreen(user: args['user']);
            } else {
              climasightsScreen = Scaffold(
                appBar: AppBar(title: Text('Error')),
                body: Center(child: Text('User data required')),
              );
            }
            return AppTransitions.slideFromBottom(climasightsScreen);
          case '/climagame-test':
            return AppTransitions.slideFromRight(ClimaGameTestScreen());
          default:
            return AppTransitions.fadeTransition(SplashScreen());
        }
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF0FDF4),
                Color(0xFFF0F9FF),
                Color(0xFFFDFBF7),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: child!,
        );
      },
    );
      },
    );
  }
}
