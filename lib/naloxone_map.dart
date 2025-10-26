import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/firebase_auth_service.dart';
import 'models/user_type.dart';
import 'services/alert_service.dart';

class NaloxoneMapScreen extends StatelessWidget {
  const NaloxoneMapScreen({super.key});

  Future<void> _openMaps(BuildContext context) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=pharmacies+near+me',
    );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch Google Maps.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open a maps app. Please make sure one is installed.'),
        ),
      );
    }
  }

  void _showReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder'),
        content: const Text(
          'After finding a pharmacy, return to the app to view the Narcan prescription and instructions.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openMaps(context);
            },
            child: const Text('Open Maps'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _goToPrescription(BuildContext context) {
    Navigator.pushNamed(context, '/narcan_prescription');
  }

  void _goToInstructions(BuildContext context) {
    Navigator.pushNamed(context, '/narcan_instruction');
  }

  Future<void> _callEmergency(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '5124158065');

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the dialer.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call failed: $e')),
      );
    }
  }

  Future<void> _sendSOSAlert(BuildContext context) async {
    try {
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please enable location services.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Use the new proximity-based alert service
      final alertService = AlertService();
      await alertService.createAlert(
        senderAccountId: user.uid,
        message: 'Emergency: Narcan needed immediately!',
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 5.0, // 5 km radius
      );

      // Also notify emergency contacts
      await _notifyEmergencyContacts(user.uid, position);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 SOS ALERT SENT! Help is on the way! 🚨'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Show confirmation dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('🚨 SOS Alert Sent!'),
              content: const Text(
                'Your emergency alert has been sent to nearby responders within 5km. '
                'Help should arrive soon. Please stay safe and wait for assistance.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Also call 911
                    _callEmergency(context);
                  },
                  child: const Text('Call 911'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchToResponder(BuildContext context) async {
    try {
      final authService = FirebaseAuthService();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await authService.updateUserType(user.uid, UserType.responder);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Switched to responder mode'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to responder dashboard
          Navigator.of(context).pushReplacementNamed('/responder_dashboard');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch to responder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _notifyEmergencyContacts(String userId, Position position) async {
    try {
      // Get user profile to access emergency contacts
      final authService = FirebaseAuthService();
      final profile = await authService.getUserProfile(userId);
      
      if (profile?.emergencyContacts.isNotEmpty == true) {
        final phoneNumbers = profile!.emergencyContacts
            .where((contact) => contact.phoneNumber.isNotEmpty)
            .map((contact) => contact.phoneNumber)
            .toList();

        if (phoneNumbers.isNotEmpty) {
          // Create emergency message with location
          final locationUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
          final smsBody = 'EMERGENCY: I need help immediately! My location: $locationUrl Please respond as soon as possible.';
          final smsUri = Uri.parse('sms:${phoneNumbers.join(',')}?body=${Uri.encodeComponent(smsBody)}');

          try {
            if (await canLaunchUrl(smsUri)) {
              await launchUrl(smsUri);
              print('Emergency contacts notified via SMS');
            }
          } catch (e) {
            print('Failed to send SMS to emergency contacts: $e');
          }
        }
      }
    } catch (e) {
      print('Error notifying emergency contacts: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authService = FirebaseAuthService();
      await authService.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1A3A), // Very dark blue
              Color(0xFF1A237E), // Dark blue
              Color(0xFF283593), // Medium dark blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Overdose Shield',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _switchToResponder(context),
                      icon: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
                      tooltip: 'Switch to Responder Mode',
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    IconButton(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // "Help is just seconds away" text
                    const Text(
                      'Help is just seconds away',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Large Circular SOS Button
                    GestureDetector(
                      onTap: () => _sendSOSAlert(context),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2196F3), // Bright blue
                              Color(0xFF00BCD4), // Cyan
                              Color(0xFFFF9800), // Orange
                              Color(0xFFFF5722), // Deep orange
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'I NEED HELP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Location sharing text
                    const Text(
                      'Your location is being shared securely.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Responders nearby
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Responders nearby',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Bottom Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.map,
                              label: 'Pharmacies',
                              onTap: () => _showReminder(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.contacts,
                              label: 'Contacts',
                              onTap: () => Navigator.pushNamed(context, '/emergency_contacts'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.info,
                              label: 'Instructions',
                              onTap: () => _goToInstructions(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.description,
                              label: 'Prescription',
                              onTap: () => _goToPrescription(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Dark blue
              Color(0xFF283593), // Medium blue
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

}
