import 'package:test/test.dart';
import 'package:firedoctor/analyzers/fcm/fcm_analyzer.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

FakeFileSystem _createProject({
  required String pubspecContent,
  Map<String, String> dartFiles = const {},
  bool hasIosConfig = false,
  bool hasAndroidConfig = false,
  bool hasIosDir = false,
  Map<String, String> plistFiles = const {},
}) {
  final fs = FakeFileSystem();
  fs.addFile('/project/pubspec.yaml', pubspecContent);
  fs.addDirectory('/project/lib');

  if (hasIosConfig) {
    fs.addDirectory('/project/ios');
    fs.addDirectory('/project/ios/Runner');
    fs.addFile(
      '/project/ios/Runner/GoogleService-Info.plist',
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<plist version="1.0"><dict>'
      '<key>BUNDLE_ID</key><string>com.example.app</string>'
      '</dict></plist>',
    );
  }

  if (hasIosDir) {
    fs.addDirectory('/project/ios');
    fs.addDirectory('/project/ios/Runner');
  }

  if (hasAndroidConfig) {
    fs.addDirectory('/project/android');
    fs.addDirectory('/project/android/app');
    fs.addFile(
      '/project/android/app/google-services.json',
      '{"project_info": {"project_number": "123"}, "client": []}',
    );
  }

  for (final entry in plistFiles.entries) {
    fs.addFile(entry.key, entry.value);
  }

  for (final entry in dartFiles.entries) {
    fs.addFile(entry.key, entry.value);
  }
  return fs;
}

FakeFileSystem _createProjectWithMain(
  String mainContent, {
  bool withFirebaseMessaging = true,
  bool hasIosConfig = false,
  bool hasAndroidConfig = false,
  bool hasIosDir = false,
  Map<String, String> additionalFiles = const {},
  Map<String, String> plistFiles = const {},
}) {
  final buffer = StringBuffer();
  buffer.writeln('name: test_app');
  buffer.writeln('dependencies:');
  if (withFirebaseMessaging) {
    buffer.writeln('  firebase_messaging: ^15.0.0');
  }
  buffer.writeln('  flutter:');
  buffer.writeln('    sdk: flutter');
  buffer.writeln('dev_dependencies: {}');

  return _createProject(
    pubspecContent: buffer.toString(),
    dartFiles: {
      '/project/lib/main.dart': mainContent,
      ...additionalFiles,
    },
    hasIosConfig: hasIosConfig,
    hasAndroidConfig: hasAndroidConfig,
    hasIosDir: hasIosDir,
    plistFiles: plistFiles,
  );
}

const _fcmUsageMain = '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final messaging = FirebaseMessaging.instance;
  runApp(const MyApp());
}
''';

const _fcmWithPermission = '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  runApp(const MyApp());
}
''';

const _fcmWithBackgroundHandler = '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final messaging = FirebaseMessaging.instance;
  runApp(const MyApp());
}
''';

const _fcmWithTokenRefresh = '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final messaging = FirebaseMessaging.instance;
  messaging.onTokenRefresh.listen((token) {
    print(token);
  });
  runApp(const MyApp());
}
''';

