import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';
import '../models/alert.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register or update a user's location
  Future<void> updateUserLocation(UserAccount user) async {
    try {
      await _firestore
          .collection('user_locations')
          .doc(user.accountId)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user location: $e');
    }
  }

  // Create and distribute an alert
  Future<void> createAlert({
    required String senderAccountId,
    required String message,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      // Create the new alert
      final alert = Alert(
        alertId: DateTime.now().millisecondsSinceEpoch.toString(),
        senderAccountId: senderAccountId,
        message: message,
        originLatitude: latitude,
        originLongitude: longitude,
        radius: radius,
        timestamp: DateTime.now(),
      );

      // Save alert to Firestore
      await _firestore
          .collection('alerts')
          .doc(alert.alertId)
          .set(alert.toFirestore());

      // Find all users in proximity
      final accountsInProximity = await _findAccountsInProximity(alert);

      // Send notification to each account
      for (final account in accountsInProximity) {
        await _sendAlertToAccount(alert, account);
      }
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  // Find all accounts within the alert radius using Firestore
  Future<List<UserAccount>> _findAccountsInProximity(Alert alert) async {
    try {
      print('Searching for responders near ${alert.originLatitude}, ${alert.originLongitude} with radius ${alert.radius}km');
      
      // Get all active responders (users with isActiveResponder = true)
      final respondersQuery = await _firestore
          .collection('users')
          .where('isActiveResponder', isEqualTo: true)
          .get();

      print('Found ${respondersQuery.docs.length} active responders in database');

      final nearbyResponders = <UserAccount>[];

      for (final doc in respondersQuery.docs) {
        final userData = doc.data();
        final userLat = (userData['latitude'] as num?)?.toDouble();
        final userLng = (userData['longitude'] as num?)?.toDouble();

        print('Responder ${doc.id}: lat=$userLat, lng=$userLng');

        // Skip if this is the same user who sent the alert
        if (doc.id == alert.senderAccountId) {
          print('Skipping sender account ${doc.id}');
          continue;
        }

        if (userLat != null && userLng != null) {
          // Calculate distance using Haversine formula
          final distance = _calculateDistance(
            userLat,
            userLng,
            alert.originLatitude,
            alert.originLongitude,
          );

          print('Distance to responder ${doc.id}: ${distance.toStringAsFixed(2)}km');

          // If within radius, include this account
          if (distance <= alert.radius) {
            print('Responder ${doc.id} is within radius!');
            nearbyResponders.add(UserAccount(
              accountId: doc.id,
              username: userData['displayName'] ?? 'Anonymous',
              latitude: userLat,
              longitude: userLng,
              deviceId: 'device_${doc.id}', // We'll use account ID as device ID for now
              lastLocationUpdate: DateTime.now(),
            ));
          }
        } else {
          print('Responder ${doc.id} has no location data');
        }
      }

      print('Found ${nearbyResponders.length} nearby responders');
      return nearbyResponders;
    } catch (e) {
      print('Error finding accounts in proximity: $e');
      throw Exception('Failed to find accounts in proximity: $e');
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    const earthRadiusKm = 6371.0;

    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    return 2 * earthRadiusKm * asin(sqrt(a));
  }

  // Send alert to a specific account
  Future<void> _sendAlertToAccount(Alert alert, UserAccount account) async {
    try {
      print('Creating notification for responder ${account.accountId}');
      
      // Create a notification document in the user's notifications subcollection
      final docRef = await _firestore
          .collection('users')
          .doc(account.accountId)
          .collection('notifications')
          .add({
        'alertId': alert.alertId,
        'message': alert.message,
        'senderAccountId': alert.senderAccountId,
        'latitude': alert.originLatitude,
        'longitude': alert.originLongitude,
        'radius': alert.radius,
        'timestamp': Timestamp.fromDate(alert.timestamp),
        'status': 'pending', // pending, responded, dismissed
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Notification created with ID: ${docRef.id} for responder ${account.accountId}');
      print('Alert ${alert.alertId} sent to account ${account.accountId} on device ${account.deviceId}');
    } catch (e) {
      print('Failed to send alert to account ${account.accountId}: $e');
    }
  }

  // Get active alerts for a specific responder
  Stream<List<Alert>> getActiveAlertsForResponder(String responderAccountId) {
    return _firestore
        .collection('alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Alert.fromFirestore(data);
      }).toList();
    });
  }

  // Get notifications for a specific responder
  Stream<List<Map<String, dynamic>>> getNotificationsForResponder(String responderAccountId) {
    print('Querying notifications for responder: $responderAccountId');
    return _firestore
        .collection('users')
        .doc(responderAccountId)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} notification documents for $responderAccountId');
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['notificationId'] = doc.id;
        print('Notification data: $data');
        return data;
      }).toList();
      
      // Filter for pending notifications
      final pendingNotifications = notifications.where((n) => n['status'] == 'pending').toList();
      print('Found ${pendingNotifications.length} pending notifications');
      return pendingNotifications;
    });
  }

  // Respond to an alert
  Future<void> respondToAlert(String alertId, String responderAccountId) async {
    try {
      // Update the alert status
      await _firestore.collection('alerts').doc(alertId).update({
        'status': 'responded',
        'responderAccountId': responderAccountId,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Update the notification for this specific responder
      final notificationsQuery = await _firestore
          .collection('users')
          .doc(responderAccountId)
          .collection('notifications')
          .where('alertId', isEqualTo: alertId)
          .get();

      for (final doc in notificationsQuery.docs) {
        await doc.reference.update({
          'status': 'responded',
          'responderAccountId': responderAccountId,
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to respond to alert: $e');
    }
  }

  // Update responder location
  Future<void> updateResponderLocation(double latitude, double longitude) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'latitude': latitude,
          'longitude': longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update responder location: $e');
    }
  }

  // Create a test alert with a different location to simulate another user
  Future<void> createTestAlert({
    required String senderAccountId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Create a test alert with a slightly different location (simulate another user)
      final testLatitude = latitude + 0.001; // Add small offset to simulate different user
      final testLongitude = longitude + 0.001;
      
      // Use a different sender ID to simulate a different user
      final testSenderId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      
      print('Creating test alert at: $testLatitude, $testLongitude from user: $testSenderId');
      
      await createAlert(
        senderAccountId: testSenderId,
        message: 'SOS: Need Narcan immediately! Emergency overdose situation.',
        latitude: testLatitude,
        longitude: testLongitude,
        radius: 5.0, // 5km radius
      );
      
      print('Test alert created at location: $testLatitude, $testLongitude');
    } catch (e) {
      print('Error creating test alert: $e');
      throw Exception('Failed to create test alert: $e');
    }
  }

  // Ensure responder location is stored in Firestore
  Future<void> ensureResponderLocation(String responderId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(responderId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isActiveResponder': true,
      });
      print('Updated responder $responderId location: $latitude, $longitude');
    } catch (e) {
      print('Error updating responder location: $e');
      throw Exception('Failed to update responder location: $e');
    }
  }
}
