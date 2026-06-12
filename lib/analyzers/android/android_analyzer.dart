import 'dart:convert';
import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';

/// Core class.
final class AndroidAnalyzer extends Analyzer {
  @override
  String get name => 'android';

  @override
  String get description => 'Analyzes Android Firebase configuration';

  @override
  String get category => 'android';

  @override
  /// Public method or function.
  Future<DiagnosticResult> analyze(AnalyzerContext context) async {
    final startTime = DateTime.now();
    final issues = <DiagnosticIssue>[];
    final fs = context.fileSystem;
    final projectPath = context.projectPath;

    final androidPath = fs.join(projectPath, 'android');
    if (!fs.exists(androidPath) || !fs.isDirectory(androidPath)) {
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.skipped,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final googleServicesPath = fs.join(
      fs.join(projectPath, 'android', 'app'),
      'google-services.json',
    );

    Map<String, dynamic>? googleServicesConfig;
    if (!fs.exists(googleServicesPath)) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.critical,
          code: 'FD400',
          title: 'Missing google-services.json',
          description:
              'The android/app/google-services.json file is missing. '
              'This file is required for Firebase services on Android.',
          recommendation:
              'Run "flutterfire configure" to generate the '
              'google-services.json file.',
          filePath: googleServicesPath,
        ),
      );
    } else {
      final content = fs.readAsString(googleServicesPath);
      googleServicesConfig = _parseGoogleServicesJson(content);
      if (googleServicesConfig == null) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.error,
            code: 'FD401',
            title: 'Invalid google-services.json',
            description:
                'The android/app/google-services.json file contains invalid JSON.',
            recommendation:
                'Regenerate the file using "flutterfire configure" '
                'or fix the JSON syntax.',
            filePath: googleServicesPath,
          ),
        );
      }
    }

    final appDir = fs.join(projectPath, 'android', 'app');
    final appBuildGradlePath = fs.join(appDir, 'build.gradle');
    final appBuildGradleKtsPath = fs.join(appDir, 'build.gradle.kts');

    String? gradleContent;
    String? gradlePath;
    if (fs.exists(appBuildGradlePath)) {
      gradleContent = fs.readAsString(appBuildGradlePath);
      gradlePath = appBuildGradlePath;
    } else if (fs.exists(appBuildGradleKtsPath)) {
      gradleContent = fs.readAsString(appBuildGradleKtsPath);
      gradlePath = appBuildGradleKtsPath;
    }

    String? expectedPackageName;
    if (gradleContent != null) {
      final gradleInfo = _parseBuildGradle(gradleContent);

      if (!gradleInfo.plugins.contains('com.google.gms.google-services')) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.error,
            code: 'FD403',
            title: 'Missing google-services plugin',
            description:
                'The com.google.gms.google-services plugin is not applied '
                'in the app-level build.gradle.',
            recommendation:
                'Add the plugin to your app-level build.gradle:\n'
                '  plugins {\n'
                '    id "com.google.gms.google-services" version "4.4.0"\n'
                '  }',
            filePath: gradlePath,
          ),
        );
      }

      if (gradleInfo.compileSdk != null && gradleInfo.compileSdk! < 34) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD407',
            title: 'compileSdk version is below 34',
            description:
                'The compileSdk is set to ${gradleInfo.compileSdk}. '
                'Version 34 or higher is recommended for latest Firebase SDKs.',
            recommendation:
                'Update compileSdk to 34 in your app-level build.gradle:\n'
                '  android {\n'
                '    compileSdk = 34\n'
                '  }',
            filePath: gradlePath,
          ),
        );
      }

      if (gradleInfo.minSdk != null && gradleInfo.minSdk! < 21) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.info,
            code: 'FD408',
            title: 'minSdk version is below 21',
            description:
                'The minSdk is set to ${gradleInfo.minSdk}. '
                'firebase_core requires a minimum SDK version of 21.',
            recommendation:
                'Update minSdk to 21 in your app-level build.gradle:\n'
                '  defaultConfig {\n'
                '    minSdk = 21\n'
                '  }',
            filePath: gradlePath,
          ),
        );
      }

      if (gradleInfo.targetSdk != null && gradleInfo.targetSdk! < 34) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD409',
            title: 'targetSdk version is below 34',
            description:
                'The targetSdk is set to ${gradleInfo.targetSdk}. '
                'Version 34 or higher is recommended.',
            recommendation:
                'Update targetSdk to 34 in your app-level build.gradle:\n'
                '  defaultConfig {\n'
                '    targetSdk = 34\n'
                '  }',
            filePath: gradlePath,
          ),
        );
      }

      expectedPackageName = gradleInfo.applicationId;
    }

    if (googleServicesConfig != null &&
        googleServicesConfig['package_name'] != null &&
        expectedPackageName != null) {
      final gsPackageName = googleServicesConfig['package_name'] as String;
      if (gsPackageName != expectedPackageName) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.error,
            code: 'FD402',
            title: 'Package name mismatch in google-services.json',
            description:
                'The package name "$gsPackageName" in google-services.json '
                'does not match the applicationId "$expectedPackageName" '
                'in build.gradle.',
            recommendation:
                'Update the applicationId in build.gradle or regenerate '
                'google-services.json with "flutterfire configure".',
            filePath: googleServicesPath,
          ),
        );
      }
    }

    final manifestPath = fs.join(
      fs.join(fs.join(projectPath, 'android', 'app'), 'src', 'main'),
      'AndroidManifest.xml',
    );

    if (fs.exists(manifestPath)) {
      final manifestContent = fs.readAsString(manifestPath);
      final manifestInfo = _parseAndroidManifestXml(manifestContent);

      if (!manifestInfo.permissions.contains('android.permission.INTERNET')) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.error,
            code: 'FD404',
            title: 'Missing INTERNET permission',
            description:
                'The INTERNET permission is not declared in '
                'AndroidManifest.xml.',
            recommendation:
                'Add the INTERNET permission to your AndroidManifest.xml:\n'
                '  <uses-permission android:name="android.permission.INTERNET"/>',
            filePath: manifestPath,
          ),
        );
      }

      if (!manifestInfo.permissions.contains(
        'android.permission.POST_NOTIFICATIONS',
      )) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD405',
            title: 'Missing POST_NOTIFICATIONS permission',
            description:
                'The POST_NOTIFICATIONS permission is not declared. '
                'Required for Android 13+ (API level 33+) notification support.',
            recommendation:
                'Add the POST_NOTIFICATIONS permission to '
                'your AndroidManifest.xml:\n'
                '  <uses-permission '
                'android:name="android.permission.POST_NOTIFICATIONS"/>',
            filePath: manifestPath,
          ),
        );
      }

      if (!manifestInfo.permissions.contains('android.permission.WAKE_LOCK')) {
        issues.add(
          DiagnosticIssue(
            severity: Severity.info,
            code: 'FD406',
            title: 'Missing WAKE_LOCK permission',
            description:
                'The WAKE_LOCK permission is not declared in '
                'AndroidManifest.xml.',
            recommendation:
                'Add the WAKE_LOCK permission to your AndroidManifest.xml:\n'
                '  <uses-permission android:name="android.permission.WAKE_LOCK"/>',
            filePath: manifestPath,
          ),
        );
      }
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

  Map<String, dynamic>? _parseGoogleServicesJson(String content) {
    try {
      final parsed = jsonDecode(content);
      if (parsed is! Map) return null;
      final result = <String, dynamic>{};

      final projectInfo = parsed['project_info'] as Map?;
      if (projectInfo != null) {
        result['project_number'] = projectInfo['project_number'];
        result['project_id'] = projectInfo['project_id'];
      }

      final clients = parsed['client'] as List?;
      if (clients != null && clients.isNotEmpty) {
        final client = clients[0] as Map?;
        final clientInfo = client?['client_info'] as Map?;
        final androidInfo = clientInfo?['android_client_info'] as Map?;
        if (androidInfo != null) {
          result['package_name'] = androidInfo['package_name'];
        }
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  ({List<String> permissions, String? packageName}) _parseAndroidManifestXml(
    String content,
  ) {
    final permissions = <String>[];
    String? packageName;

    final manifestRegex = RegExp(r'<manifest\s[^>]*package="([^"]+)"');
    final manifestMatch = manifestRegex.firstMatch(content);
    if (manifestMatch != null) {
      packageName = manifestMatch.group(1);
    }

    final permRegex = RegExp(r'<uses-permission\s+android:name="([^"]+)"\s*/>');
    for (final match in permRegex.allMatches(content)) {
      permissions.add(match.group(1)!);
    }

    return (permissions: permissions, packageName: packageName);
  }

  ({
    int? compileSdk,
    int? minSdk,
    int? targetSdk,
    List<String> plugins,
    String? applicationId,
  })
  _parseBuildGradle(String content) {
    int? compileSdk;
    int? minSdk;
    int? targetSdk;
    final plugins = <String>[];
    String? applicationId;

    final compileSdkMatch =
        RegExp(r'compileSdk\s*=\s*(\d+)').firstMatch(content) ??
        RegExp(r'compileSdk\s+(\d+)').firstMatch(content);
    if (compileSdkMatch != null) {
      compileSdk = int.parse(compileSdkMatch.group(1)!);
    }

    final minSdkMatch =
        RegExp(r'minSdk\s*=\s*(\d+)').firstMatch(content) ??
        RegExp(r'minSdk\s+(\d+)').firstMatch(content);
    if (minSdkMatch != null) {
      minSdk = int.parse(minSdkMatch.group(1)!);
    }

    final targetSdkMatch =
        RegExp(r'targetSdk\s*=\s*(\d+)').firstMatch(content) ??
        RegExp(r'targetSdk\s+(\d+)').firstMatch(content);
    if (targetSdkMatch != null) {
      targetSdk = int.parse(targetSdkMatch.group(1)!);
    }

    final appIdMatch = RegExp(
      r'''applicationId\s*=?\s*["']([^"']+)["']''',
    ).firstMatch(content);
    if (appIdMatch != null) {
      applicationId = appIdMatch.group(1);
    }

    for (final match in RegExp(
      r'''id\s*\(?["']([^"']+)["']\)?''',
    ).allMatches(content)) {
      plugins.add(match.group(1)!);
    }

    for (final match in RegExp(
      r'''apply\s+plugin:\s*["']([^"']+)["']''',
    ).allMatches(content)) {
      plugins.add(match.group(1)!);
    }

    return (
      compileSdk: compileSdk,
      minSdk: minSdk,
      targetSdk: targetSdk,
      plugins: plugins,
      applicationId: applicationId,
    );
  }
}