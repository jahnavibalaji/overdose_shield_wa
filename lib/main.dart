import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'narcan_prescription.dart';
import 'narcan_instruction.dart';
import 'naloxone_map.dart';
import 'responder_dashboard.dart';
import 'emergency_contacts_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/user_type_selection_screen.dart';
import 'auth/responder_registration_screen.dart';
import 'auth/firebase_auth_service.dart';
import 'models/user_profile.dart';
import 'models/user_type.dart';

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

  Future<UserProfile?> _getUserProfile(String uid) async {
    try {
      print('Getting user profile for uid: $uid');
      final authService = FirebaseAuthService();
      final profile = await authService.getUserProfile(uid);
      print('User profile result: ${profile != null ? 'Found' : 'Not found'}');
      if (profile != null) {
        print('User type: ${profile.userType.name}');
      }
      return profile;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

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
          print('Auth state changed: ${snapshot.hasData ? 'User logged in' : 'No user'}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            print('User authenticated: ${snapshot.data?.email}');
            return FutureBuilder<UserProfile?>(
              future: _getUserProfile(snapshot.data!.uid),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (userTypeSnapshot.hasData && userTypeSnapshot.data != null) {
                  final userProfile = userTypeSnapshot.data!;
                  print('User profile found, navigating based on user type: ${userProfile.userType.name}');
                  if (userProfile.userType == UserType.responder) {
                    return const ResponderDashboard();
                  } else {
                    return const NaloxoneMapScreen();
                  }
                } else {
                  print('No user profile found, navigating to user type selection');
                  return UserTypeSelectionScreen(
                    email: snapshot.data!.email ?? '',
                    displayName: snapshot.data!.displayName ?? '',
                    provider: snapshot.data!.providerData.isNotEmpty 
                        ? snapshot.data!.providerData.first.providerId 
                        : 'email',
                  );
                }
              },
            );
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/user_type_selection': (context) => const UserTypeSelectionScreen(
          email: '', 
          displayName: '', 
          provider: null
        ),
        '/responder_setup': (context) => const ResponderRegistrationScreen(),
        '/responder_dashboard': (context) => const ResponderDashboard(),
        '/map': (context) => const NaloxoneMapScreen(),
        '/narcan_prescription': (context) => const NarcanPrescriptionScreen(),
        '/narcan_instruction': (context) => const NarcanInstructionScreen(),
        '/emergency_contacts': (context) => const EmergencyContactsScreen(),
      },
    );
  }
}
