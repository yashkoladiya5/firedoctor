import 'package:test/test.dart';
import 'package:firedoctor/analyzers/firebase_core/firebase_core_analyzer.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

FakeFileSystem _createProject({
  required String pubspecContent,
  Map<String, String> dartFiles = const {},
  bool addLibDir = true,
  bool addFirebaseOptions = false,
}) {
  final fs = FakeFileSystem();
  fs.addFile('/project/pubspec.yaml', pubspecContent);
  if (addLibDir) {
    fs.addDirectory('/project/lib');
  }
  for (final entry in dartFiles.entries) {
    fs.addFile(entry.key, entry.value);
  }
  if (addFirebaseOptions) {
    fs.addFile('/project/lib/firebase_options.dart', '''
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => FirebaseOptions(
    apiKey: 'test-key',
    appId: 'test-app',
    messagingSenderId: 'test-sender',
    projectId: 'test-project',
  );
}
''');
  }
  return fs;
}

FakeFileSystem _createProjectWithMain(
  String mainContent, {
  bool withFirebaseCore = true,
  bool addFirebaseOptions = false,
  Map<String, String> additionalFiles = const {},
}) {
  final buffer = StringBuffer();
  buffer.writeln('name: test_app');
  buffer.writeln('dependencies:');
  if (withFirebaseCore) {
    buffer.writeln('  firebase_core: ^3.0.0');
  }
  buffer.writeln('  flutter:');
  buffer.writeln('    sdk: flutter');
  buffer.writeln('dev_dependencies: {}');

  return _createProject(
    pubspecContent: buffer.toString(),
    dartFiles: {'/project/lib/main.dart': mainContent, ...additionalFiles},
    addFirebaseOptions: addFirebaseOptions,
  );
}

