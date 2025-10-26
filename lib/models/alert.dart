import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String alertId;
  final String senderAccountId;
  final String message;
  final double originLatitude;
  final double originLongitude;
  final double radius; // in kilometers
  final DateTime timestamp;
  final String status; // 'active', 'responded', 'cancelled'
  final String? responderAccountId;

  Alert({
    required this.alertId,
    required this.senderAccountId,
    required this.message,
    required this.originLatitude,
    required this.originLongitude,
    required this.radius,
    required this.timestamp,
    this.status = 'active',
    this.responderAccountId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'alertId': alertId,
      'senderAccountId': senderAccountId,
      'message': message,
      'originLatitude': originLatitude,
      'originLongitude': originLongitude,
      'radius': radius,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'responderAccountId': responderAccountId,
    };
  }

  factory Alert.fromFirestore(Map<String, dynamic> data) {
    return Alert(
      alertId: data['alertId'] ?? '',
      senderAccountId: data['senderAccountId'] ?? '',
      message: data['message'] ?? '',
      originLatitude: (data['originLatitude'] as num?)?.toDouble() ?? 0.0,
      originLongitude: (data['originLongitude'] as num?)?.toDouble() ?? 0.0,
      radius: (data['radius'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      responderAccountId: data['responderAccountId'],
    );
  }
}
