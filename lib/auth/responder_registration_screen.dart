import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_type.dart';
import 'firebase_auth_service.dart';

class ResponderRegistrationScreen extends StatefulWidget {
  const ResponderRegistrationScreen({super.key});

  @override
  State<ResponderRegistrationScreen> createState() => _ResponderRegistrationScreenState();
}

class _ResponderRegistrationScreenState extends State<ResponderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactNumberController = TextEditingController();
  final _maxDistanceController = TextEditingController(text: '5000'); // Default 5km
  final _additionalInfoController = TextEditingController();
  
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _isActiveResponder = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _contactNumberController.dispose();
    _maxDistanceController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15), // Wait up to 15 seconds for best GPS signal
      );
      
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responder Registration'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thank you for being a Responder!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Help save lives by providing Narcan to those in need.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Contact Information Section
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 (555) 123-4567',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Response Settings Section
              const Text(
                'Response Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Max Response Distance
              TextFormField(
                controller: _maxDistanceController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Response Distance (meters)',
                  hintText: '5000',
                  prefixIcon: Icon(Icons.location_on),
                  suffixText: 'meters',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter maximum response distance';
                  }
                  final distance = int.tryParse(value);
                  if (distance == null || distance < 100) {
                    return 'Please enter a valid distance (minimum 100 meters)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Active Responder Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isActiveResponder ? Icons.notifications_active : Icons.notifications_off,
                      color: _isActiveResponder ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Responder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isActiveResponder 
                                ? 'You will receive alerts for nearby emergencies'
                                : 'You will not receive alerts',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActiveResponder,
                      onChanged: (value) {
                        setState(() {
                          _isActiveResponder = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Information Section
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _additionalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Additional Information (Optional)',
                  hintText: 'Any additional details about your availability or experience...',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              
              const SizedBox(height: 24),
              
              // Location Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentPosition != null ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentPosition != null ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition != null ? Icons.location_on : Icons.location_off,
                      color: _currentPosition != null ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPosition != null ? 'Location Detected' : 'Location Access Needed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _currentPosition != null ? Colors.green : Colors.orange,
                            ),
                          ),
                          Text(
                            _currentPosition != null 
                                ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                : 'Please enable location access to receive nearby alerts',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentPosition == null)
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerAsResponder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Registration',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerAsResponder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get existing user profile and update responder-specific fields
      final existingProfile = await _authService.getUserProfile(currentUser.uid);
      if (existingProfile == null) {
        throw Exception('User profile not found');
      }

      // Update user profile with responder information
      final updatedProfile = existingProfile.copyWith(
        userType: UserType.responder,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        lastLocationUpdate: _currentPosition != null ? DateTime.now() : null,
        isActiveResponder: _isActiveResponder,
        maxResponseDistance: int.parse(_maxDistanceController.text),
        contactNumber: _contactNumberController.text,
        additionalInfo: _additionalInfoController.text.isNotEmpty 
            ? _additionalInfoController.text 
            : null,
      );

      // Update user profile in Firestore
      await _authService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully registered as a Responder!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to responder dashboard
        Navigator.of(context).pushReplacementNamed('/responder_dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering as responder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