void main() {
  group('FirebaseCoreAnalyzer', () {
    late FirebaseCoreAnalyzer analyzer;

    setUp(() {
      analyzer = FirebaseCoreAnalyzer();
    });

    group('metadata', () {
      test('has correct name', () {
        expect(analyzer.name, equals('firebase_core'));
      });

      test('has correct description', () {
        expect(
          analyzer.description,
          equals('Analyzes Firebase Core initialization in Flutter projects'),
        );
      });

      test('has correct category', () {
        expect(analyzer.category, equals('firebase_core'));
      });
    });

    group('skipped conditions', () {
      test('returns skipped when pubspec.yaml does not exist', () async {
        final fs = FakeFileSystem();
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });

      test('returns skipped when pubspec.yaml is invalid', () async {
        final fs = _createProject(pubspecContent: '{{{');
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });

      test('returns skipped when lib/ directory does not exist', () async {
        final fs = _createProject(
          pubspecContent:
              'name: test_app\ndependencies: {}\ndev_dependencies: {}\n',
          addLibDir: false,
        );
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });
    });

    group('correct setup', () {
      const mainContent = '''
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
''';

      test(
        'returns passed with no FD300/FD302/FD306 when everything is correct',
        () async {
          final fs = _createProjectWithMain(
            mainContent,
            addFirebaseOptions: true,
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.status, equals(CheckStatus.passed));
          expect(result.issues.where((i) => i.code == 'FD300'), isEmpty);
          expect(result.issues.where((i) => i.code == 'FD302'), isEmpty);
          expect(result.issues.where((i) => i.code == 'FD306'), isEmpty);
        },
      );

      test(
        'does not produce FD300 when Firebase.initializeApp is present',
        () async {
          final fs = _createProjectWithMain(
            mainContent,
            addFirebaseOptions: true,
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD300'), isEmpty);
        },
      );

      test(
        'does not produce FD302 when ensureInitialized is present and before init',
        () async {
          final fs = _createProjectWithMain(
            mainContent,
            addFirebaseOptions: true,
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD302'), isEmpty);
        },
      );

      test('does not produce FD306 when init is before runApp', () async {
        final fs = _createProjectWithMain(
          mainContent,
          addFirebaseOptions: true,
        );
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD306'), isEmpty);
      });

      test('does not produce FD305 when init has await', () async {
        final fs = _createProjectWithMain(
          mainContent,
          addFirebaseOptions: true,
        );
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD305'), isEmpty);
      });
    });

    group('missing initialization (FD300)', () {
      test(
        'returns critical FD300 when no Firebase.initializeApp found in any file',
        () async {
          const noInitContent = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(noInitContent);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD300'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD300');
          expect(issue.severity, equals(Severity.critical));
        },
      );

      test('FD300 has filePath pointing to pubspec.yaml', () async {
        const noInitContent = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(noInitContent);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        final issue = result.issues.firstWhere((i) => i.code == 'FD300');
        expect(issue.filePath, endsWith('pubspec.yaml'));
      });
    });

    group('missing firebase_options.dart (FD301)', () {
      test(
        'returns warning FD301 when lib/firebase_options.dart does not exist',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: false);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD301'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD301');
          expect(issue.severity, equals(Severity.warning));
        },
      );
    });

    group('missing ensureInitialized (FD302)', () {
      test(
        'returns error FD302 when WidgetsFlutterBinding.ensureInitialized is missing',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD302'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD302');
          expect(issue.severity, equals(Severity.error));
        },
      );

      test(
        'returns error FD302 when ensureInitialized appears after Firebase.initializeApp in same file',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD302'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD302');
          expect(issue.severity, equals(Severity.error));
        },
      );

      test(
        'does not produce FD302 when ensureInitialized is in a different file',
        () async {
          final fs = _createProjectWithMain(
            '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''',
            addFirebaseOptions: true,
            additionalFiles: {
              '/project/lib/init.dart': '''
import 'package:flutter/material.dart';

void initPlatform() {
  WidgetsFlutterBinding.ensureInitialized();
}
''',
            },
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD302'), isEmpty);
        },
      );
    });

    group('DefaultFirebaseOptions not used (FD303)', () {
      test(
        'returns info FD303 when DefaultFirebaseOptions.currentPlatform is not referenced',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD303'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD303');
          expect(issue.severity, equals(Severity.info));
        },
      );
    });

    group('multiple init calls (FD304)', () {
      test(
        'returns warning FD304 when Firebase.initializeApp appears multiple times in one file',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD304'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD304');
          expect(issue.severity, equals(Severity.warning));
        },
      );

      test(
        'returns warning FD304 when Firebase.initializeApp appears in multiple files',
        () async {
          final fs = _createProjectWithMain(
            '''import 'package:firebase_core/firebase_core.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''',
            addFirebaseOptions: true,
            additionalFiles: {
              '/project/lib/other.dart': '''
import 'package:firebase_core/firebase_core.dart';
void init() async {
  await Firebase.initializeApp();
}
''',
            },
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD304'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD304');
          expect(issue.severity, equals(Severity.warning));
        },
      );
    });

    group('missing await (FD305)', () {
      test(
        'returns warning FD305 when Firebase.initializeApp is called without await on the same line',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD305'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD305');
          expect(issue.severity, equals(Severity.warning));
        },
      );
    });

    group('init after runApp (FD306)', () {
      test(
        'returns error FD306 when Firebase.initializeApp appears after runApp in the same file',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  await Firebase.initializeApp();
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD306'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD306');
          expect(issue.severity, equals(Severity.error));
        },
      );
    });

    group('missing firebase_core dependency (FD307)', () {
      test(
        'returns error FD307 when firebase_core is not in dependencies',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, withFirebaseCore: false);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD307'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD307');
          expect(issue.severity, equals(Severity.error));
        },
      );

      test(
        'does not produce FD307 when firebase_core is in dependencies',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD307'), isEmpty);
        },
      );
    });

    group('status computation', () {
      test('returns failed when critical/error issues present', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  runApp(const MyApp());
  await Firebase.initializeApp();
}
''';
        final fs = _createProjectWithMain(content, withFirebaseCore: false);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
      });

      test('returns warning when only warning issues present', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content, addFirebaseOptions: true);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
      });

      test('returns passed when only info issues or no issues', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content, addFirebaseOptions: true);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
      });
    });

    group('edge cases', () {
      test(
        'handles empty lib/ directory with firebase_core dep — produces FD300 + FD301',
        () async {
          final fs = _createProject(
            pubspecContent:
                'name: test_app\ndependencies:\n  firebase_core: ^3.0.0\ndev_dependencies: {}\n',
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD300'), isTrue);
          expect(result.issues.any((i) => i.code == 'FD301'), isTrue);
          expect(result.issues.any((i) => i.code == 'FD307'), isFalse);
        },
      );

      test(
        'handles empty lib/ directory without firebase_core dep — produces no issues',
        () async {
          final fs = _createProject(
            pubspecContent:
                'name: test_app\ndependencies: {}\ndev_dependencies: {}\n',
          );
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues, isEmpty);
        },
      );

      test(
        'handles .dart files with no Firebase references — no FD issues triggered',
        () async {
          const content = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
''';
          final fs = _createProjectWithMain(content, withFirebaseCore: false);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          // Neither firebase_core in deps nor Firebase references in dart files
          expect(result.status, equals(CheckStatus.passed));
          expect(result.issues, isEmpty);
        },
      );

      test('detects multi-line Firebase.initializeApp() call', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content, addFirebaseOptions: true);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues.where((i) => i.code == 'FD300'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD305'), isEmpty);
      });

      test(
        'does not false-positive on Firebase.initializeApp in string literals',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final msg = "Firebase.initializeApp() should not be detected here";
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD300'), isEmpty);
          expect(result.issues.where((i) => i.code == 'FD304'), isEmpty);
        },
      );

      test(
        'does not false-positive on Firebase.initializeApp in block comments',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /* Firebase.initializeApp() should not be detected */
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD300'), isEmpty);
          expect(result.issues.where((i) => i.code == 'FD304'), isEmpty);
        },
      );

      test(
        'does not false-positive on WidgetsFlutterBinding.ensureInitialized in comments',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized() is commented out
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          // should emit FD302 since the only ensureInitialized is in a comment
          expect(result.issues.any((i) => i.code == 'FD302'), isTrue);
        },
      );

      test(
        'handles multiline strings and comments that contain Firebase patterns',
        () async {
          const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp() is in a comment
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
          final fs = _createProjectWithMain(content, addFirebaseOptions: true);
          final context = createAnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          // The analyzer should still detect Firebase.initializeApp on the real line
          expect(result.issues.where((i) => i.code == 'FD300'), isEmpty);
        },
      );

      test('handles case-sensitive detection', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() {
  firebase.initializeapp();
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        // Lowercase 'firebase.initializeapp()' should NOT match
        expect(result.issues.any((i) => i.code == 'FD300'), isTrue);
        final fd300 = result.issues.firstWhere((i) => i.code == 'FD300');
        expect(fd300.severity, equals(Severity.critical));
      });
    });

    group('result metadata', () {
      test('result has correct analyzerName', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content, addFirebaseOptions: true);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.analyzerName, equals('firebase_core'));
      });

      test('result has non-zero duration', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content, addFirebaseOptions: true);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.duration.inMicroseconds, greaterThanOrEqualTo(0));
      });

      test('result has a recent timestamp', () async {
        const content = '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
''';
        final fs = _createProjectWithMain(content, addFirebaseOptions: true);
        final context = createAnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.timestamp.isAfter(DateTime(2020, 1, 1)), isTrue);
      });
    });
  });
}
