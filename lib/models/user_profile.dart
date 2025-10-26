import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_type.dart';
import 'emergency_contact.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserType userType;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? provider;
  
  // Location data (for responders)
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;
  
  // Responder-specific data
  final bool isActiveResponder;
  final int? maxResponseDistance; // in meters
  final String? contactNumber;
  final String? additionalInfo;
  
  // Emergency contacts (for receivers)
  final List<EmergencyContact> emergencyContacts;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.userType,
    required this.createdAt,
    required this.lastLoginAt,
    this.provider,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
    this.isActiveResponder = false,
    this.maxResponseDistance,
    this.contactNumber,
    this.additionalInfo,
    this.emergencyContacts = const [],
  });

  // Convert from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      userType: UserType.values.firstWhere(
        (type) => type.name == data['userType'],
        orElse: () => UserType.receiver,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      provider: data['provider'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      lastLocationUpdate: (data['lastLocationUpdate'] as Timestamp?)?.toDate(),
      isActiveResponder: data['isActiveResponder'] ?? false,
      maxResponseDistance: data['maxResponseDistance'],
      contactNumber: data['contactNumber'],
      additionalInfo: data['additionalInfo'],
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
          ?.map((contact) => EmergencyContact.fromMap(contact))
          .toList() ?? [],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'provider': provider,
      'latitude': latitude,
      'longitude': longitude,
      'lastLocationUpdate': lastLocationUpdate != null 
          ? Timestamp.fromDate(lastLocationUpdate!) 
          : null,
      'isActiveResponder': isActiveResponder,
      'maxResponseDistance': maxResponseDistance,
      'contactNumber': contactNumber,
      'additionalInfo': additionalInfo,
      'emergencyContacts': emergencyContacts.map((contact) => contact.toMap()).toList(),
    };
  }

  // Copy with method for updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserType? userType,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? provider,
    double? latitude,
    double? longitude,
    DateTime? lastLocationUpdate,
    bool? isActiveResponder,
    int? maxResponseDistance,
    String? contactNumber,
    String? additionalInfo,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      provider: provider ?? this.provider,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      isActiveResponder: isActiveResponder ?? this.isActiveResponder,
      maxResponseDistance: maxResponseDistance ?? this.maxResponseDistance,
      contactNumber: contactNumber ?? this.contactNumber,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
