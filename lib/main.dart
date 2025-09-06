import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TutionPalApp());
}

class TutionPalApp extends StatelessWidget {
  const TutionPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home එකට අපි කලින් හදපු HomeScreen එක දෙනවා.
      home: const HomeScreen(),
    );
  }
}
