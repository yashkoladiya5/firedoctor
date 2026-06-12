# Diagnostic Codes Reference

FireDoctor defines 56 diagnostic codes across 7 analyzers. Each code identifies a specific Firebase configuration issue.

## Severity Legend

| Severity | Icon | Meaning |
|----------|------|---------|
| Critical | 🚨 | Blocking issue — Firebase services will not function |
| Error | ❌ | Serious issue — incorrect behavior or missing requirements |
| Warning | ⚠️ | Configuration problem — potential issues or missing best practices |
| Info | ℹ️ | Informational — recommendations and improvement suggestions |

## Code Range Summary

| Analyzer | Code Range | Codes | Critical | Error | Warning | Info |
|----------|------------|-------|----------|-------|---------|------|
| Project | FD100 series | 9 | 0 | 1 | 5 | 3 |
| Dependency | FD200 series | 3 | 0 | 0 | 2 | 1 |
| Firebase Core | FD300 series | 8 | 0 | 1 | 5 | 2 |
| Android | FD400 series | 13 | 1 | 2 | 3 | 7 |
| iOS | FD500 series | 10 | 1 | 3 | 3 | 3 |
| FCM | FD600 series | 6 | 0 | 0 | 2 | 4 |
| Crashlytics | FD700 series | 11 | 0 | 2 | 1 | 8 |
| **Total** | — | **56** | **2** | **9** | **21** | **28** |

---

## Project Analyzer (FD100 series)

Checks project structure, pubspec.yaml validity, and Flutter platform directories.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD100 | Warning | Missing pubspec.yaml | Project does not contain a pubspec.yaml file | Ensure the project root contains a valid pubspec.yaml |
| FD101 | Error | Invalid pubspec.yaml | pubspec.yaml is not valid YAML or cannot be parsed | Fix YAML syntax errors in pubspec.yaml |
| FD102 | Info | Missing pubspec name field | pubspec.yaml is missing a `name` field | Add a `name` field to your pubspec.yaml |
| FD103 | Info | Flutter SDK constraint | Flutter SDK constraint is not specified in pubspec.yaml | Add `flutter` to your SDK constraints |
| NOT_FLUTTER_PROJECT | Warning | Not a Flutter project | Project does not declare a dependency on Flutter | Add `flutter` as a dependency to use Firebase Flutter plugins |
| MISSING_ANDROID | Warning | Missing android/ directory | No android/ directory found | Add Android platform support with `flutter create --platforms=android` |
| MISSING_IOS | Warning | Missing ios/ directory | No ios/ directory found | Add iOS platform support with `flutter create --platforms=ios` |
| MISSING_LIB | Error | Missing lib/ directory | No lib/ directory found | Create a `lib/` directory with Dart source files |
| MISSING_TEST | Info | Missing test/ directory | No test/ directory found | Create a `test/` directory and add tests |

---

## Dependency Analyzer (FD200 series)

Validates Firebase package dependencies in pubspec.yaml.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD200 | Warning | Missing firebase_core dependency | firebase_core is not declared in dependencies but other Firebase packages are present | Add `firebase_core: ^3.0.0` to your dependencies — it is required by all Firebase services |
| FD201 | Warning | Firebase package in dev_dependencies | Firebase packages should be in dependencies, not dev_dependencies | Move Firebase packages from `dev_dependencies` to `dependencies` |
| FD202 | Info | Loose Firebase version constraint | Firebase dependency uses a loose version constraint (`any`, `*`, or empty) | Use a caret constraint like `^2.0.0` to avoid unexpected breaking changes |

---

## Firebase Core Analyzer (FD300 series)

Analyzes Firebase initialization in Dart source files.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD300 | Error | Missing firebase_core dependency | firebase_core is not added to pubspec.yaml | Add `firebase_core: ^3.0.0` to your dependencies |
| FD301 | Warning | Missing firebase_options.dart | firebase_options.dart file not found in lib/ | Run `flutterfire configure` to generate firebase_options.dart |
| FD302 | Info | Firebase not initialized | No `Firebase.initializeApp()` call found | Add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` to your main function |
| FD303 | Info | DefaultFirebaseOptions not used | DefaultFirebaseOptions.currentPlatform not found in Firebase initialization | Pass platform-specific options: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` |
| FD304 | Warning | Multiple Firebase.initializeApp() calls | Multiple calls to Firebase.initializeApp() found | Ensure Firebase is initialized only once in your application |
| FD305 | Warning | Unawaited Firebase.initializeApp() | Firebase.initializeApp() is not awaited | Add `await` before `Firebase.initializeApp()` |
| FD306 | Warning | Firebase.initializeApp() after runApp() | Firebase.initializeApp() is called after runApp() | Move Firebase.initializeApp() before the runApp() call |
| FD307 | Warning | Missing WidgetsFlutterBinding.ensureInitialized() | WidgetsFlutterBinding.ensureInitialized() is missing before Firebase init | Add `WidgetsFlutterBinding.ensureInitialized()` before `Firebase.initializeApp()` |

