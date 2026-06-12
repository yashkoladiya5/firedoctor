/// Script to generate expected_findings.json for all validation projects.
/// Usage: dart run validation/generate_expected.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final projectsDir = Directory('validation/projects');
  final entries = projectsDir.listSync()..sort((a, b) => a.path.compareTo(b.path));

  for (final entry in entries) {
    if (entry is! Directory) continue;
    final projectPath = entry.path;
    final projectName = entry.path.split('/').last;

    print('Generating expected findings for $projectName...');
    final findings = generateForProject(projectPath, projectName);
    final output = {
      'projectName': projectName,
      'expectedFindings': findings,
    };
    final json = const JsonEncoder.withIndent('  ').convert(output);

    final outputPath = '$projectPath/expected_findings.json';
    File(outputPath).writeAsStringSync(json);
    print('  Wrote ${findings.length} entries to $outputPath');
  }

  print('\nDone!');
}

List<Map<String, dynamic>> generateForProject(String projectPath, String name) {
  final pubspecPath = '$projectPath/pubspec.yaml';
  final hasPubspec = File(pubspecPath).existsSync();
  final pubspec = hasPubspec ? File(pubspecPath).readAsStringSync() : '';

  final hasFlutterSdk = pubspec.contains('flutter:');
  final isFlutterProject = hasPubspec && hasFlutterSdk;
  final pubspecIsMalformed = name.contains('broken') && hasPubspec && !pubspec.contains('name:');

  final deps = _parseDependencies(pubspec);
  final hasFirebaseCore = deps.contains('firebase_core');
  final hasFirebaseMessaging = deps.contains('firebase_messaging');
  final hasCrashlytics = deps.contains('firebase_crashlytics');
  final hasFirebaseAnalytics = deps.contains('firebase_analytics');
  final hasFirebaseAuth = deps.contains('firebase_auth');
  final hasCloudFirestore = deps.contains('cloud_firestore');
  final hasFirebaseDependency = deps.any((d) => d.startsWith('firebase') || d.startsWith('cloud_'));

  final libDir = Directory('$projectPath/lib');
  final allDartCode = libDir.existsSync()
      ? libDir.listSync(recursive: true)
          .where((f) => f is File && f.path.endsWith('.dart'))
          .cast<File>()
          .map((f) => f.readAsStringSync())
          .join('\n')
      : '';
  final hasCrashlyticsImport = allDartCode.contains('package:firebase_crashlytics');
  final hasMessagingImport = allDartCode.contains('package:firebase_messaging');

  final hasAndroidDir = Directory('$projectPath/android').existsSync();
  final hasIOSDir = Directory('$projectPath/ios').existsSync();
  final hasLibDir = libDir.existsSync();
  final hasTestDir = Directory('$projectPath/test').existsSync();
  final hasFirebaseOptions = File('$projectPath/lib/firebase_options.dart').existsSync();

  final hasInitializeApp = allDartCode.contains('Firebase.initializeApp');
  final hasEnsureInitialized = allDartCode.contains('WidgetsFlutterBinding.ensureInitialized');
  final hasRunZonedGuarded = allDartCode.contains('runZonedGuarded');
  final hasErrorOnPlatformDispatcher = allDartCode.contains('PlatformDispatcher');
  final initCount = 'Firebase.initializeApp'.allMatches(allDartCode).length;

  final infoPlistPath = '$projectPath/ios/Runner/Info.plist';
  final hasInfoPlist = File(infoPlistPath).existsSync();
  final infoPlist = hasInfoPlist ? File(infoPlistPath).readAsStringSync() : '';
  final hasRemoteNotificationMode = infoPlist.contains('remote-notification');

  final podfilePath = '$projectPath/ios/Podfile';
  final hasPodfile = File(podfilePath).existsSync();
  final podfile = hasPodfile ? File(podfilePath).readAsStringSync() : '';
  final iosVersionMatch = RegExp("platform\\s*:ios,\\s*['\"](\\d+\\.\\d+)['\"]").firstMatch(podfile);
  final iosVersion = iosVersionMatch != null ? double.parse(iosVersionMatch.group(1)!) : null;

  final buildGradlePath = '$projectPath/android/app/build.gradle';
  final hasBuildGradle = File(buildGradlePath).existsSync();
  final buildGradle = hasBuildGradle ? File(buildGradlePath).readAsStringSync() : '';

  final hasNotificationPermission = allDartCode.contains('requestPermission') ||
      allDartCode.contains('NotificationSettings');
  final hasTokenRefreshListener = allDartCode.contains('onTokenRefresh') ||
      allDartCode.contains('getToken');
  final hasBackgroundHandler = allDartCode.contains('firebaseMessagingBackgroundHandler') ||
      allDartCode.contains('FirebaseMessaging.onBackgroundMessage');

  final genuinelyUsesFirebase = hasInitializeApp;
  final genuinelyUsesCrashlytics = hasCrashlyticsImport || hasCrashlytics;
  final genuinelyUsesFCM = hasMessagingImport || hasFirebaseMessaging;
  final hasFirebaseAppDelegateProxyEnabled = infoPlist.contains('FirebaseAppDelegateProxyEnabled');

  final expected = <Map<String, dynamic>>[];

  void add(String code, bool shouldBeFound) {
    final prefix = code.length >= 3 ? code.substring(0, 3) : '';
    final analyzerName = switch (prefix) {
      'FD1' => 'project',
      'FD2' => 'dependency',
      'FD3' => 'firebase_core',
      'FD4' => 'android',
      'FD5' => 'ios',
      'FD6' => 'fcm',
      'FD7' => 'crashlytics',
      _ => 'project',
    };
    expected.add({'code': code, 'shouldBeFound': shouldBeFound, 'analyzerName': analyzerName});
  }

  // Project analyzer
  add('MISSING_PUBSPEC', false);
  add('INVALID_PUBSPEC', pubspecIsMalformed);
  add('NOT_FLUTTER_PROJECT', !isFlutterProject);
  add('MISSING_ANDROID', isFlutterProject && !hasAndroidDir);
  add('MISSING_IOS', isFlutterProject && !hasIOSDir);
  add('MISSING_LIB', isFlutterProject && !hasLibDir);
  add('MISSING_TEST', isFlutterProject && !hasTestDir);
  add('FLUTTER_SDK_CONSTRAINT', isFlutterProject);

  // Dependency analyzer
  add('FD200', hasFirebaseDependency && !hasFirebaseCore);
  add('FD201', false);
  add('FD202', false);
  add('FD203', hasFirebaseCore && !hasFirebaseAnalytics);
  add('FD204', hasFirebaseCore && !hasCloudFirestore);
  add('FD205', hasFirebaseCore && !hasFirebaseAuth);

  // Firebase Core
  add('FD300', hasFirebaseCore && !hasInitializeApp);
  add('FD301', hasFirebaseCore && !hasFirebaseOptions);
  add('FD302', genuinelyUsesFirebase && !hasEnsureInitialized);
  add('FD303', genuinelyUsesFirebase && !allDartCode.contains('DefaultFirebaseOptions'));
  add('FD304', genuinelyUsesFirebase && initCount >= 2);
  add('FD305', false);
  add('FD306', false);
  add('FD307', hasInitializeApp && !hasFirebaseCore);

  // Android
  add('FD400', hasAndroidDir && !File('$projectPath/android/app/google-services.json').existsSync());
  add('FD401', false);
  add('FD402', false);
  // FD403 only fires if build.gradle exists but lacks google-services plugin
  add('FD403', hasBuildGradle && !buildGradle.contains('google-services'));
  // FD404 only fires if AndroidManifest.xml exists but lacks INTERNET permission
  final manifestPath = '$projectPath/android/app/src/main/AndroidManifest.xml';
  final hasAndroidManifest = File(manifestPath).existsSync();
  final manifestContent = hasAndroidManifest ? File(manifestPath).readAsStringSync() : '';
  final hasInternetPermission = manifestContent.contains('android.permission.INTERNET');
  add('FD404', hasAndroidManifest && !hasInternetPermission);
  add('FD405', false);
  add('FD406', false);
  add('FD407', false);
  add('FD408', false);
  add('FD409', false);

  // iOS
  final hasGoogleServicesPlist = File('$projectPath/ios/Runner/GoogleService-Info.plist').existsSync();
  add('FD500', hasIOSDir && !hasGoogleServicesPlist);
  add('FD501', false);
  add('FD502', false);
  add('FD503', false);
  // FD504-FD506 require Xcode project file (project.pbxproj) to exist
  final pbxprojPath = '$projectPath/ios/Runner.xcodeproj/project.pbxproj';
  final hasPbxproj = File(pbxprojPath).existsSync();
  add('FD504', hasIOSDir && !hasPbxproj);
  add('FD505', genuinelyUsesFCM && hasPbxproj);
  add('FD506', genuinelyUsesFCM && hasPbxproj);
  add('FD507', genuinelyUsesFCM && hasInfoPlist && !hasRemoteNotificationMode);
  add('FD508', hasIOSDir && !File('$projectPath/ios/Podfile').existsSync());
  add('FD509', hasIOSDir && iosVersion != null && iosVersion < 12.0);
  add('FD510', hasIOSDir && hasFirebaseCore && podfile.isNotEmpty && !podfile.contains(RegExp(r'firebase|Firebase')));
  add('FD511', false);
  // FD512 requires both GoogleService-Info.plist AND Info.plist to exist
  add('FD512', genuinelyUsesFCM && hasGoogleServicesPlist && hasInfoPlist && !hasFirebaseAppDelegateProxyEnabled);

  // FCM
  add('FD600', genuinelyUsesFCM && !hasFirebaseMessaging);
  add('FD601', genuinelyUsesFCM && !hasInitializeApp);
  add('FD602', genuinelyUsesFCM && !hasNotificationPermission);
  add('FD603', genuinelyUsesFCM && !hasBackgroundHandler);
  add('FD604', genuinelyUsesFCM && hasFirebaseAppDelegateProxyEnabled);
  add('FD605', genuinelyUsesFCM && !hasTokenRefreshListener);

  // Crashlytics
  add('FD700', genuinelyUsesCrashlytics && !hasCrashlytics);
  add('FD701', genuinelyUsesCrashlytics && !hasCrashlyticsImport);
  add('FD702', genuinelyUsesCrashlytics && !allDartCode.contains('FlutterError.onError'));
  add('FD703', genuinelyUsesCrashlytics && !hasErrorOnPlatformDispatcher);
  add('FD704', genuinelyUsesCrashlytics && !hasRunZonedGuarded);
  add('FD705', genuinelyUsesCrashlytics && allDartCode.contains('crashlyticsCollectionEnabled'));
  add('FD706', genuinelyUsesCrashlytics && !allDartCode.contains('recordError'));
  // FD707 only fires if crashlytics is used AND none of the error strategies are present
  // It requires no FlutterError.onError, no PlatformDispatcher.onError, AND no recordError
  final hasFlutterErrorOnError = allDartCode.contains('FlutterError.onError');
  final hasRecordError = allDartCode.contains('recordError');
  add('FD707', genuinelyUsesCrashlytics && !hasFlutterErrorOnError && !hasErrorOnPlatformDispatcher && !hasRecordError);
  // FD708/FD709 only fire if build.gradle exists (same as android analyzer)
  add('FD708', genuinelyUsesCrashlytics && hasBuildGradle && !buildGradle.contains('crashlytics'));
  add('FD709', genuinelyUsesCrashlytics && hasBuildGradle);
  // FD710/FD711: check Podfile + Podfile.lock for crashlytics
  // FD710: Crashlytics CocoaPod must be in Podfile OR Podfile.lock
  final hasCrashlyticsInPodfile =
      podfile.contains('Firebase/Crashlytics') || podfile.contains('FirebaseCrashlytics');
  final podfileLockPath = '$projectPath/ios/Podfile.lock';
  final hasPodfileLock = File(podfileLockPath).existsSync();
  final podfileLockContent = hasPodfileLock ? File(podfileLockPath).readAsStringSync() : '';
  final hasCrashlyticsInPodfileLock = podfileLockContent.contains('FirebaseCrashlytics');
  add('FD710', genuinelyUsesCrashlytics && hasIOSDir && !hasCrashlyticsInPodfile && !hasCrashlyticsInPodfileLock);
  // FD711: dSYM upload requires FirebaseCrashlytics in Podfile.lock
  add('FD711', genuinelyUsesCrashlytics && hasIOSDir && !hasCrashlyticsInPodfileLock);
  add('FD712', genuinelyUsesCrashlytics);
  add('FD713', genuinelyUsesCrashlytics);

  return expected;
}

Set<String> _parseDependencies(String pubspec) {
  final knownFirebasePkgs = {
    'firebase_core', 'firebase_analytics', 'firebase_auth', 'firebase_crashlytics',
    'firebase_messaging', 'firebase_storage', 'firebase_database', 'firebase_remote_config',
    'firebase_dynamic_links', 'firebase_app_check', 'firebase_app_installations',
    'firebase_in_app_messaging', 'firebase_ml_model_downloader', 'firebase_performance',
    'firebase_vertexai', 'cloud_firestore', 'cloud_functions',
  };
  final deps = <String>{};
  for (final line in pubspec.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
    for (final pkg in knownFirebasePkgs) {
      if (trimmed.startsWith('$pkg:')) {
        deps.add(pkg);
        break;
      }
    }
  }
  return deps;
}
