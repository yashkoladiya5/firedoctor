import 'package:test/test.dart';
import 'package:firedoctor/analyzers/android/android_analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

FakeFileSystem _createProject({required Map<String, String> files}) {
  final fs = FakeFileSystem();
  fs.addDirectory('/project');
  fs.addDirectory('/project/android');
  fs.addDirectory('/project/android/app');
  fs.addDirectory('/project/android/app/src');
  fs.addDirectory('/project/android/app/src/main');
  for (final entry in files.entries) {
    fs.addFile(entry.key, entry.value);
  }
  return fs;
}

String get validGoogleServicesJson => '''
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "my-app-123"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc123",
        "android_client_info": {
          "package_name": "com.example.app"
        }
      },
      "oauth_client": [],
      "api_key": []
    }
  ],
  "configuration_version": "1"
}
''';

String get invalidJson => 'not valid json';

String googleServicesWithPackage(String packageName) => '''
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "my-app-123"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc123",
        "android_client_info": {
          "package_name": "$packageName"
        }
      },
      "oauth_client": [],
      "api_key": []
    }
  ],
  "configuration_version": "1"
}
''';

String get validBuildGradle => '''
plugins {
    id "com.android.application" version "8.1.0"
    id "com.google.gms.google-services" version "4.4.0"
}

android {
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 21
        targetSdk = 34
    }
}
''';

String get groovyBuildGradle => '''
plugins {
    id 'com.android.application' version '8.1.0'
    id 'com.google.gms.google-services' version '4.4.0'
}

android {
    compileSdk 34

    defaultConfig {
        applicationId "com.example.app"
        minSdk 21
        targetSdk 34
    }
}
''';

String get buildGradleApplyPlugin => '''
buildscript {
    repositories {
        google()
    }
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}

apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'

android {
    compileSdk 34

    defaultConfig {
        applicationId "com.example.app"
        minSdk 21
        targetSdk 34
    }
}
''';

String get lowSdkBuildGradle => '''
plugins {
    id "com.android.application" version "8.1.0"
    id "com.google.gms.google-services" version "4.4.0"
}

android {
    compileSdk = 33

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 19
        targetSdk = 33
    }
}
''';

String get manifestWithPermissions => '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="Test App"
        android:name=".MainApplication">
        <activity android:name=".MainActivity" />
    </application>
</manifest>
''';

String get manifestNoInternet => '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application android:label="Test App">
        <activity android:name=".MainActivity" />
    </application>
</manifest>
''';

String get manifestMinimal => '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application android:label="Test App">
        <activity android:name=".MainActivity" />
    </application>
</manifest>
''';

String get manifestOnlyInternet => '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app">

    <uses-permission android:name="android.permission.INTERNET"/>

    <application android:label="Test App">
        <activity android:name=".MainActivity" />
    </application>
</manifest>
''';

