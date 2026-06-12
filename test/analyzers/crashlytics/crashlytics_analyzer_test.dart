import 'package:test/test.dart';
import 'package:firedoctor/analyzers/crashlytics/crashlytics_analyzer.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

FakeFileSystem _createProject({
  required String pubspecContent,
  Map<String, String> dartFiles = const {},
  String? androidBuildGradleContent,
  String? iosPodfileContent,
  String? iosPodfileLockContent,
}) {
  final fs = FakeFileSystem();
  fs.addFile('/project/pubspec.yaml', pubspecContent);
  fs.addDirectory('/project/lib');

  if (androidBuildGradleContent != null) {
    fs.addDirectory('/project/android');
    fs.addDirectory('/project/android/app');
    fs.addFile(
      '/project/android/app/build.gradle',
      androidBuildGradleContent,
    );
  }

  if (iosPodfileContent != null || iosPodfileLockContent != null) {
    fs.addDirectory('/project/ios');
    if (iosPodfileContent != null) {
      fs.addFile('/project/ios/Podfile', iosPodfileContent);
    }
    if (iosPodfileLockContent != null) {
      fs.addFile('/project/ios/Podfile.lock', iosPodfileLockContent);
    }
  }

  for (final entry in dartFiles.entries) {
    fs.addFile(entry.key, entry.value);
  }
  return fs;
}

FakeFileSystem _createProjectWithMain(
  String mainContent, {
  bool withCrashlytics = true,
  String? androidBuildGradleContent,
  String? iosPodfileContent,
  String? iosPodfileLockContent,
  Map<String, String> additionalFiles = const {},
}) {
  final buffer = StringBuffer();
  buffer.writeln('name: test_app');
  buffer.writeln('dependencies:');
  if (withCrashlytics) {
    buffer.writeln('  firebase_crashlytics: ^4.0.0');
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
    androidBuildGradleContent: androidBuildGradleContent,
    iosPodfileContent: iosPodfileContent,
    iosPodfileLockContent: iosPodfileLockContent,
  );
}

const _basicCrashlyticsMain = '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseCrashlytics.instance;
  runApp(const MyApp());
}
''';

const _fullErrorReportingMain = '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const MyApp());
}

void setup() {
  FirebaseCrashlytics.instance.recordError(Exception('test'), StackTrace.current);
}
''';

const _zonedCrashlyticsMain = '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() async {
    runApp(const MyApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
''';

const _crashlyticsWithKeys = '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseCrashlytics.instance.setCustomKey('environment', 'production');
  FirebaseCrashlytics.instance.setUserIdentifier('user_123');
  runApp(const MyApp());
}
''';

const _collectionEnabledMain = '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  runApp(const MyApp());
}
''';

const _recordErrorMain = '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    doSomething();
  } catch (e, s) {
    FirebaseCrashlytics.instance.recordError(e, s);
  }
  runApp(const MyApp());
}
''';

