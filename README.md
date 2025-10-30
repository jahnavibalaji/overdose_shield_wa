# Overdose Shield

A Flutter + Firebase app to connect overdose victims with responders and naloxone locations in real time.

## Project Information

**Developer:** Jahnavi Balaji (High School Student, Washington State)  
**Email:** jahnavi.balaji11@gmail.com  
**Repository:** https://github.com/jahnavibalaji/overdose_shield_wa  
**Version:** 1.0.0+1  
**Last Updated:** January 2025

## Project Overview

Overdose Shield is a cross-platform mobile application built with Flutter that serves as a critical tool for overdose prevention and emergency response in Washington State. The app facilitates real-time communication between individuals experiencing overdose emergencies and trained responders in their vicinity.

### Key Features

- **Emergency Alert System**: Real-time location-based alerts to nearby responders
- **Naloxone Location Finder**: Interactive map showing nearby naloxone distribution points
- **Dual User Modes**: Separate interfaces for receivers (those in need) and responders (trained helpers)
- **Emergency Contacts**: SMS notification system for emergency contacts
- **Education & Accessibility**: Built-in PDF guides and prescription info, available across Android, iOS, and Web

## File Structure

### Directory Organization

```
overdose_shield_wa/
├── lib/                          # Main application source code
│   ├── auth/                     # Authentication modules
│   ├── models/                   # Data models and classes
│   ├── services/                 # Business logic services
│   └── *.dart                    # Main application screens
├── assets/                       # Static assets and resources
├── android/                      # Android platform-specific code
├── ios/                         # iOS platform-specific code
├── web/                         # Web platform-specific code
├── test/                        # Unit and widget tests
├── pubspec.yaml                 # Flutter dependencies and configuration
└── README.md                    # This documentation file
```

### File Naming Conventions

**Structure:** `[feature]_[type].dart`  
**Attributes:** 
- Feature: Describes the main functionality (auth, emergency, naloxone, etc.)
- Type: Indicates the file purpose (screen, service, model, etc.)

**Examples:**
- `login_screen.dart` - Authentication login interface
- `responder_dashboard.dart` - Main responder interface
- `emergency_contact.dart` - Data model for emergency contacts
- `alert_service.dart` - Handles Firebase alert triggers and notifications

## File Formats

The project uses a variety of file formats across different platforms and purposes. For detailed specifications of all file formats, extensions, and their uses, see [docs/FILE_FORMATS.md](docs/FILE_FORMATS.md).

**Summary:**
- **Source Code**: Dart (.dart), Swift (.swift), Kotlin (.kt), YAML (.yaml)
- **Configuration**: JSON (.json), XML (.xml), Plist (.plist), Gradle (.gradle.kts)
- **Assets**: PDF (.pdf), CSV (.csv), KML (.kml), PNG (.png)
- **Web**: HTML (.html), JavaScript (generated)

## Data Models and Schema

### User Profile Model
```dart
class UserProfile {
  String uid;                    // Unique user identifier
  String email;                  // User email address
  String displayName;            // User display name
  UserType userType;             // 'receiver' or 'responder'
  double? latitude;              // Current location latitude
  double? longitude;             // Current location longitude
  DateTime lastLoginTime;        // Last login timestamp
}
```
*Stored in Firestore under the `user_profiles` collection for role-based access and authentication.*

### Alert Model
```dart
class Alert {
  String id;                     // Unique alert identifier
  String message;                // Alert message content
  double latitude;               // Alert location latitude
  double longitude;              // Alert location longitude
  DateTime timestamp;            // Alert creation time
  String status;                 // 'pending', 'responded', 'resolved'
  String senderId;               // User who sent the alert
  String? responderId;           // User who responded to alert
}
```
*Stored in Firestore under the `notifications` collection for real-time alert tracking and responder coordination.*

### Emergency Contact Model
```dart
class EmergencyContact {
  String name;                   // Contact name
  String phoneNumber;            // Contact phone number
  String relationship;           // Relationship to user
  bool isPrimary;                // Primary emergency contact flag
}
```
*Stored locally using SharedPreferences and synced with user profiles for SMS notification functionality.*

## Dependencies and Technologies

