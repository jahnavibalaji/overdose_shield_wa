import 'package:flutter/material.dart';
import '../models/user_type.dart';
import 'firebase_auth_service.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String email;
  final String displayName;
  final String? provider;

  const UserTypeSelectionScreen({
    super.key,
    required this.email,
    required this.displayName,
    this.provider,
  });

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserType? _selectedUserType;
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Welcome Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.assignment_ind,
                          size: 40,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to Overdose Shield WA!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your role to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // User Type Selection Cards
                Column(
                  children: [
                    // Receiver Card
                    _buildUserTypeCard(
                      UserType.receiver,
                      Icons.person,
                      const Color(0xFF4CAF50),
                      'I may need Narcan in an emergency',
                      'Get help when you need it most',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Responder Card
                    _buildUserTypeCard(
                      UserType.responder,
                      Icons.local_hospital,
                      const Color(0xFF2196F3),
                      'I can supply Narcan to those in need',
                      'Help others in their time of need',
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Continue Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _selectedUserType != null && !_isLoading
                        ? const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          )
                        : null,
                    color: _selectedUserType == null || _isLoading
                        ? Colors.grey[300]
                        : null,
                    boxShadow: _selectedUserType != null && !_isLoading
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1976D2).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedUserType != null && !_isLoading 
                        ? _continueWithUserType 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedUserType != null ? Colors.white : Colors.grey[600],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(UserType userType, IconData icon, Color color, String title, String subtitle) {
    final isSelected = _selectedUserType == userType;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = userType;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 15 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Icon and Selection Indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? color.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: isSelected ? Colors.white : Colors.transparent,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Title and Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueWithUserType() async {
    if (_selectedUserType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Update the user's type in Firestore
        await _authService.updateUserType(currentUser.uid, _selectedUserType!);
        
        if (mounted) {
          // Navigate to the appropriate screen based on user type
          if (_selectedUserType == UserType.responder) {
            // Navigate to responder setup screen
            Navigator.of(context).pushReplacementNamed('/responder_setup');
          } else {
            // Navigate to main app for receivers
            Navigator.of(context).pushReplacementNamed('/map');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user type: $e'),
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
