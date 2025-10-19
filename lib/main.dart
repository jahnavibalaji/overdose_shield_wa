import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'narcan_prescription.dart';
import 'narcan_instruction.dart';
import 'naloxone_map.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Current platform options: ${DefaultFirebaseOptions.currentPlatform}');
  }
  
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const NaloxoneMapScreen();
          }
          return const LoginScreen();
        },
      ),
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