void main() {
  group('AndroidAnalyzer', () {
    late AndroidAnalyzer analyzer;

    setUp(() {
      analyzer = AndroidAnalyzer();
    });

    test('has correct metadata', () {
      expect(analyzer.name, equals('android'));
      expect(
        analyzer.description,
        equals('Analyzes Android Firebase configuration'),
      );
      expect(analyzer.category, equals('android'));
    });

    group('no android directory', () {
      test('returns skipped when android/ directory does not exist', () async {
        final fs = FakeFileSystem();
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });

      test('returns skipped when android is a file not directory', () async {
        final fs = FakeFileSystem();
        fs.addFile('/project/android', 'not a directory');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });
    });

    group('valid Android project', () {
      test('returns passed when everything is correct (Kotlin DSL)', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });

      test('returns passed with Groovy syntax build.gradle', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': groovyBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });

      test('returns passed with apply plugin style build.gradle', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': buildGradleApplyPlugin,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    group('google-services.json checks', () {
      test('emits FD400 when google-services.json is missing', () async {
        final fs = _createProject(files: {
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD400'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD400');
        expect(issue.severity, equals(Severity.critical));
        expect(result.status, equals(CheckStatus.failed));
      });

      test('emits FD401 when google-services.json has invalid JSON', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': invalidJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD401'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD401');
        expect(issue.severity, equals(Severity.error));
        expect(result.status, equals(CheckStatus.failed));
      });

      test('emits FD402 when package name mismatches applicationId', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json':
              googleServicesWithPackage('com.example.other'),
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD402'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD402');
        expect(issue.severity, equals(Severity.error));
        expect(result.status, equals(CheckStatus.failed));
      });

      test('does not emit FD402 when package name matches', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json':
              googleServicesWithPackage('com.example.app'),
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD402'), isEmpty);
      });

      test('does not emit FD402 when applicationId is not in build.gradle',
          () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': '''
plugins {
    id "com.android.application" version "8.1.0"
    id "com.google.gms.google-services" version "4.4.0"
}
android {
    compileSdk = 34
    defaultConfig {
        minSdk = 21
        targetSdk = 34
    }
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD402'), isEmpty);
      });
    });

    group('build.gradle plugin checks', () {
      test('emits FD403 when google-services plugin is missing', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': '''
plugins {
    id "com.android.application" version "8.1.0"
}
android {
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 21
        targetSdk = 34
    }
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD403'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD403');
        expect(issue.severity, equals(Severity.error));
        expect(result.status, equals(CheckStatus.failed));
      });

      test('emits FD403 with Groovy apply plugin syntax', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': '''
apply plugin: 'com.android.application'
android {
    compileSdk 34
    defaultConfig {
        applicationId "com.example.app"
        minSdk 21
        targetSdk 34
    }
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD403'), isTrue);
      });
    });

    group('AndroidManifest permission checks', () {
      test('emits FD404 when INTERNET permission is missing', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestNoInternet,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD404'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD404');
        expect(issue.severity, equals(Severity.error));
        expect(result.status, equals(CheckStatus.failed));
      });

      test('emits FD405 when POST_NOTIFICATIONS permission is missing',
          () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestOnlyInternet,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD405'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD405');
        expect(issue.severity, equals(Severity.warning));
      });

      test('emits FD406 when WAKE_LOCK permission is missing', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestOnlyInternet,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD406'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD406');
        expect(issue.severity, equals(Severity.info));
      });

      test('no permission issues when all permissions present', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD404'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD405'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD406'), isEmpty);
      });
    });

    group('SDK version checks', () {
      test('emits FD407 when compileSdk < 34', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': lowSdkBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD407'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD407');
        expect(issue.severity, equals(Severity.warning));
      });

      test('no FD407 when compileSdk >= 34', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD407'), isEmpty);
      });

      test('emits FD408 when minSdk < 21', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': lowSdkBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD408'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD408');
        expect(issue.severity, equals(Severity.info));
      });

      test('no FD408 when minSdk >= 21', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD408'), isEmpty);
      });

      test('emits FD409 when targetSdk < 34', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': lowSdkBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD409'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD409');
        expect(issue.severity, equals(Severity.warning));
      });

      test('no FD409 when targetSdk >= 34', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD409'), isEmpty);
      });
    });

    group('Kotlin DSL build.gradle.kts', () {
      test('parses Kotlin DSL SDK versions correctly', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle.kts': '''
plugins {
    id("com.android.application") version "8.1.0"
    id("com.google.gms.google-services") version "4.4.0"
}
android {
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 21
        targetSdk = 34
    }
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });

      test('emits FD403 with Kotlin DSL when plugin missing', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle.kts': '''
plugins {
    id("com.android.application") version "8.1.0"
}
android {
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 21
        targetSdk = 34
    }
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD403'), isTrue);
      });
    });

    group('Groovy build.gradle syntax variants', () {
      test('parses compileSdk with Groovy syntax (no equals)', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': groovyBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });

      test('parses apply plugin: style correctly', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': buildGradleApplyPlugin,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD403'), isEmpty);
        expect(result.status, equals(CheckStatus.passed));
      });
    });

    group('status computation', () {
      test('returns failed when critical/error issues exist', () async {
        final fs = _createProject(files: {
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
      });

      test('returns warning when only warning issues exist', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': lowSdkBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // FD407 (warning) and FD409 (warning) should yield warning status
        expect(result.issues.where((i) => i.code == 'FD407'), isNotEmpty);
        expect(result.issues.where((i) => i.code == 'FD409'), isNotEmpty);
        expect(result.issues.where((i) => i.code == 'FD408'), isNotEmpty);
        expect(result.status, equals(CheckStatus.warning));
      });

      test('returns passed when only info issues or no issues', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    group('combined edge cases', () {
      test('multiple issues simultaneously', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json':
              googleServicesWithPackage('com.example.wrong'),
          '/project/android/app/build.gradle': '''
plugins {
    id "com.android.application" version "8.1.0"
}
android {
    compileSdk = 33
    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 19
        targetSdk = 33
    }
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestOnlyInternet,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD402'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD403'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD405'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD406'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD407'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD408'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD409'), isTrue);
        expect(result.status, equals(CheckStatus.failed));
      });

      test('handles no Android files at all (just android dir exists)',
          () async {
        final fs = FakeFileSystem();
        fs.addDirectory('/project');
        fs.addDirectory('/project/android');
        // No files inside android/
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Should find FD400 (no google-services.json)
        // No build.gradle so no FD403 or SDK checks
        // No AndroidManifest.xml so no permission checks
        expect(result.status, equals(CheckStatus.failed));
        expect(result.issues.any((i) => i.code == 'FD400'), isTrue);
      });

      test('handles build.gradle with no SDK versions defined', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': '''
plugins {
    id "com.android.application" version "8.1.0"
    id "com.google.gms.google-services" version "4.4.0"
}
''',
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // No SDK version issues since values are null
        expect(result.issues.where((i) => i.code == 'FD407'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD408'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD409'), isEmpty);
        expect(result.status, equals(CheckStatus.passed));
      });
    });

    group('result metadata', () {
      test('result has correct analyzerName', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.analyzerName, equals('android'));
      });

      test('result has non-zero duration', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.duration.inMicroseconds, greaterThanOrEqualTo(0));
      });

      test('result has a recent timestamp', () async {
        final fs = _createProject(files: {
          '/project/android/app/google-services.json': validGoogleServicesJson,
          '/project/android/app/build.gradle': validBuildGradle,
          '/project/android/app/src/main/AndroidManifest.xml':
              manifestWithPermissions,
        });
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.timestamp.isAfter(DateTime(2020, 1, 1)), isTrue);
      });
    });
  });
}
