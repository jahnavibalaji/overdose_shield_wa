import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use minimal configuration to avoid People API
    scopes: <String>[], // Empty scopes array
    // Force account selection
    forceCodeForRefreshToken: true,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserType userType = UserType.receiver,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'userType': userType.name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActiveResponder': false,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Try to update last login time, create document if it doesn't exist
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If update fails, document might not exist, create it
        print('User document not found, creating profile for existing user...');
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'userType': UserType.receiver.name, // Default to receiver
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'provider': 'email',
          'isActiveResponder': false,
        }, SetOptions(merge: true));
        print('User profile created successfully');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-in...');
      
      // Sign out from Google first to allow account selection
      await _googleSignIn.signOut();
      print('Signed out from Google to allow account selection');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-in was cancelled by user');
        return null;
      }

      print('Google Sign-in successful, getting authentication details...');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Creating Firebase credential...');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with credential...');

      // Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      print('Firebase authentication successful! User: ${userCredential.user?.email}');

      // Check if this is a new user and try to create/update Firestore document
      try {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          print('New user detected, creating Firestore document...');
          // Create user document in Firestore for new users
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'userType': UserType.receiver.name, // Default to receiver for Google sign-in
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'provider': 'google',
            'isActiveResponder': false,
          });
          print('Firestore document created successfully');
        } else {
          print('Existing user, updating last login time...');
          // Update last login time for existing users
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          print('Firestore document updated successfully');
        }
      } catch (firestoreError) {
        print('Firestore operation failed: $firestoreError');
        // If it's a "document not found" error, create the document
        if (firestoreError.toString().contains('not-found')) {
          print('Document not found, creating user profile...');
          try {
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'email': userCredential.user!.email,
              'displayName': userCredential.user!.displayName,
              'photoURL': userCredential.user!.photoURL,
              'userType': UserType.receiver.name,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLoginAt': FieldValue.serverTimestamp(),
              'provider': 'google',
              'isActiveResponder': false,
            });
            print('User profile created successfully');
          } catch (createError) {
            print('Failed to create user profile: $createError');
          }
        }
      }

      print('Google Sign-in completed successfully!');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: $e');
      throw _handleAuthException(e);
    } catch (e) {
      print('General Exception during Google Sign-in: $e');
      throw Exception('Google Sign-in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('Successfully signed out from Firebase and Google');
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Clear all authentication data (for account switching)
  Future<void> clearAllAuthData() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google and disconnect
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      
      print('Cleared all authentication data');
    } catch (e) {
      print('Error clearing auth data: $e');
      throw Exception('Failed to clear authentication data: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }


  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).delete();
      
      // Delete user account
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).update(profile.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update user type
  Future<void> updateUserType(String uid, UserType userType) async {
    try {
      print('Updating user type for uid: $uid to: ${userType.name}');
      await _firestore.collection('users').doc(uid).set({
        'userType': userType.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('User type updated successfully');
    } catch (e) {
      print('Error updating user type: $e');
      throw Exception('Failed to update user type: $e');
    }
  }

  // Update responder status
  Future<void> updateResponderStatus(String uid, bool isActiveResponder) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActiveResponder': isActiveResponder,
      });
    } catch (e) {
      throw Exception('Failed to update responder status: $e');
    }
  }

  // Update location for responders
  Future<void> updateLocation(String uid, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}

