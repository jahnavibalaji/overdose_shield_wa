import 'package:flutter/material.dart';
import 'narcan_prescription.dart';
import 'narcan_instruction.dart';
import 'naloxone_map.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

void main() {
  runApp(const OverdoseShieldApp());
}

class OverdoseShieldApp extends StatelessWidget {
  const OverdoseShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overdose Shield WA',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/map': (context) => const NaloxoneMapScreen(),
        '/narcan_prescription': (context) => const NarcanPrescriptionScreen(),
        '/narcan_instruction': (context) => const NarcanInstructionScreen(),
      },
    );
  }
}