---

## Android Analyzer (FD400 series)

Checks Android Firebase configuration: google-services.json, build.gradle, AndroidManifest.xml.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD400 | Critical | Missing google-services.json | android/app/google-services.json file is missing | Run `flutterfire configure` to generate the google-services.json file |
| FD401 | Error | Invalid google-services.json | google-services.json contains invalid JSON | Regenerate using `flutterfire configure` or fix JSON syntax errors |
| FD402 | Error | Package name mismatch | Package names in google-services.json and build.gradle do not match | Update applicationId in build.gradle or regenerate google-services.json |
| FD403 | Warning | Missing google-services plugin | com.google.gms.google-services Gradle plugin is not applied | Add `id "com.google.gms.google-services" version "4.4.0"` to your app-level build.gradle |
| FD404 | Warning | Outdated build tools version | Android build tools version is outdated | Update build tools version in your build.gradle |
| FD405 | Warning | Missing POST_NOTIFICATIONS permission | POST_NOTIFICATIONS permission is missing in AndroidManifest.xml | Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` for Android 13+ |
| FD406 | Info | Missing WAKE_LOCK permission | WAKE_LOCK permission is missing in AndroidManifest.xml | Add `<uses-permission android:name="android.permission.WAKE_LOCK"/>` |
| FD407 | Info | Missing INTERNET permission | INTERNET permission is missing in AndroidManifest.xml | Add `<uses-permission android:name="android.permission.INTERNET"/>` |
| FD408 | Info | Outdated minSdkVersion | Android minSdkVersion is below 21 | Set `minSdk = 21` for firebase_core compatibility |
| FD409 | Info | Outdated targetSdkVersion | Android targetSdkVersion is below 34 | Update `targetSdk` to 34 |
| FD410 | Info | Outdated compileSdkVersion | Android compileSdkVersion is below 34 | Update `compileSdk` to 34 |
| FD411 | Info | Missing applicationId | Missing applicationId in build.gradle | Add `applicationId` to your defaultConfig block |
| FD412 | Info | Missing AGP version | Android Gradle Plugin version not found in project | Add Android Gradle Plugin to your project-level build.gradle |

---

## iOS Analyzer (FD500 series)

Checks iOS Firebase configuration: GoogleService-Info.plist, Podfile, Xcode project, Info.plist.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD500 | Critical | Missing GoogleService-Info.plist | iOS GoogleService-Info.plist file is missing | Run `flutterfire configure` or download from Firebase Console |
| FD501 | Error | Invalid GoogleService-Info.plist | GoogleService-Info.plist is not valid or malformed | Regenerate using `flutterfire configure` or download fresh from Firebase Console |
| FD502 | Error | Bundle ID mismatch | Bundle IDs in GoogleService-Info.plist and Xcode project do not match | Update PRODUCT_BUNDLE_IDENTIFIER in Xcode or regenerate GoogleService-Info.plist |
| FD503 | Error | Missing Podfile | iOS/Podfile is missing | Run `flutter create .` in the ios directory or create a Podfile manually |
| FD504 | Warning | Firebase pod not found | No Firebase pods found in Podfile.lock | Add Firebase pods to your Podfile: `pod 'Firebase/Core'` |
| FD505 | Warning | Push Notifications capability missing | Push Notifications capability is not enabled in Xcode project | Enable in Xcode: Signing & Capabilities > + Capability > Push Notifications |
| FD506 | Warning | Background Modes capability missing | Background Modes capability is not enabled in Xcode project | Enable in Xcode: Signing & Capabilities > + Capability > Background Modes |
| FD507 | Info | Remote-notifications background mode missing | Remote-notifications background mode is not enabled in Info.plist | Add `remote-notification` to UIBackgroundModes in Info.plist |
| FD508 | Info | iOS version < 12.0 | iOS deployment target is below 12.0 | Update platform in Podfile: `platform :ios, '12.0'` |
| FD509 | Info | Firebase imports in main.dart | GoogleService-Info.plist exists but no Firebase imports found in Dart files | Add `import 'package:firebase_core/firebase_core.dart'` to your Dart code |

---

## FCM Analyzer (FD600 series)

Analyzes Firebase Cloud Messaging setup: dependency, Dart usage, background handlers, iOS proxy settings.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD601 | Warning | Missing firebase_messaging dependency | firebase_messaging is not declared in pubspec.yaml while Firebase config files exist | Add `firebase_messaging: ^15.0.0` to your dependencies |
| FD602 | Info | FCM usage not found | firebase_messaging is declared but no FirebaseMessaging usage found | Import and use firebase_messaging: `import 'package:firebase_messaging/firebase_messaging.dart'` |
| FD603 | Info | No background message handler configured | No background message handler registered with onBackgroundMessage | Register a top-level handler: `FirebaseMessaging.onBackgroundMessage(handler)` |
| FD604 | Warning | FirebaseAppDelegateProxyEnabled set to false | FirebaseAppDelegateProxyEnabled is set to false in Info.plist | Remove the key or set to true — Firebase method swizzling is required for FCM |
| FD605 | Info | No permission request found | Notification permission request not found | Call `messaging.requestPermission()` for iOS and Android 13+ |
| FD606 | Info | No token refresh handler | No token refresh handler registered with onTokenRefresh | Listen for token refreshes: `FirebaseMessaging.instance.onTokenRefresh.listen(...)` |

---

## Crashlytics Analyzer (FD700 series)

Analyzes Firebase Crashlytics configuration: dependency, Dart usage, Gradle plugin, CocoaPods, dSYM upload.

| Code | Severity | Title | Description | Recommendation |
|------|----------|-------|-------------|----------------|
| FD700 | Warning | Missing firebase_crashlytics dependency | firebase_crashlytics is not declared in pubspec.yaml | Add `firebase_crashlytics: ^4.0.0` to your dependencies |
| FD701 | Info | Crashlytics not initialized | FirebaseCrashlytics is not used in Dart files | Import and use Crashlytics: `import 'package:firebase_crashlytics/firebase_crashlytics.dart'` |
| FD702 | Info | runZonedGuarded not detected | runZonedGuarded is not used for crash reporting | Wrap main() with `runZonedGuarded` to catch async errors |
| FD703 | Info | FlutterError.onError not overridden | FlutterError.onError is not set for crash reporting | Set `FlutterError.onError` to forward errors to Crashlytics |
| FD704 | Info | PlatformDispatcher.onError not detected | PlatformDispatcher.onError is not set for crash reporting | Set `PlatformDispatcher.instance.onError` to record platform errors |
| FD705 | Info | setCrashlyticsCollectionEnabled not found | setCrashlyticsCollectionEnabled is not used | Configure: `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true)` |
| FD706 | Info | Missing Crashlytics custom keys | No custom keys found in Crashlytics implementation | Add `setCustomKey` calls for crash context |
| FD707 | Info | Missing Crashlytics user identification | No user identification methods (setUserIdentifier) found | Add `setUserIdentifier` to associate crashes with users |
| FD708 | Error | Missing Crashlytics Gradle plugin | Crashlytics Gradle plugin not found in Android build.gradle | Add `id "com.google.firebase.crashlytics" version "3.0.0"` to your app-level build.gradle |
| FD709 | Info | Missing Crashlytics build configuration | Crashlytics build configuration not found in build.gradle | Add `firebaseCrashlytics { nativeSymbolUploadEnabled = true }` block |
| FD710 | Error | Missing Crashlytics CocoaPods pod | Firebase/Crashlytics pod not found in Podfile | Add `pod 'Firebase/Crashlytics'` to your Podfile |
| FD711 | Info | Missing dSYM upload configuration | dSYM upload script not configured for Crashlytics | Configure dSYM upload script in Xcode build phases |

---

## Troubleshooting Common Scenarios

### Scenario: Missing Firebase configuration files

If you see FD400 (critical) and FD500 (critical), you likely haven't run `flutterfire configure`:

```bash
# Install the Firebase CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure

# Re-run FireDoctor to verify
firedoctor doctor
```

### Scenario: Initialization order issues

If you see FD306 (warning) and FD307 (warning), your main function needs restructuring:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();          // Fix FD307
  await Firebase.initializeApp(                       // Fix FD306
    options: DefaultFirebaseOptions.currentPlatform,  // Fix FD303
  );
  runApp(const MyApp());
}
```

### Scenario: Missing Crashlytics on Android

If you see FD708 (error), add the Crashlytics Gradle plugin to `android/app/build.gradle`:

```gradle
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
    id 'com.google.firebase.crashlytics'              // Add this line
}
```

### Scenario: Push notifications not working

If you see FD505, FD506, FD507, FD602, and FD605 together, several items need attention:

1. Enable Push Notifications and Background Modes in Xcode capabilities
2. Add `remote-notification` to `UIBackgroundModes` in Info.plist
3. Request notification permission: `await messaging.requestPermission()`
4. Register background message handler: `FirebaseMessaging.onBackgroundMessage(handler)`
