class UserAccount {
  final String accountId;
  final String username;
  double latitude;
  double longitude;
  final String deviceId; // The physical device ID
  final DateTime lastLocationUpdate;

  UserAccount({
    required this.accountId,
    required this.username,
    required this.latitude,
    required this.longitude,
    required this.deviceId,
    required this.lastLocationUpdate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'username': username,
      'latitude': latitude,
      'longitude': longitude,
      'deviceId': deviceId,
      'lastLocationUpdate': lastLocationUpdate,
    };
  }

  factory UserAccount.fromFirestore(Map<String, dynamic> data) {
    return UserAccount(
      accountId: data['accountId'] ?? '',
      username: data['username'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      deviceId: data['deviceId'] ?? '',
      lastLocationUpdate: (data['lastLocationUpdate'] as DateTime?) ?? DateTime.now(),
    );
  }
}