### Core Dependencies
- **Flutter SDK**: >=3.3.0 <4.0.0
- **Firebase Core**: ^3.6.0 (Backend services)
- **Firebase Auth**: ^5.3.3 (User authentication)
- **Cloud Firestore**: ^5.4.3 (Database)
- **Google Sign-In**: ^6.2.1 (Authentication)

### Location and Mapping
- **Geolocator**: ^10.1.0 (GPS location services)
- **URL Launcher**: ^6.3.2 (External map applications)

### UI and Media
- **Flutter PDFView**: ^1.4.1+1 (PDF document viewing)
- **Permission Handler**: ^12.0.1 (Device permissions)
- **Shared Preferences**: ^2.2.2 (Local data storage)

## Installation and Setup

### Prerequisites
- Flutter SDK (>=3.3.0)
- Dart SDK
- Android Studio (for Android development)
- Xcode (for iOS development)
- Firebase project with authentication and Firestore enabled

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jahnavibalaji/overdose_shield_wa.git
   cd overdose_shield_wa
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` file to `android/app/`
   - Add your `GoogleService-Info.plist` file to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Run the application:**
   ```bash
   # For Android
   flutter run
   
   # For iOS
   flutter run -d ios
   
   # For Web
   flutter run -d chrome
   ```

## Configuration

### Firebase Setup
The application requires Firebase configuration for:
- **Authentication**: User login and registration
- **Firestore Database**: User profiles and alert storage
- **Cloud Messaging**: Push notifications for alerts

### Location Permissions
The app requires location permissions for:
- Finding nearby responders
- Sending location-based alerts
- Displaying user location on maps

### Platform-Specific Configuration

#### Android
- Minimum SDK: 21
- Target SDK: 34
- Location permissions in `AndroidManifest.xml`
- Google Services configuration

#### iOS
- Deployment target: 11.0
- Location usage descriptions in `Info.plist`
- Firebase configuration

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## Deployment

### Android
1. Generate signed APK:
   ```bash
   flutter build apk --release
   ```

2. Upload to Google Play Store

### iOS
1. Build for iOS:
   ```bash
   flutter build ios --release
   ```

2. Archive and upload via Xcode

### Web
1. Build for web:
   ```bash
   flutter build web
   ```

2. Deploy to web hosting service

## Data Privacy and Security

### User Data Protection
- All user data is encrypted in transit and at rest
- Location data is only stored temporarily for alert purposes
- User authentication is handled securely through Firebase

### Compliance
- HIPAA considerations for health-related data
- Washington State privacy laws compliance
- GDPR compliance for international users

## Version History

### Version 1.0.0+1 (January 2025)
- Initial production release
- Enhanced location accuracy (GPS-level precision)
- Firebase alert response fixes
- Cross-platform compatibility (Android, iOS, Web)
- Real-time alert system with 3+ responder notifications
- SMS emergency contact notifications
- Educational resource integration
- Prototype tested on Android Emulator (Pixel 6, API 34)

### Previous Versions
- Development and testing phases
- UI/UX improvements
- Bug fixes and performance optimizations

## Contributing

### Development Guidelines
- Follow Flutter/Dart coding standards
- Write comprehensive tests for new features
- Update documentation for any changes
- Use meaningful commit messages

### Code Style
- Use `flutter analyze` to check code quality
- Follow the existing file naming conventions
- Document complex functions and classes
- Use meaningful variable and function names

## Support and Contact

### Technical Support
- Create an issue in the GitHub repository
- Contact the developer at jahnavi.balaji11@gmail.com

### Emergency Support
- For immediate assistance, contact local emergency services
- The app is not a replacement for emergency medical services

## License

This project is not currently licensed for public use or redistribution.  
All rights are reserved by the developer. Permission is required for any form of reproduction, modification, or distribution.

A license may be added in a future release once the project is finalized and reviewed for compliance.

## Acknowledgments

- Washington State Department of Health for naloxone location data
- Flutter and Dart development teams
- Firebase for backend services
- Open source community contributors

---

**Important Notice**: This application is designed to assist in overdose prevention and emergency response. It is not a replacement for professional medical care or emergency services. Always call 911 in case of a medical emergency.

<!-- noop: trigger auth prompt on push -->