void main() {
  group('CrashlyticsAnalyzer', () {
    late CrashlyticsAnalyzer analyzer;

    setUp(() {
      analyzer = CrashlyticsAnalyzer();
    });

    group('metadata', () {
      test('has correct name', () {
        expect(analyzer.name, equals('crashlytics'));
      });

      test('has correct description', () {
        expect(
          analyzer.description,
          equals('Analyzes Firebase Crashlytics configuration'),
        );
      });

      test('has correct category', () {
        expect(analyzer.category, equals('crashlytics'));
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

    group('FD700: missing firebase_crashlytics dependency', () {
      test('emits FD700 when firebase_crashlytics not in deps', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withCrashlytics: false,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD700'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD700');
        expect(issue.severity, equals(Severity.warning));
        expect(issue.filePath, endsWith('pubspec.yaml'));
      });

      test('does not emit FD700 when firebase_crashlytics is in deps',
          () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD700'), isEmpty);
      });
    });

    group('FD701: Crashlytics not used in Dart code', () {
      test(
          'emits FD701 when firebase_crashlytics in deps but no FirebaseCrashlytics reference',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';
void main() {
  runApp(const MyApp());
}
''',
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD701'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD701');
        expect(issue.severity, equals(Severity.warning));
        expect(issue.filePath, endsWith('pubspec.yaml'));
      });

      test('does not emit FD701 when FirebaseCrashlytics is referenced',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD701'), isEmpty);
      });
    });

    group('FD702: FlutterError.onError not forwarded', () {
      test(
          'emits FD702 when Crashlytics used but no FlutterError.onError',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD702'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD702');
        expect(issue.severity, equals(Severity.error));
      });

      test(
          'does not emit FD702 when FlutterError.onError is configured',
          () async {
        final fs = _createProjectWithMain(
          _fullErrorReportingMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD702'), isEmpty);
      });

      test('does not emit FD702 when no Crashlytics usage', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD702'), isEmpty);
      });
    });

    group('FD703: PlatformDispatcher.onError not configured', () {
      test(
          'emits FD703 when Crashlytics used but no PlatformDispatcher.onError',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD703'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD703');
        expect(issue.severity, equals(Severity.error));
      });

      test(
          'does not emit FD703 when PlatformDispatcher.onError is configured',
          () async {
        final fs = _createProjectWithMain(
          _fullErrorReportingMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD703'), isEmpty);
      });
    });

    group('FD704: Missing runZonedGuarded', () {
      test(
          'emits FD704 when Crashlytics used but no runZonedGuarded',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD704'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD704');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD704 when runZonedGuarded is used', () async {
        final fs = _createProjectWithMain(
          _zonedCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD704'), isEmpty);
      });
    });

    group('FD705: Crashlytics collection explicitly configured', () {
      test(
          'emits FD705 when setCrashlyticsCollectionEnabled is called',
          () async {
        final fs = _createProjectWithMain(
          _collectionEnabledMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD705'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD705');
        expect(issue.severity, equals(Severity.info));
      });

      test(
          'does not emit FD705 when setCrashlyticsCollectionEnabled is not called',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD705'), isEmpty);
      });
    });

    group('FD706: recordError usage not detected', () {
      test(
          'emits FD706 when Crashlytics used but no recordError call',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD706'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD706');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD706 when recordError is used', () async {
        final fs = _createProjectWithMain(
          _recordErrorMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD706'), isEmpty);
      });

      test(
          'does not emit FD706 when recordError is used in full reporting setup',
          () async {
        final fs = _createProjectWithMain(
          _fullErrorReportingMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // _fullErrorReportingMain includes recordError via
        // PlatformDispatcher.instance.onError callback
        expect(result.issues.where((i) => i.code == 'FD706'), isEmpty);
      });
    });

    group('FD707: No fatal error reporting strategy', () {
      test(
          'emits FD707 when Crashlytics used but no error reporting strategy',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD707'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD707');
        expect(issue.severity, equals(Severity.info));
      });

      test(
          'does not emit FD707 when FlutterError.onError is configured',
          () async {
        final fs = _createProjectWithMain(
          _fullErrorReportingMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD707'), isEmpty);
      });

      test('does not emit FD707 when recordError is used', () async {
        final fs = _createProjectWithMain(
          _recordErrorMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD707'), isEmpty);
      });
    });

    group('FD708: Missing Crashlytics Gradle plugin', () {
      test('emits FD708 when Crashlytics Gradle plugin is missing',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          androidBuildGradleContent: '''
plugins {
    id "com.android.application"
    id "kotlin-android"
}
android {
    compileSdk 34
}
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD708'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD708');
        expect(issue.severity, equals(Severity.error));
      });

      test(
          'does not emit FD708 when Crashlytics plugin is present (Kotlin DSL)',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          androidBuildGradleContent: '''
plugins {
    id "com.android.application"
    id "com.google.firebase.crashlytics"
}
android {
    compileSdk 34
}
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD708'), isEmpty);
      });

      test(
          'does not emit FD708 when Crashlytics plugin is present (Groovy DSL)',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          androidBuildGradleContent: '''
apply plugin: 'com.android.application'
apply plugin: 'com.google.firebase.crashlytics'
android {
    compileSdk 34
}
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD708'), isEmpty);
      });
    });

    group('FD709: Missing Crashlytics build configuration', () {
      test(
          'emits FD709 when firebaseCrashlytics block is missing',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          androidBuildGradleContent: '''
plugins {
    id "com.android.application"
    id "com.google.firebase.crashlytics"
}
android {
    compileSdk 34
}
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD709'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD709');
        expect(issue.severity, equals(Severity.info));
      });

      test(
          'does not emit FD709 when firebaseCrashlytics block is present',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          androidBuildGradleContent: '''
plugins {
    id "com.android.application"
    id "com.google.firebase.crashlytics"
}
android {
    compileSdk 34
}
firebaseCrashlytics {
    nativeSymbolUploadEnabled true
}
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD709'), isEmpty);
      });
    });

    group('FD710: Missing Crashlytics CocoaPods pod', () {
      test('emits FD710 when no Podfile exists', () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          // iOS directory exists but no Podfile
          iosPodfileContent: null,
        );
        // Manually add iOS directory since _createProjectWithMain won't add
        // ios dir when iosPodfileContent is null
        fs.addDirectory('/project/ios');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD710'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD710');
        expect(issue.severity, equals(Severity.error));
        expect(issue.filePath, endsWith('Podfile'));
      });

      test(
          'emits FD710 when Podfile exists but no Crashlytics pod',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          iosPodfileContent: '''
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Core'
end
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD710'), isTrue);
      });

      test(
          'does not emit FD710 when Firebase/Crashlytics pod is in Podfile',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          iosPodfileContent: '''
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Crashlytics'
end
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD710'), isEmpty);
      });

      test(
          'does not emit FD710 when FirebaseCrashlytics is in Podfile.lock',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          iosPodfileContent: '''
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Crashlytics'
end
''',
          iosPodfileLockContent: '''
PODS:
  - Firebase/Crashlytics
  - FirebaseCrashlytics
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD710'), isEmpty);
      });
    });

    group('FD711: Missing dSYM upload configuration', () {
      test('emits FD711 when dSYM config not detected', () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          iosPodfileContent: '''
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Crashlytics'
end
''',
          iosPodfileLockContent: '''
PODS:
  - Firebase/Crashlytics (10.0.0)
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD711'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD711');
        expect(issue.severity, equals(Severity.info));
      });

      test('does not emit FD711 when dSYM upload is configured in Podfile.lock',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          iosPodfileContent: '''
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Crashlytics'
end
''',
          iosPodfileLockContent: '''
PODS:
  - Firebase/Crashlytics (10.0.0)
  - FirebaseCrashlytics (10.0.0)
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD711'), isEmpty);
      });
    });

    group('FD712: No custom keys usage', () {
      test('emits FD712 when Crashlytics used but no setCustomKey', () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD712'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD712');
        expect(issue.severity, equals(Severity.info));
      });

      test('does not emit FD712 when setCustomKey is used', () async {
        final fs = _createProjectWithMain(
          _crashlyticsWithKeys,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD712'), isEmpty);
      });
    });

    group('FD713: No user identification strategy', () {
      test(
          'emits FD713 when Crashlytics used but no setUserIdentifier',
          () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD713'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD713');
        expect(issue.severity, equals(Severity.info));
      });

      test('does not emit FD713 when setUserIdentifier is used', () async {
        final fs = _createProjectWithMain(
          _crashlyticsWithKeys,
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD713'), isEmpty);
      });
    });

    group('status computation', () {
      test('returns failed when FD702 (error severity) present', () async {
        final fs = _createProjectWithMain(
          _basicCrashlyticsMain,
          withCrashlytics: true,
          androidBuildGradleContent: '''
plugins {
    id "com.android.application"
}
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
      });

      test('returns warning when only warning issues present', () async {
        final fs = _createProjectWithMain(
          'void main() {}',
          withCrashlytics: false,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
      });

      test('returns passed when no crash-related dependencies or configs exist',
          () async {
        // Create a project with no crashlytics dependency, no android, no ios
        final fs = FakeFileSystem();
        fs.addFile(
          '/project/pubspec.yaml',
          'name: test_app\ndependencies:\n  flutter:\n    sdk: flutter\ndev_dependencies: {}\n',
        );
        fs.addDirectory('/project/lib');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // FD700 fires (warning) since crashlytics is not in deps
        expect(result.status, equals(CheckStatus.warning));
        expect(result.issues.any((i) => i.code == 'FD700'), isTrue);
      });
    });

    group('edge cases', () {
      test('handles empty lib/ directory gracefully', () async {
        final fs = FakeFileSystem();
        fs.addFile(
          '/project/pubspec.yaml',
          'name: test_app\ndependencies:\n  firebase_crashlytics: ^4.0.0\n  flutter:\n    sdk: flutter\ndev_dependencies: {}\n',
        );
        fs.addDirectory('/project/lib');

        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD701'), isTrue);
        expect(result.issues.where((i) => i.code == 'FD702'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD703'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD704'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD706'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD707'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD712'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD713'), isEmpty);
      });

      test(
          'does not false-positive on FirebaseCrashlytics in string literals',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';

void main() {
  final s = "FirebaseCrashlytics.instance is not real usage";
  final r = "recordError is in a string";
  runApp(const MyApp());
}
''',
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD701'), isTrue);
        expect(result.issues.where((i) => i.code == 'FD702'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD706'), isEmpty);
      });

      test('does not false-positive on Crashlytics references in comments',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';

void main() {
  // FirebaseCrashlytics.instance is commented out
  // FlutterError.onError is commented out
  // recordError is commented out
  runApp(const MyApp());
}
''',
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD701'), isTrue);
        expect(result.issues.where((i) => i.code == 'FD702'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD706'), isEmpty);
      });

      test('handles case-sensitive detection', () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';

void main() {
  firebasecrashlytics.instance;
  fluttererror.onerror;
  platformdispatcher.instance.onerror;
  runzonedguarded(() {});
  runApp(const MyApp());
}
''',
          withCrashlytics: true,
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Lowercase should NOT match, so FD701 fires
        expect(result.issues.any((i) => i.code == 'FD701'), isTrue);
        expect(result.issues.where((i) => i.code == 'FD702'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD703'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD704'), isEmpty);
      });

      test(
          'handles multiple Dart files with distributed Crashlytics setup',
          () async {
        final fs = _createProjectWithMain(
          '''
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseCrashlytics.instance;
  runApp(const MyApp());
}
''',
          withCrashlytics: true,
          additionalFiles: {
            '/project/lib/errors.dart': '''
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void setupErrorHandling() {
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
}
''',
            '/project/lib/catch.dart': '''
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void handleError(Object error, StackTrace stack) {
  FirebaseCrashlytics.instance.recordError(error, stack);
}
''',
          },
          androidBuildGradleContent: '''
plugins {
    id "com.android.application"
    id "com.google.firebase.crashlytics"
}
firebaseCrashlytics {
    nativeSymbolUploadEnabled true
}
''',
          iosPodfileContent: '''
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Crashlytics'
end
''',
          iosPodfileLockContent: '''
PODS:
  - Firebase/Crashlytics (10.0.0)
  - FirebaseCrashlytics (10.0.0)
''',
        );
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD700'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD701'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD702'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD706'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD708'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD709'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD710'), isFalse);
        expect(result.issues.any((i) => i.code == 'FD711'), isFalse);
        // FD703, FD704, FD712, FD713 may still fire (not configured)
      });

      test('handles android/build.gradle.kts (Kotlin DSL)', () async {
        final fs = FakeFileSystem();
        fs.addFile(
          '/project/pubspec.yaml',
          'name: test_app\ndependencies:\n  firebase_crashlytics: ^4.0.0\n  flutter:\n    sdk: flutter\ndev_dependencies: {}\n',
        );
        fs.addDirectory('/project/lib');
        fs.addFile(
          '/project/lib/main.dart',
          _basicCrashlyticsMain,
        );
        fs.addDirectory('/project/android');
        fs.addDirectory('/project/android/app');
        fs.addFile(
          '/project/android/app/build.gradle.kts',
          '''
plugins {
    id("com.android.application")
    id("com.google.firebase.crashlytics")
}
android {
    compileSdk = 34
}
firebaseCrashlytics {
    nativeSymbolUploadEnabled = true
}
''',
        );

        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Should find the plugin in Kotlin DSL format
        expect(result.issues.where((i) => i.code == 'FD708'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD709'), isEmpty);
      });
    });

    group('result metadata', () {
      test('result has correct analyzerName', () async {
        final fs = _createProjectWithMain('void main() {}');
        final context =
            createAnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.analyzerName, equals('crashlytics'));
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