const _fcmWithGetToken = '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final messaging = FirebaseMessaging.instance;
  final token = await messaging.getToken();
  runApp(const MyApp());
}
''';

void main() {
  group('FCMAnalyzer', () {
    late FCMAnalyzer analyzer;

    setUp(() {
      analyzer = FCMAnalyzer();
    });

    group('metadata', () {
      test('has correct name', () {
        expect(analyzer.name, equals('fcm'));
      });

      test('has correct description', () {
        expect(
          analyzer.description,
          equals('Analyzes Firebase Cloud Messaging configuration'),
        );
      });

      test('has correct category', () {
        expect(analyzer.category, equals('fcm'));
      });
    });

    group('skipped conditions', () {
      test('returns skipped when pubspec.yaml does not exist', () async {
        final fs = FakeFileSystem();
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });

      test('returns skipped when pubspec.yaml is invalid', () async {
        final fs = FakeFileSystem();
        fs.addFile('/project/pubspec.yaml', '{{{');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });
    });

    group('FD600: missing firebase_messaging dependency', () {
      test(
          'emits FD600 when GoogleService-Info.plist exists but firebase_messaging not in deps',
          () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: false,
          hasIosConfig: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD600'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD600');
        expect(issue.severity, equals(Severity.warning));
        expect(issue.filePath, endsWith('pubspec.yaml'));
      });

      test(
          'emits FD600 when google-services.json exists but firebase_messaging not in deps',
          () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: false,
          hasAndroidConfig: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD600'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD600');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD600 when firebase_messaging is in deps', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: true,
          hasIosConfig: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD600'), isEmpty);
      });

      test(
          'does not emit FD600 when no Firebase config files exist and no deps',
          () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: false,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD600'), isEmpty);
      });
    });

    group('FD601: FCM not used in Dart code', () {
      test(
          'emits FD601 when firebase_messaging in deps but no FirebaseMessaging reference',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';
void main() {
  runApp(const MyApp());
}
''',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD601'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD601');
        expect(issue.severity, equals(Severity.warning));
        expect(issue.filePath, endsWith('pubspec.yaml'));
      });

      test('does not emit FD601 when FirebaseMessaging is referenced',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD601'), isEmpty);
      });

      test(
          'does not emit FD601 when firebase_messaging not in deps and no config',
          () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: false,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD601'), isEmpty);
      });
    });

    group('FD602: notification permission not requested', () {
      test(
          'emits FD602 when FCM usage found but no requestPermission call',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD602'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD602');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD602 when requestPermission is called', () async {
        final fs = _createProjectWithMain(
          _fcmWithPermission,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
      });

      test('does not emit FD602 when no FCM usage', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
      });
    });

    group('FD603: background message handler', () {
      test(
          'emits FD603 when FCM usage found but no onBackgroundMessage handler',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD603'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD603');
        expect(issue.severity, equals(Severity.info));
      });

      test(
          'does not emit FD603 when onBackgroundMessage is configured',
          () async {
        final fs = _createProjectWithMain(
          _fcmWithBackgroundHandler,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
      });

      test('does not emit FD603 when no FCM usage', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
      });
    });

    group('FD604: FirebaseAppDelegateProxyEnabled set to false', () {
      test(
          'emits FD604 when Info.plist has FirebaseAppDelegateProxyEnabled set to false',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
          hasIosDir: true,
          plistFiles: {
            '/project/ios/Runner/Info.plist':
                '<?xml version="1.0"?><plist><dict>'
                '<key>FirebaseAppDelegateProxyEnabled</key><false/>'
                '</dict></plist>',
          },
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD604'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD604');
        expect(issue.severity, equals(Severity.warning));
        expect(issue.filePath, endsWith('Info.plist'));
      });

      test(
          'does not emit FD604 when FirebaseAppDelegateProxyEnabled key is absent',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
          hasIosDir: true,
          plistFiles: {
            '/project/ios/Runner/Info.plist':
                '<?xml version="1.0"?><plist><dict>'
                '<key>SomeOtherKey</key><string>value</string>'
                '</dict></plist>',
          },
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD604'), isEmpty);
      });

      test(
          'does not emit FD604 when FirebaseAppDelegateProxyEnabled is set to true',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
          hasIosDir: true,
          plistFiles: {
            '/project/ios/Runner/Info.plist':
                '<?xml version="1.0"?><plist><dict>'
                '<key>FirebaseAppDelegateProxyEnabled</key><true/>'
                '</dict></plist>',
          },
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD604'), isEmpty);
      });

      test(
          'does not emit FD604 when Info.plist does not exist',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
          hasIosDir: false,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD604'), isEmpty);
      });
    });

    group('FD605: token refresh listener', () {
      test(
          'emits FD605 when FCM usage found but no onTokenRefresh or getToken',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD605'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD605');
        expect(issue.severity, equals(Severity.info));
      });

      test('does not emit FD605 when onTokenRefresh is used', () async {
        final fs = _createProjectWithMain(
          _fcmWithTokenRefresh,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });

      test('does not emit FD605 when getToken is called', () async {
        final fs = _createProjectWithMain(
          _fcmWithGetToken,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });

      test('does not emit FD605 when no FCM usage', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });
    });

    group('status computation', () {
      test('returns warning when FD600 present (warning only)', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withFirebaseMessaging: false,
          hasIosConfig: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
      });

      test(
          'returns warning when FD602 present (warning among info issues)',
          () async {
        final fs = _createProjectWithMain(
          _fcmUsageMain,
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
      });

      test('returns info status when only info issues present', () async {
        final fs = _createProjectWithMain(
          _fcmWithBackgroundHandler,
          withFirebaseMessaging: true,
          hasIosDir: true,
          plistFiles: {
            '/project/ios/Runner/Info.plist':
                '<?xml version="1.0"?><plist><dict>'
                '<key>FirebaseAppDelegateProxyEnabled</key><false/>'
                '</dict></plist>',
          },
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // FD604 is warning (false proxy) -> status should be warning
        expect(result.status, equals(CheckStatus.warning));
      });

      test('returns passed when no issues', () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';
void main() {
  runApp(const MyApp());
}
''',
          withFirebaseMessaging: false,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    group('edge cases', () {
      test('handles empty lib/ directory gracefully', () async {
        final fs = FakeFileSystem();
        fs.addFile('/project/pubspec.yaml',
            'name: test_app\ndependencies:\n  firebase_messaging: ^15.0.0\n  flutter:\n    sdk: flutter\ndev_dependencies: {}\n');
        fs.addDirectory('/project/lib');

        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Should have FD601 (FCM not used), but no FD602/603/605 (no FCM usage)
        expect(result.issues.any((i) => i.code == 'FD601'), isTrue);
        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });

      test(
          'handles FirebaseMessaging in string literals — no false positives for FD602/603/605',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final msg = "FirebaseMessaging.instance is not real usage";
  final perm = "requestPermission() is not a call";
  final bg = "FirebaseMessaging.onBackgroundMessage is in a string";
  final token = "onTokenRefresh is just a comment";
  runApp(const MyApp());
}
''',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // FirebaseMessaging only appears inside string literals, which are
        // stripped by the comment/string stripper. The import line uses
        // lowercase "firebase_messaging" which doesn't match "FirebaseMessaging".
        // So FD601 fires because no real FirebaseMessaging reference remains.
        expect(result.issues.any((i) => i.code == 'FD601'), isTrue);
        // FD602/603/605 require hasFcmUsage (no real usage after stripping),
        // so they correctly do NOT fire.
        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });

      test(
          'does not false-positive on FirebaseMessaging in comments',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // FirebaseMessaging.instance is commented out
  // requestPermission() is commented out
  // FirebaseMessaging.onBackgroundMessage is commented out
  // onTokenRefresh is commented out
  runApp(const MyApp());
}
''',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // All FirebaseMessaging references are in comments (stripped), and the
        // import line uses lowercase "firebase_messaging" which doesn't match.
        // So FD601 fires with no real reference remaining.
        expect(result.issues.any((i) => i.code == 'FD601'), isTrue);
        // FD602/603/605 require hasFcmUsage (no real usage after stripping),
        // so they correctly do NOT fire.
        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });

      test('handles case-sensitive detection', () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';

void main() {
  firebasemessaging.instance;
  requestpermission();
  runApp(const MyApp());
}
''',
          withFirebaseMessaging: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Lowercase firebasemessaging should NOT match FirebaseMessaging
        // So FD601 should fire (no real FirebaseMessaging reference)
        expect(result.issues.any((i) => i.code == 'FD601'), isTrue);
        // No FCM usage -> no FD602/603/605
        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD605'), isEmpty);
      });

      test('handles multiple Dart files with combined FCM setup', () async {
        final fs = _createProjectWithMain(
          _fcmWithPermission,
          withFirebaseMessaging: true,
          additionalFiles: {
            '/project/lib/handler.dart': '''
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
''',
            '/project/lib/listener.dart': '''
import 'package:firebase_messaging/firebase_messaging.dart';

void setupFcm() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
''',
          },
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Permission in main.dart, handler setup in listener.dart
        expect(result.issues.any((i) => i.code == 'FD600'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD601'), isFalse);
        expect(result.issues.where((i) => i.code == 'FD602'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD603'), isEmpty);
        // FD605 may still fire (no token refresh)
        expect(result.issues.any((i) => i.code == 'FD605'), isTrue);
      });
    });

    group('result metadata', () {
      test('result has correct analyzerName', () async {
        final fs = _createProjectWithMain('void main() {}');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.analyzerName, equals('fcm'));
      });

      test('result has non-zero duration', () async {
        final fs = _createProjectWithMain('void main() {}');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.duration.inMicroseconds, greaterThanOrEqualTo(0));
      });

      test('result has a recent timestamp', () async {
        final fs = _createProjectWithMain('void main() {}');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.timestamp.isAfter(DateTime(2020, 1, 1)), isTrue);
      });
    });
  });
}
