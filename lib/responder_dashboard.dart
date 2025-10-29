import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth/firebase_auth_service.dart';
import 'models/user_type.dart';
import 'services/alert_service.dart';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});

  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotifications();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        
        if (profile?.userType == UserType.responder) {
          try {
            // Check if location permission is granted
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              print('Location services are disabled');
              return;
            }

            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied) {
                print('Location permissions are denied');
                return;
              }
            }

            if (permission == LocationPermission.deniedForever) {
              print('Location permissions are permanently denied');
              return;
            }

            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            
            final alertService = AlertService();
            await alertService.ensureResponderLocation(
              user.uid,
              position.latitude,
              position.longitude,
            );
          } catch (e) {
            print('Error setting up responder location: $e');
          }
        }
        
        setState(() {
          _isLoading = false;
        });
        
        // Update the UI based on user profile
        if (profile != null) {
          print('User profile loaded: ${profile.displayName}');
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Simplified query to avoid index requirement
        final querySnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('status', isEqualTo: 'pending')
            .limit(10)
            .get();

        // Sort in memory instead of using orderBy
        final docs = querySnapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = a.data()['timestamp']?.toDate() ?? DateTime(1970);
          final bTime = b.data()['timestamp']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // Descending order
        });

        // Add a test alert if no real alerts are found
        List<Map<String, dynamic>> notifications = docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();

        // If no notifications found, add a test alert
        if (notifications.isEmpty) {
          notifications.add({
            'id': 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
            'message': '🚨 TEST ALERT: Person needs immediate help with overdose',
            'latitude': 47.5776875,
            'longitude': -122.1272197,
            'timestamp': Timestamp.fromDate(DateTime.now()),
            'status': 'pending',
            'senderId': 'test_sender_123',
            'senderName': 'Test User',
            'alertId': 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
          });
        }

        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      
      // If there's an error, show a test alert anyway
      setState(() {
        _notifications = [{
          'id': 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
          'message': '🚨 TEST ALERT: Person needs immediate help with overdose',
          'latitude': 47.5776875,
          'longitude': -122.1272197,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'status': 'pending',
          'senderId': 'test_sender_123',
          'senderName': 'Test User',
          'alertId': 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
        }];
      });
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                                  'Responder Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _switchToReceiver(context),
                            icon: const Icon(Icons.person, color: Colors.white, size: 20),
                            tooltip: 'Switch to Receiver Mode',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                            tooltip: 'Logout',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main Content
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Card
                              _buildStatusCard(),
                              const SizedBox(height: 20),
                              
                              // Map Card
                              _buildMapCard(),
                              const SizedBox(height: 20),
                              
                              // Emergency Alerts Section
                              const Text(
                                'Active Alerts',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Notifications List
                              ..._notifications.map((notification) => 
                                _buildEmergencyAlertCard(notification)
                              ).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1), // Semi-transparent white
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50), // Green
                                        shape: BoxShape.circle,
                                      ),
            child: const Icon(
              Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
            child: Text(
              'Active Responder',
              style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
                                            ),
                                          ),
                                        ],
                                      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1), // Semi-transparent white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
      child: Stack(
        children: [
          // Map placeholder
                              Container(
                                decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), // Semi-transparent white
                                  borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                Icons.map,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          // Location pin
          const Positioned(
            top: 80,
            left: 120,
            child: Icon(
              Icons.location_on,
                                            color: Colors.red,
              size: 32,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        
  Widget _buildEmergencyAlertCard(Map<String, dynamic> notification) {
                                            return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
        color: Colors.white, // White background for alerts
        borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 8,
            offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800), // Orange
                  shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                  Icons.warning,
                                                          color: Colors.white,
                  size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                  'Emergency: Narcan Needed',
                                                          style: TextStyle(
                    fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                    color: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
            '${_calculateDistance(notification)} miles away',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
            '${_getTimeAgo(notification)} ago',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () => _openGoogleMaps(notification),
                                                          style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          icon: const Icon(Icons.navigation, size: 16),
                                                          label: const Text('Navigate'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToAlert(notification),
                                                          style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Respond'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
  }

  String _calculateDistance(Map<String, dynamic> notification) {
    // Simple distance calculation - in real app, you'd use actual location
    return '0.4';
  }

  String _getTimeAgo(Map<String, dynamic> notification) {
    final timestamp = notification['timestamp'];
    if (timestamp != null) {
      final now = DateTime.now();
      final alertTime = timestamp.toDate();
      final difference = now.difference(alertTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else {
        return '${difference.inHours}h';
      }
    }
    return 'Unknown';
  }

  Future<void> _openGoogleMaps(Map<String, dynamic> notification) async {
    final lat = notification['latitude'] ?? 0.0;
    final lng = notification['longitude'] ?? 0.0;
    
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
                                          backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _respondToAlert(Map<String, dynamic> notification) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification['id'])
            .update({
          'status': 'responded',
          'responderAccountId': user.uid,
          'respondedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response recorded successfully'),
              backgroundColor: Colors.green,
      ),
    );
  }

        // Reload notifications
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error responding to alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchToReceiver(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create or update user profile with receiver type
        await FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(user.uid)
            .set({
          'userType': 'receiver',
          'email': user.email,
          'displayName': user.displayName ?? 'User',
          'lastLoginTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/map');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch to receiver mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
