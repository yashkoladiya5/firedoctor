final class FirebasePackage {
  final String packageName;
  final String displayName;
  final String category;
  final String documentationUrl;
  final String description;

  const FirebasePackage({
    required this.packageName,
    required this.displayName,
    required this.category,
    required this.documentationUrl,
    required this.description,
  });

  static const core = FirebasePackage(
    packageName: 'firebase_core',
    displayName: 'Firebase Core',
    category: 'Core',
    documentationUrl: 'https://firebase.flutter.dev/docs/core/overview',
    description:
        'Firebase Core package for Flutter. Required by all Firebase services.',
  );

  static const auth = FirebasePackage(
    packageName: 'firebase_auth',
    displayName: 'Firebase Authentication',
    category: 'Authentication',
    documentationUrl: 'https://firebase.flutter.dev/docs/auth/overview',
    description: 'Firebase Authentication package for Flutter.',
  );

  static const cloudFirestore = FirebasePackage(
    packageName: 'cloud_firestore',
    displayName: 'Cloud Firestore',
    category: 'Firestore Database',
    documentationUrl: 'https://firebase.flutter.dev/docs/firestore/overview',
    description: 'Cloud Firestore package for Flutter.',
  );

  static const storage = FirebasePackage(
    packageName: 'firebase_storage',
    displayName: 'Firebase Storage',
    category: 'Cloud Storage',
    documentationUrl: 'https://firebase.flutter.dev/docs/storage/overview',
    description: 'Firebase Cloud Storage package for Flutter.',
  );

  static const messaging = FirebasePackage(
    packageName: 'firebase_messaging',
    displayName: 'Firebase Cloud Messaging',
    category: 'Cloud Messaging',
    documentationUrl: 'https://firebase.flutter.dev/docs/messaging/overview',
    description: 'Firebase Cloud Messaging package for Flutter.',
  );

  static const crashlytics = FirebasePackage(
    packageName: 'firebase_crashlytics',
    displayName: 'Firebase Crashlytics',
    category: 'Crashlytics',
    documentationUrl: 'https://firebase.flutter.dev/docs/crashlytics/overview',
    description: 'Firebase Crashlytics package for Flutter.',
  );

  static const analytics = FirebasePackage(
    packageName: 'firebase_analytics',
    displayName: 'Firebase Analytics',
    category: 'Analytics',
    documentationUrl: 'https://firebase.flutter.dev/docs/analytics/overview',
    description: 'Firebase Analytics package for Flutter.',
  );

  static const remoteConfig = FirebasePackage(
    packageName: 'firebase_remote_config',
    displayName: 'Firebase Remote Config',
    category: 'Remote Config',
    documentationUrl:
        'https://firebase.flutter.dev/docs/remote-config/overview',
    description: 'Firebase Remote Config package for Flutter.',
  );

  static const database = FirebasePackage(
    packageName: 'firebase_database',
    displayName: 'Firebase Realtime Database',
    category: 'Realtime Database',
    documentationUrl: 'https://firebase.flutter.dev/docs/database/overview',
    description: 'Firebase Realtime Database package for Flutter.',
  );

  static const appCheck = FirebasePackage(
    packageName: 'firebase_app_check',
    displayName: 'Firebase App Check',
    category: 'App Check',
    documentationUrl: 'https://firebase.flutter.dev/docs/app-check/overview',
    description: 'Firebase App Check package for Flutter.',
  );

  static const List<FirebasePackage> all = [
    core,
    auth,
    cloudFirestore,
    storage,
    messaging,
    crashlytics,
    analytics,
    remoteConfig,
    database,
    appCheck,
  ];

  static FirebasePackage? fromPackageName(String name) {
    for (final pkg in all) {
      if (pkg.packageName == name) return pkg;
    }
    return null;
  }
}
