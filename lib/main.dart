import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 👉 Hive import කරගන්න
import 'models/tution_class.dart';              // 👉 අපේ model එක import කරගන්න
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👉 FIX 1: App එක පටන් ගන්න කලින් Hive initialize කරනවා
  await Hive.initFlutter();

  // 👉 FIX 2: අපි generate කරපු Adapter එක Hive වලට register කරනවා
  Hive.registerAdapter(TutionClassAdapter());

  // 👉 FIX 3: App එක පුරාම use කරන්න class box එක open කරනවා
  await Hive.openBox<TutionClass>('classes');

  // (ඔයා payments වලටත් adapter හැදුවොත්, ඒ box එකත් මෙතන open කරන්න)

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const TutionPalApp());
}

class TutionPalApp extends StatelessWidget {
  const TutionPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuition Pal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}