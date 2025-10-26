class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? relationship; // e.g., "Family", "Friend", "Doctor", etc.

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      relationship: map['relationship'],
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
    );
  }

  @override
  String toString() {
    return 'EmergencyContact(id: $id, name: $name, phoneNumber: $phoneNumber, email: $email, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
