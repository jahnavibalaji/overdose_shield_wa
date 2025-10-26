enum UserType {
  receiver,    // Someone who might need Narcan
  responder,   // Someone who can supply Narcan
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.receiver:
        return 'Receiver';
      case UserType.responder:
        return 'Responder';
    }
  }

  String get description {
    switch (this) {
      case UserType.receiver:
        return 'I may need Narcan in an emergency';
      case UserType.responder:
        return 'I can supply Narcan to those in need';
    }
  }
}
