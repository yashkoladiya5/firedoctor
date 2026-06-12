import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/parsers/pubspec_parser.dart';

final class CrashlyticsAnalyzer extends Analyzer {
  @override
  String get name => 'crashlytics';

  @override
  String get description => 'Analyzes Firebase Crashlytics configuration';

  @override
  String get category => 'crashlytics';

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

    final hasCrashlyticsDependency =
        pubspec.hasDependency('firebase_crashlytics') ||
            pubspec.hasDevDependency('firebase_crashlytics');

    final libPath = fs.join(projectPath, 'lib');
    final hasLibDir = fs.exists(libPath) && fs.isDirectory(libPath);

    // Dart analysis
    bool hasCrashlyticsUsage = false;
    bool hasFlutterErrorOnError = false;
    bool hasPlatformDispatcherOnError = false;
    bool hasRunZonedGuarded = false;
    bool hasCollectionEnabled = false;
    bool hasRecordError = false;
    bool hasCustomKey = false;
    bool hasUserIdentifier = false;

    if (hasCrashlyticsDependency && hasLibDir) {
      final dartFiles = _findDartFiles(fs, libPath);

      for (final filePath in dartFiles) {
        try {
          final content = fs.readAsString(filePath);
          final cleaned = _stripCommentsAndStrings(content);
          final lines = cleaned.split('\n');

          for (final line in lines) {
            if (line.contains('FirebaseCrashlytics')) {
              hasCrashlyticsUsage = true;
            }
            if (line.contains('FlutterError.onError')) {
              hasFlutterErrorOnError = true;
            }
            if (line.contains('PlatformDispatcher.instance.onError')) {
              hasPlatformDispatcherOnError = true;
            }
            if (line.contains('runZonedGuarded')) {
              hasRunZonedGuarded = true;
            }
            if (line.contains('setCrashlyticsCollectionEnabled')) {
              hasCollectionEnabled = true;
            }
            if (line.contains('.recordError(')) {
              hasRecordError = true;
            }
            if (line.contains('setCustomKey(')) {
              hasCustomKey = true;
            }
            if (line.contains('setUserIdentifier(')) {
              hasUserIdentifier = true;
            }
          }
        } catch (_) {}
      }
    }

