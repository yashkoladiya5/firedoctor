import 'package:test/test.dart';
import 'package:firedoctor/analyzers/project/project_analyzer.dart';
import 'package:firedoctor/analyzers/firebase_core/firebase_core_analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/cli/commands/doctor_command.dart';
import 'package:firedoctor/cli/commands/report_command.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/constants/app_constants.dart';
import '../shared/mocks.dart';

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

FakeFileSystem _createFlutterProject({
  required String mainContent,
  bool addFirebaseCore = true,
  bool addFirebaseOptions = false,
  Map<String, String> additionalFiles = const {},
}) {
  final buffer = StringBuffer();
  buffer.writeln('name: test_app');
  buffer.writeln('dependencies:');
  if (addFirebaseCore) {
    buffer.writeln('  firebase_core: ^3.0.0');
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
    addFirebaseOptions: addFirebaseOptions,
  );
}

void main() {
  group('Bug 1: Project name extraction', () {
    test('ProjectAnalyzer extracts project name from pubspec.yaml', () async {
      final fs = FakeFileSystem();
      fs.addFile('/project/pubspec.yaml', '''
name: my_test_project
dependencies:
  flutter:
    sdk: flutter
dev_dependencies: {}
''');
      fs.addDirectory('/project/lib');
      fs.addFile('/project/lib/main.dart', 'void main() {}');

      final analyzer = ProjectAnalyzer();
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.projectName, equals('my_test_project'));
    });

    test('DoctorCommand uses project name from analyzer result', () async {
      final fs = FakeFileSystem();
      fs.addDirectory('/project');
      fs.addDirectory('/project/lib');
      fs.addFile('/project/pubspec.yaml', '''
name: my_test_project
dependencies:
  flutter:
    sdk: flutter
dev_dependencies: {}
''');
      fs.addFile('/project/lib/main.dart', 'void main() {}');

      final terminal = FakeTerminal();
      final analyzerService = AnalyzerService(
        logger: Logger(terminal: terminal),
      );
      analyzerService.register(ProjectAnalyzer());

      final command = DoctorCommand(
        logger: Logger(terminal: terminal),
        terminal: terminal,
        fileSystem: fs,
        analyzerService: analyzerService,
      );

      final exitCode = await command.execute(['/project']);

      final output = terminal.buffer.toString();
      expect(output, contains('my_test_project'));
      expect(exitCode, AppConstants.exitSuccess);
    });

    test('ReportCommand uses project name from analyzer result', () async {
      final fs = FakeFileSystem();
      fs.addDirectory('/project');
      fs.addDirectory('/project/lib');
      fs.addFile('/project/pubspec.yaml', '''
name: my_test_project
dependencies:
  flutter:
    sdk: flutter
dev_dependencies: {}
''');
      fs.addFile('/project/lib/main.dart', 'void main() {}');

      final terminal = FakeTerminal();
      final analyzerService = AnalyzerService(
        logger: Logger(terminal: terminal),
      );
      analyzerService.register(ProjectAnalyzer());

      final command = ReportCommand(
        logger: Logger(terminal: terminal),
        terminal: terminal,
        fileSystem: fs,
        analyzerService: analyzerService,
      );

      final exitCode = await command.execute(['/project']);

      final output = terminal.buffer.toString();
      expect(output, contains('my_test_project'));
      expect(exitCode, AppConstants.exitSuccess);
    });
  });

  group('Bug 2: Multi-line Firebase.initializeApp() detection', () {
    test('detects multi-line initWith options across multiple lines', () async {
      const mainContent = '''
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
''';
      final fs = _createFlutterProject(
        mainContent: mainContent,
        addFirebaseOptions: true,
      );
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final analyzer = FirebaseCoreAnalyzer();
      final result = await analyzer.analyze(context);

      expect(result.issues.where((i) => i.code == 'FD300'), isEmpty,
          reason: 'FD300 should not fire — init IS found');
      expect(result.issues.where((i) => i.code == 'FD302'), isEmpty,
          reason: 'FD302 should not fire — ensureInitialized IS before init');
      expect(result.issues.where((i) => i.code == 'FD306'), isEmpty,
          reason: 'FD306 should not fire — init IS before runApp');
      expect(result.issues.where((i) => i.code == 'FD305'), isEmpty,
          reason: 'FD305 should not fire — init IS awaited');
    });
  });

  group('Bug 3: Comments and string literals do not produce false positives',
      () {
    test('commented-out init calls do not count toward FD304', () async {
      const mainContent = '''
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /* Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); */
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
''';
      final fs = _createFlutterProject(mainContent: mainContent);
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final analyzer = FirebaseCoreAnalyzer();
      final result = await analyzer.analyze(context);

      expect(result.issues.where((i) => i.code == 'FD304'), isEmpty,
          reason: 'FD304 should not fire — only one real init call');
      expect(result.issues.where((i) => i.code == 'FD300'), isEmpty,
          reason: 'FD300 should not fire — init IS found');
    });

    test('string literal init calls do not count toward FD304', () async {
      const mainContent = '''
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final x = 'Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)';
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
''';
      final fs = _createFlutterProject(mainContent: mainContent);
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final analyzer = FirebaseCoreAnalyzer();
      final result = await analyzer.analyze(context);

      expect(result.issues.where((i) => i.code == 'FD304'), isEmpty,
          reason: 'FD304 should not fire — only one real init call');
      expect(result.issues.where((i) => i.code == 'FD300'), isEmpty,
          reason: 'FD300 should not fire — init IS found');
    });
  });

  group('Bug 4: Cross-file ensureInitialized detection', () {
    test(
        'FD302 not emitted when ensureInitialized is in a different file from init',
        () async {
      final fs = _createFlutterProject(
        mainContent: '''
import 'package:flutter/material.dart';
import 'firebase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
''',
        additionalFiles: {
          '/project/lib/firebase.dart': '''
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
}
''',
        },
      );
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final analyzer = FirebaseCoreAnalyzer();
      final result = await analyzer.analyze(context);

      expect(result.issues.where((i) => i.code == 'FD302'), isEmpty,
          reason:
              'FD302 should not fire — ensureInitialized is in main.dart, init is in firebase.dart');
      expect(result.issues.where((i) => i.code == 'FD306'), isEmpty,
          reason:
              'FD306 should not fire — runApp is in main.dart, init is in firebase.dart');
      expect(result.issues.where((i) => i.code == 'FD300'), isEmpty,
          reason: 'FD300 should not fire — init IS found');
    });
  });
}
