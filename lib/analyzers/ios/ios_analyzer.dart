import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/parsers/pubspec_parser.dart';
import 'parsers/parsers.dart';

/// Core class.
final class IOSAnalyzer extends Analyzer {
  final PlistParser _plistParser;
  final PodfileParser _podfileParser;
  final PodfileLockParser _podfileLockParser;
  final PbxprojParser _pbxprojParser;

  IOSAnalyzer({
    PlistParser? plistParser,
    PodfileParser? podfileParser,
    PodfileLockParser? podfileLockParser,
    PbxprojParser? pbxprojParser,
  }) : _plistParser = plistParser ?? const PlistParser(),
       _podfileParser = podfileParser ?? const PodfileParser(),
       _podfileLockParser = podfileLockParser ?? const PodfileLockParser(),
       _pbxprojParser = pbxprojParser ?? const PbxprojParser();

  @override
  String get name => 'ios';

  @override
  String get description => 'Analyzes iOS Firebase configuration';

  @override
  String get category => 'ios';

  @override
  /// Public method or function.
  Future<DiagnosticResult> analyze(AnalyzerContext context) async {
    final startTime = DateTime.now();
    final issues = <DiagnosticIssue>[];
    final fs = context.fileSystem;
    final projectPath = context.projectPath;

    final iosPath = fs.join(projectPath, 'ios');
    if (!fs.exists(iosPath) || !fs.isDirectory(iosPath)) {
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.skipped,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final googleServicePath = fs.join(
      fs.join(iosPath, 'Runner'),
      'GoogleService-Info.plist',
    );
    final podfilePath = fs.join(iosPath, 'Podfile');
    final podfileLockPath = fs.join(iosPath, 'Podfile.lock');
    final pbxprojPath = fs.join(
      fs.join(iosPath, 'Runner.xcodeproj'),
      'project.pbxproj',
    );
    final infoPlistPath = fs.join(fs.join(iosPath, 'Runner'), 'Info.plist');

    Map<String, String>? googleServiceInfo;
    if (!fs.exists(googleServicePath)) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.critical,
          code: 'FD500',
          title: 'Missing GoogleService-Info.plist',
          description:
              'The ios/Runner/GoogleService-Info.plist file is missing. '
              'This file is required for Firebase services on iOS.',
          recommendation:
              'Run "flutterfire configure" to generate the '
              'GoogleService-Info.plist file or download it from Firebase Console.',
          filePath: googleServicePath,
        ),
      );
    } else {
      final content = fs.readAsString(googleServicePath);
      googleServiceInfo = _plistParser.parseGoogleServiceInfoPlist(content);

      if (googleServiceInfo == null) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.error,
            code: 'FD501',
            title: 'Invalid GoogleService-Info.plist',
            description:
                'The GoogleService-Info.plist file contains invalid or malformed content.',
            recommendation:
                'Regenerate the file using "flutterfire configure" '
                'or download a fresh copy from Firebase Console.',
            filePath: googleServicePath,
          ),
        );
      }
    }

    String? podfileContent;
    if (!fs.exists(podfilePath)) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.error,
          code: 'FD508',
          title: 'Missing Podfile',
          description:
              'The ios/Podfile file is missing. This file is required for '
              'managing iOS dependencies.',
          recommendation:
              'Run "flutter create ." in the ios directory or '
              'create a Podfile manually.',
          filePath: podfilePath,
        ),
      );
    } else {
      podfileContent = fs.readAsString(podfilePath);
    }

    ({
      String? bundleIdentifier,
      String? runnerTargetName,
      bool hasPushCapability,
      bool hasBackgroundModes,
    })?
    pbxprojInfo;
    if (fs.exists(pbxprojPath)) {
      final pbxprojContent = fs.readAsString(pbxprojPath);
      pbxprojInfo = _pbxprojParser.parse(pbxprojContent);
    }

    ({List<String> backgroundModes, bool hasFirebaseAppDelegateProxy})?
    infoPlistInfo;
    if (fs.exists(infoPlistPath)) {
      final infoPlistContent = fs.readAsString(infoPlistPath);
      infoPlistInfo = _plistParser.parseInfoPlist(infoPlistContent);
    }

    if (googleServiceInfo != null &&
        googleServiceInfo['BUNDLE_ID'] != null &&
        pbxprojInfo != null &&
        pbxprojInfo.bundleIdentifier != null) {
      final plistBundleId = googleServiceInfo['BUNDLE_ID']!;
      if (plistBundleId != pbxprojInfo.bundleIdentifier) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.error,
            code: 'FD502',
            title: 'Bundle ID mismatch in GoogleService-Info.plist',
            description:
                'The bundle ID "$plistBundleId" in GoogleService-Info.plist '
                'does not match the PRODUCT_BUNDLE_IDENTIFIER '
                '"${pbxprojInfo.bundleIdentifier}" in the Xcode project.',
            recommendation:
                'Update the PRODUCT_BUNDLE_IDENTIFIER in your Xcode project or '
                'regenerate GoogleService-Info.plist with '
                '"flutterfire configure".',
            filePath: googleServicePath,
          ),
        );
      }
    }

    if (pbxprojInfo != null && pbxprojInfo.bundleIdentifier == null) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.warning,
          code: 'FD503',
          title: 'Bundle identifier not detected',
          description:
              'Could not detect the bundle identifier from the Xcode project.',
          recommendation:
              'Ensure PRODUCT_BUNDLE_IDENTIFIER is set in your Xcode project settings.',
          filePath: pbxprojPath,
        ),
      );
    }

    if (pbxprojInfo != null && pbxprojInfo.runnerTargetName == null) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.error,
          code: 'FD504',
          title: 'Runner target not found in Xcode project',
          description:
              'The "Runner" target was not found in the Xcode project file.',
          recommendation:
              'Ensure the Xcode project contains a target named "Runner".',
          filePath: pbxprojPath,
        ),
      );
    }

    if (pbxprojInfo != null && !pbxprojInfo.hasPushCapability) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.warning,
          code: 'FD505',
          title: 'Push Notifications capability missing',
          description:
              'The Push Notifications capability is not enabled in the Xcode project.',
          recommendation:
              'Enable Push Notifications in Xcode: '
              'Signing & Capabilities > + Capability > Push Notifications.',
          filePath: pbxprojPath,
        ),
      );
    }

    if (pbxprojInfo != null && !pbxprojInfo.hasBackgroundModes) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.warning,
          code: 'FD506',
          title: 'Background Modes capability missing',
          description:
              'The Background Modes capability is not enabled in the Xcode project.',
          recommendation:
              'Enable Background Modes in Xcode: '
              'Signing & Capabilities > + Capability > Background Modes.',
          filePath: pbxprojPath,
        ),
      );
    }

    // Only flag missing remote-notification background mode if the project
    // actually uses Firebase Cloud Messaging
    bool needsRemoteNotifications = false;
    if (!needsRemoteNotifications) {
      final pubspecPath = fs.join(projectPath, 'pubspec.yaml');
      if (fs.exists(pubspecPath)) {
        final pubspec = await PubspecParser.parseFromFile(pubspecPath, fs);
        needsRemoteNotifications =
            pubspec != null &&
            (pubspec.hasDependency('firebase_messaging') ||
                pubspec.hasDevDependency('firebase_messaging'));
      }
    }

    if (infoPlistInfo != null &&
        needsRemoteNotifications &&
        !infoPlistInfo.backgroundModes.contains('remote-notification')) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.warning,
          code: 'FD507',
          title: 'Remote Notifications background mode missing',
          description:
              'The "remote-notification" background mode is not configured in Info.plist.',
          recommendation:
              'Add "remote-notification" to UIBackgroundModes in Info.plist:\n'
              '  <key>UIBackgroundModes</key>\n'
              '  <array>\n'
              '    <string>remote-notification</string>\n'
              '  </array>',
          filePath: infoPlistPath,
        ),
      );
    }

    ({
      double? iosVersion,
      bool hasFirebasePods,
      List<String> pods,
      bool hasRunnerTarget,
    })?
    podfileInfo;
    if (podfileContent != null) {
      podfileInfo = _podfileParser.parse(podfileContent);
      if (podfileInfo != null &&
          podfileInfo.iosVersion != null &&
          podfileInfo.iosVersion! < 12.0) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD509',
            title: 'iOS platform version below 12.0 in Podfile',
            description:
                'The Podfile platform version is set to ${podfileInfo.iosVersion}. '
                'Firebase SDKs require iOS 12.0 or higher.',
            recommendation:
                'Update the platform version in your Podfile:\n'
                '  platform :ios, \'12.0\'',
            filePath: podfilePath,
          ),
        );
      }
    }

    bool hasFirebasePods = false;
    if (podfileInfo != null && podfileInfo.hasFirebasePods) {
      hasFirebasePods = true;
    } else if (fs.exists(podfileLockPath)) {
      final lockContent = fs.readAsString(podfileLockPath);
      final lockInfo = _podfileLockParser.parse(lockContent);
      if (lockInfo.hasFirebasePods) {
        hasFirebasePods = true;
      }
    }

    if (!hasFirebasePods &&
        (googleServiceInfo != null || fs.exists(podfilePath))) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.warning,
          code: 'FD510',
          title: 'No Firebase pods found',
          description:
              'No Firebase pods were found in the Podfile or Podfile.lock.',
          recommendation:
              'Add Firebase pods to your Podfile:\n'
              '  pod \'Firebase/Core\'',
          filePath: podfilePath,
        ),
      );
    }

    if (googleServiceInfo != null) {
      final libPath = fs.join(projectPath, 'lib');
      bool hasFirebaseImport = false;
      if (fs.exists(libPath) && fs.isDirectory(libPath)) {
        hasFirebaseImport = _scanForFirebaseImports(fs, libPath);
      }
      if (!hasFirebaseImport) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.info,
            code: 'FD511',
            title: 'GoogleService-Info.plist not referenced',
            description:
                'GoogleService-Info.plist exists but no Firebase imports '
                'were found in Dart files.',
            recommendation:
                'Add Firebase to your Dart code:\n'
                '  import \'package:firebase_core/firebase_core.dart\';',
            filePath: googleServicePath,
          ),
        );
      }
    }

    if (googleServiceInfo != null &&
        infoPlistInfo != null &&
        !infoPlistInfo.hasFirebaseAppDelegateProxy) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.info,
          code: 'FD512',
          title: 'APNs configuration warning',
          description:
              'FirebaseAppDelegateProxyEnabled is not configured in Info.plist. '
              'Without this setting, Firebase may not properly handle APNs '
              'token registration.',
          recommendation:
              'Consider adding to your Info.plist:\n'
              '  <key>FirebaseAppDelegateProxyEnabled</key>\n'
              '  <false/>',
          filePath: infoPlistPath,
        ),
      );
    }

    final hasCriticalOrError = issues.any(
      (i) => i.severity == Severity.critical || i.severity == Severity.error,
    );
    final hasWarning = issues.any((i) => i.severity == Severity.warning);

    final status = hasCriticalOrError
        ? CheckStatus.failed
        : hasWarning
        ? CheckStatus.warning
        : CheckStatus.passed;

    return DiagnosticResult(
      analyzerName: name,
      status: status,
      issues: issues,
      duration: DateTime.now().difference(startTime),
      timestamp: DateTime.now(),
    );
  }

  bool _scanForFirebaseImports(FileSystem fs, String dirPath) {
    try {
      final entries = fs.listDirectory(dirPath);
      for (final entry in entries) {
        if (fs.isDirectory(entry)) {
          if (_scanForFirebaseImports(fs, entry)) return true;
        } else if (entry.endsWith('.dart')) {
          try {
            final content = fs.readAsString(entry);
            if (RegExp(
              r'''import\s+['"]package:firebase_''',
            ).hasMatch(content)) {
              return true;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return false;
  }
}