    // FD700: firebase_crashlytics dependency missing
    if (!hasCrashlyticsDependency) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD700',
        title: 'Missing firebase_crashlytics dependency',
        description:
            'firebase_crashlytics is not declared in pubspec.yaml. '
            'Crashlytics requires this package for crash reporting.',
        recommendation:
            'Add firebase_crashlytics to your dependencies:\n'
            '  firebase_crashlytics: ^4.0.0',
        filePath: pubspecPath,
      ));
    }

    // FD701: firebase_crashlytics installed but no usage detected
    if (hasCrashlyticsDependency && !hasCrashlyticsUsage) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD701',
        title: 'Crashlytics not initialized in Dart code',
        description:
            'firebase_crashlytics is declared as a dependency but no '
            'FirebaseCrashlytics references were found in Dart files under lib/.',
        recommendation:
            'Import and use firebase_crashlytics in your Dart code:\n'
            "  import 'package:firebase_crashlytics/firebase_crashlytics.dart';",
        filePath: pubspecPath,
      ));
    }

    // FD702: FlutterError.onError not forwarded to Crashlytics
    if (hasCrashlyticsUsage && !hasFlutterErrorOnError) {
      issues.add(const DiagnosticIssue(
        severity: Severity.error,
        code: 'FD702',
        title: 'FlutterError.onError not forwarded to Crashlytics',
        description:
            'FlutterError.onError is not configured to forward errors to '
            'Crashlytics. Unhandled Flutter errors will not be captured.',
        recommendation:
            'Configure FlutterError.onError to report to Crashlytics:\n'
            '  FlutterError.onError = (errorDetails) {\n'
            '    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);\n'
            '  };',
      ));
    }

    // FD703: PlatformDispatcher.instance.onError not configured
    if (hasCrashlyticsUsage && !hasPlatformDispatcherOnError) {
      issues.add(const DiagnosticIssue(
        severity: Severity.error,
        code: 'FD703',
        title: 'PlatformDispatcher.onError not configured',
        description:
            'PlatformDispatcher.instance.onError is not configured to forward '
            'errors to Crashlytics. Unhandled platform errors will not be captured.',
        recommendation:
            'Configure PlatformDispatcher.instance.onError to report to Crashlytics:\n'
            '  PlatformDispatcher.instance.onError = (error, stack) {\n'
            '    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);\n'
            '    return true;\n'
            '  };',
      ));
    }

    // FD704: runZonedGuarded missing
    if (hasCrashlyticsUsage && !hasRunZonedGuarded) {
      issues.add(const DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD704',
        title: 'Missing runZonedGuarded for error zone',
        description:
            'No runZonedGuarded call found. Without a guarded zone, '
            'unhandled async errors may not be captured by Crashlytics.',
        recommendation:
            'Wrap your main() with runZonedGuarded:\n'
            '  runZonedGuarded(() async {\n'
            '    runApp(const MyApp());\n'
            '  }, (error, stack) {\n'
            '    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);\n'
            '  });',
      ));
    }

    // FD705: Crashlytics collection disabled
    if (hasCrashlyticsUsage && hasCollectionEnabled) {
      issues.add(const DiagnosticIssue(
        severity: Severity.info,
        code: 'FD705',
        title: 'Crashlytics collection explicitly configured',
        description:
            'setCrashlyticsCollectionEnabled is explicitly called. '
            'Verify that collection is enabled for production builds.',
        recommendation:
            'Ensure crash reporting is enabled in production:\n'
            '  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);',
      ));
    }

    // FD706: recordError usage not detected
    if (hasCrashlyticsUsage && !hasRecordError) {
      issues.add(const DiagnosticIssue(
        severity: Severity.warning,
        code: 'FD706',
        title: 'No recordError usage detected',
        description:
            'Crashlytics is used but no recordError call was found. '
            'Errors may not be explicitly reported to Crashlytics.',
        recommendation:
            'Use recordError to report caught exceptions:\n'
            '  FirebaseCrashlytics.instance.recordError(error, stack);',
      ));
    }

    // FD707: No fatal error reporting strategy detected
    if (hasCrashlyticsUsage &&
        !hasFlutterErrorOnError &&
        !hasPlatformDispatcherOnError &&
        !hasRecordError) {
      issues.add(const DiagnosticIssue(
        severity: Severity.info,
        code: 'FD707',
        title: 'No fatal error reporting strategy detected',
        description:
            'No FlutterError.onError, PlatformDispatcher.onError, or recordError '
            'usage found. Crashlytics may not capture any errors.',
        recommendation:
            'Implement at least one error reporting strategy:\n'
            '  // Option 1: FlutterError.onError\n'
            '  FlutterError.onError = (errorDetails) {\n'
            '    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);\n'
            '  };\n'
            '  // Option 2: PlatformDispatcher.instance.onError\n'
            '  // Option 3: try/catch with recordError',
      ));
    }

    // FD712: No custom keys usage detected
    if (hasCrashlyticsUsage && !hasCustomKey) {
      issues.add(const DiagnosticIssue(
        severity: Severity.info,
        code: 'FD712',
        title: 'No custom keys usage detected',
        description:
            'Crashlytics is used but no setCustomKey calls were found. '
            'Custom keys help provide context for debugging crashes.',
        recommendation:
            'Add custom keys to provide crash context:\n'
            '  FirebaseCrashlytics.instance.setCustomKey("key_name", "value");',
      ));
    }

    // FD713: No user identification strategy detected
    if (hasCrashlyticsUsage && !hasUserIdentifier) {
      issues.add(const DiagnosticIssue(
        severity: Severity.info,
        code: 'FD713',
        title: 'No user identification strategy detected',
        description:
            'No setUserIdentifier call was found. User identification '
            'helps associate crashes with specific users.',
        recommendation:
            'Set a user identifier for crash context:\n'
            '  FirebaseCrashlytics.instance.setUserIdentifier("user_id");',
      ));
    }

    // Android checks
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

    bool hasCrashlyticsGradlePlugin = false;
    bool hasCrashlyticsBuildConfig = false;

    if (gradleContent != null) {
      // FD708: Check for Crashlytics Gradle plugin
      final pluginPatterns = [
        RegExp(r'''id\s*\(?["']com\.google\.firebase\.crashlytics["']\)?'''),
        RegExp(
            r'''apply\s+plugin:\s*["']com\.google\.firebase\.crashlytics["']'''),
      ];
      for (final pattern in pluginPatterns) {
        if (pattern.hasMatch(gradleContent)) {
          hasCrashlyticsGradlePlugin = true;
          break;
        }
      }

      // FD709: Check for Crashlytics build configuration (firebaseCrashlytics block)
      if (RegExp(r'firebaseCrashlytics\s*\{').hasMatch(gradleContent)) {
        hasCrashlyticsBuildConfig = true;
      }
    }

    if (gradleContent != null) {
      if (!hasCrashlyticsGradlePlugin) {
        issues.add(DiagnosticIssue(
          severity: Severity.error,
          code: 'FD708',
          title: 'Missing Crashlytics Gradle plugin',
          description:
              'The com.google.firebase.crashlytics Gradle plugin is not applied '
              'in the app-level build.gradle.',
          recommendation:
              'Add the Crashlytics Gradle plugin:\n'
              '  plugins {\n'
              '    id "com.google.firebase.crashlytics" version "3.0.0"\n'
              '  }',
          filePath: gradlePath!,
        ));
      }

      if (!hasCrashlyticsBuildConfig) {
        issues.add(DiagnosticIssue(
          severity: Severity.info,
          code: 'FD709',
          title: 'Missing Crashlytics build configuration',
          description:
              'No firebaseCrashlytics block found in build.gradle. '
              'Build configuration may not be optimized for Crashlytics.',
          recommendation:
              'Add Crashlytics build configuration:\n'
              '  firebaseCrashlytics {\n'
              '    nativeSymbolUploadEnabled = true\n'
              '  }',
          filePath: gradlePath!,
        ));
      }
    }

    // iOS checks
    final iosPath = fs.join(projectPath, 'ios');
    if (fs.exists(iosPath) && fs.isDirectory(iosPath)) {
      final podfilePath = fs.join(iosPath, 'Podfile');
      final podfileLockPath = fs.join(iosPath, 'Podfile.lock');

      bool hasCrashlyticsPod = false;
      bool hasDsymConfig = false;

      if (fs.exists(podfilePath)) {
        final podfileContent = fs.readAsString(podfilePath);
        // FD710: Check for Crashlytics pod
        if (RegExp(r'''pod\s+['"](Firebase/Crashlytics|FirebaseCrashlytics)['"]''')
            .hasMatch(podfileContent)) {
          hasCrashlyticsPod = true;
        }
      }

      if (fs.exists(podfileLockPath)) {
        final lockContent = fs.readAsString(podfileLockPath);
        // Check Podfile.lock for FirebaseCrashlytics pod
        if (lockContent.contains('FirebaseCrashlytics')) {
          hasCrashlyticsPod = true;
        }

        // FD711: Check for dSYM upload script (FIRCrashlytics or FirebaseCrashlytics in Podfile.lock)
        if (lockContent.contains('- FirebaseCrashlytics')) {
          hasDsymConfig = true;
        }
      }

      if (!hasCrashlyticsPod) {
        issues.add(DiagnosticIssue(
          severity: Severity.error,
          code: 'FD710',
          title: 'Missing Crashlytics CocoaPods pod',
          description:
              'The Firebase/Crashlytics pod is not found in Podfile or Podfile.lock. '
              'Crashlytics requires this pod for iOS crash reporting.',
          recommendation:
              'Add the Crashlytics pod to your Podfile:\n'
              "  pod 'Firebase/Crashlytics'",
          filePath: podfilePath,
        ));
      }

      if (!hasDsymConfig) {
        issues.add(DiagnosticIssue(
          severity: Severity.info,
          code: 'FD711',
          title: 'Missing dSYM upload configuration',
          description:
              'dSYM upload script for Crashlytics not detected. '
              'Without dSYM uploads, crash reports may not be symbolicated.',
          recommendation:
              'Ensure dSYM upload is configured in your Xcode build phases:\n'
              '  "\${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" '
              '-gsp "\${PROJECT_DIR}/Runner/GoogleService-Info.plist" '
              '-p ios "\${DWARF_DSYM_FOLDER_PATH}/\${DWARF_DSYM_FILE_NAME}"',
          filePath: podfileLockPath,
        ));
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

  List<String> _findDartFiles(FileSystem fs, String dirPath) {
    final files = <String>[];
    if (!fs.exists(dirPath) || !fs.isDirectory(dirPath)) return files;

    for (final entry in fs.listDirectory(dirPath)) {
      if (fs.isDirectory(entry)) {
        files.addAll(_findDartFiles(fs, entry));
      } else if (entry.endsWith('.dart')) {
        files.add(entry);
      }
    }
    return files;
  }

  String _stripCommentsAndStrings(String source) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < source.length) {
      if (i < source.length - 1 && source[i] == '/' && source[i + 1] == '/') {
        buffer.write(' ');
        i++;
        while (i < source.length && source[i] != '\n') {
          buffer.write(' ');
          i++;
        }
        if (i < source.length) {
          buffer.write(source[i]);
          i++;
        }
        continue;
      }
      if (i < source.length - 1 && source[i] == '/' && source[i + 1] == '*') {
        buffer.write('  ');
        i += 2;
        while (i < source.length - 1 &&
            !(source[i] == '*' && source[i + 1] == '/')) {
          buffer.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
        if (i < source.length - 1) {
          buffer.write('  ');
          i += 2;
        }
        continue;
      }
      if (source[i] == '"' || source[i] == "'") {
        final quote = source[i];
        buffer.write(quote);
        i++;
        if (i + 1 < source.length &&
            source[i] == quote &&
            source[i + 1] == quote) {
          buffer.write('$quote$quote');
          i += 2;
          while (i < source.length - 2 &&
              !(source[i] == quote &&
                  source[i + 1] == quote &&
                  source[i + 2] == quote)) {
            buffer.write(source[i] == '\n' ? '\n' : ' ');
            i++;
          }
          if (i < source.length - 2) {
            buffer.write('$quote$quote$quote');
            i += 3;
          }
        } else {
          while (i < source.length && source[i] != quote) {
            if (source[i] == '\\' && i + 1 < source.length) {
              buffer.write('  ');
              i += 2;
            } else {
              buffer.write(source[i] == '\n' ? '\n' : ' ');
              i++;
            }
          }
          if (i < source.length) {
            buffer.write(quote);
            i++;
          }
        }
        continue;
      }
      buffer.write(source[i]);
      i++;
    }
    return buffer.toString();
  }
}
