import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/parsers/pubspec_parser.dart';
import 'package:firedoctor/analyzers/ios/parsers/plist_parser.dart';

final class FCMAnalyzer extends Analyzer {
  final PlistParser _plistParser;

  FCMAnalyzer({PlistParser? plistParser})
      : _plistParser = plistParser ?? const PlistParser();

  @override
  String get name => 'fcm';

  @override
  String get description => 'Analyzes Firebase Cloud Messaging configuration';

  @override
  String get category => 'fcm';

  @override
  Future<DiagnosticResult> analyze(AnalyzerContext context) async {
    final startTime = DateTime.now();
    final issues = <DiagnosticIssue>[];
    final fs = context.fileSystem;
    final projectPath = context.projectPath;

    final pubspecPath = fs.join(projectPath, 'pubspec.yaml');
    if (!fs.exists(pubspecPath)) {
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.skipped,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final pubspec = await PubspecParser.parseFromFile(pubspecPath, fs);
    if (pubspec == null) {
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.skipped,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final hasFirebaseMessaging = pubspec.hasDependency('firebase_messaging') ||
        pubspec.hasDevDependency('firebase_messaging');

    final iosPlistPath = fs.join(
      fs.join(fs.join(projectPath, 'ios', 'Runner'), 'GoogleService-Info.plist'),
    );
    final androidServicesPath = fs.join(
      fs.join(projectPath, 'android', 'app'),
      'google-services.json',
    );

    final hasIosConfig = fs.exists(iosPlistPath);
    final hasAndroidConfig = fs.exists(androidServicesPath);

    // FD600: firebase_messaging dependency missing
    if (!hasFirebaseMessaging && (hasIosConfig || hasAndroidConfig)) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD600',
        title: 'Missing firebase_messaging dependency',
        description:
            'Firebase configuration files exist but firebase_messaging is '
            'not declared in pubspec.yaml. Firebase Cloud Messaging '
            'requires this package for push notifications.',
        recommendation:
            'Add firebase_messaging to your dependencies:\n'
            '  firebase_messaging: ^15.0.0',
        filePath: pubspecPath,
      ));
    }

    // Scan Dart files for FCM usage, permission requests, background handler, token refresh
    bool hasFcmUsage = false;
    bool hasPermissionRequest = false;
    bool hasBackgroundHandler = false;
    bool hasTokenRefresh = false;

    if (hasFirebaseMessaging) {
      final dartFiles = context.sourceFileCache?.getDartFiles(projectPath) ?? [];

      for (final filePath in dartFiles) {
        final lines = context.sourceFileCache?.getLines(filePath);
        if (lines == null) continue;

        for (final line in lines) {
          if (line.contains('FirebaseMessaging')) {
            hasFcmUsage = true;
          }
          if (line.contains('requestPermission(') ||
              line.contains('requestPermission()')) {
            hasPermissionRequest = true;
          }
          if (line.contains('FirebaseMessaging.onBackgroundMessage(')) {
            hasBackgroundHandler = true;
          }
          if (line.contains('onTokenRefresh') ||
              line.contains('getToken(') ||
              line.contains('.getToken()')) {
            hasTokenRefresh = true;
          }
        }
      }
    }

    // FD601: FCM not used in Dart code
    if (hasFirebaseMessaging && !hasFcmUsage) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD601',
        title: 'FCM not initialized in Dart code',
        description:
            'firebase_messaging is declared as a dependency but no '
            'FirebaseMessaging references were found in Dart files under lib/.',
        recommendation:
            'Import and use firebase_messaging in your Dart code:\n'
            "  import 'package:firebase_messaging/firebase_messaging.dart';",
        filePath: pubspecPath,
      ));
    }

    // FD602: Notification permission not requested
    if (hasFcmUsage && !hasPermissionRequest) {
      issues.add(const DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD602',
        title: 'Notification permission not requested',
        description:
            'FCM usage was detected but no notification permission request '
            'was found. On iOS and Android 13+, push notifications require '
            'explicit user permission.',
        recommendation:
            'Request notification permission after initializing Firebase:\n'
            '  NotificationSettings settings = await messaging.requestPermission();',
      ));
    }

    // FD603: No background message handler
    if (hasFcmUsage && !hasBackgroundHandler) {
      issues.add(const DiagnosticIssue(
        severity: Severity.info,
        code: 'FD603',
        title: 'No background message handler configured',
        description:
            'No FirebaseMessaging.onBackgroundMessage handler was found. '
            'Without this, messages received when the app is terminated '
            'will not be handled.',
        recommendation:
            'Add a top-level background message handler:\n'
            "  @pragma('vm:entry-point')\n"
            '  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {\n'
            '    await Firebase.initializeApp();\n'
            '  }\n'
            '  void main() {\n'
            '    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);\n'
            '  }',
      ));
    }

    // FD604: iOS FirebaseAppDelegateProxyEnabled set to false
    if (hasIosConfig || hasFirebaseMessaging) {
      final infoPlistPath = fs.join(
        fs.join(projectPath, 'ios', 'Runner'),
        'Info.plist',
      );
      if (fs.exists(infoPlistPath)) {
        final infoPlistContent = fs.readAsString(infoPlistPath);
        final proxyValue =
            _plistParser.parseFirebaseAppDelegateProxyValue(infoPlistContent);
        if (proxyValue == false) {
          issues.add(DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD604',
            title: 'FirebaseAppDelegateProxyEnabled set to false',
            description:
                'FirebaseAppDelegateProxyEnabled is explicitly set to false '
                'in Info.plist. This disables Firebase method swizzling, '
                'which is required for the Firebase Messaging plugin to work.',
            recommendation:
                'Remove the FirebaseAppDelegateProxyEnabled key from Info.plist '
                'or set it to true:\n'
                '  <key>FirebaseAppDelegateProxyEnabled</key>\n'
                '  <true/>',
            filePath: infoPlistPath,
          ));
        }
      }
    }

    // FD605: No token refresh listener
    if (hasFcmUsage && !hasTokenRefresh) {
      issues.add(const DiagnosticIssue(
        severity: Severity.info,
        code: 'FD605',
        title: 'No FCM token refresh listener',
        description:
            'No onTokenRefresh or getToken call found. FCM tokens can '
            'change (app reinstall, restore, refresh) and without handling '
            'token updates, push notifications may silently fail.',
        recommendation:
            'Listen for token refreshes:\n'
            '  FirebaseMessaging.instance.onTokenRefresh.listen((token) {\n'
            '    // Send token to your server\n'
            '  });',
      ));
    }

    final hasCriticalOrError = issues.any(
      (i) => i.severity == Severity.critical || i.severity == Severity.error,
    );
    final hasWarning = issues.any((i) => i.severity == Severity.warning);

    CheckStatus status;
    if (hasCriticalOrError) {
      status = CheckStatus.failed;
    } else if (hasWarning) {
      status = CheckStatus.warning;
    } else {
      status = CheckStatus.passed;
    }

    return DiagnosticResult(
      analyzerName: name,
      status: status,
      issues: issues,
      duration: DateTime.now().difference(startTime),
      timestamp: DateTime.now(),
    );
  }
}
