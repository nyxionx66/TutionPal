import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/tution_class.dart';
import 'models/payment.dart';
import 'models/study_session.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TutionClassAdapter());
  Hive.registerAdapter(PaymentAdapter()); // Register Payment adapter
  Hive.registerAdapter(StudySessionAdapter()); // Register StudySession adapter

  // Open Hive boxes
  await Hive.openBox<TutionClass>('classes');
  await Hive.openBox<Payment>('payments'); // Open payments box
  await Hive.openBox<StudySession>('study_sessions'); // Open study sessions box

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize notification service in background
  try {
    NotificationService().initialize();
    print('Enhanced notification service initialized');
  } catch (e) {
    print('Notification service initialization error (ignored): $e');
    // Continue without notifications if there's an error
  }

  runApp(const TutionPalApp());
}

class TutionPalApp extends StatelessWidget {
  const TutionPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tution Pal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Modern color scheme implementation
        primarySwatch: MaterialColor(0xFF2A66F2, {
          50: const Color(0xFFE3F2FD),
          100: const Color(0xFFBBDEFB),
          200: const Color(0xFF90CAF9),
          300: const Color(0xFF64B5F6),
          400: const Color(0xFF42A5F5),
          500: const Color(0xFF2A66F2), // Primary color
          600: const Color(0xFF1E88E5),
          700: const Color(0xFF1976D2),
          800: const Color(0xFF1565C0),
          900: const Color(0xFF0D47A1),
        }),
        primaryColor: const Color(0xFF2A66F2),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2A66F2),
          secondary: Color(0xFFFFB800),
          surface: Colors.white,
          background: Color(0xFFF8F9FA),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}