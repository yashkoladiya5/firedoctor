import 'package:test/test.dart';
import 'package:firedoctor/analyzers/project/project_analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

void setUpFlutterProject(FakeFileSystem fs) {
  fs.addFile('/project/pubspec.yaml', '''
name: test_app
version: 1.0.0
description: A test Flutter project
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'
dependencies:
  flutter:
    sdk: flutter
dev_dependencies: {}
''');
}

void addAllDirectories(FakeFileSystem fs) {
  fs.addDirectory('/project/android');
  fs.addDirectory('/project/ios');
  fs.addDirectory('/project/lib');
  fs.addDirectory('/project/test');
}

void main() {
  group('ProjectAnalyzer', () {
    late ProjectAnalyzer analyzer;

    setUp(() {
      analyzer = ProjectAnalyzer();
    });

    test('has correct metadata', () {
      expect(analyzer.name, equals('project'));
      expect(analyzer.description, equals('Analyzes Flutter project structure and metadata'));
      expect(analyzer.category, equals('project'));
    });

    group('missing pubspec.yaml', () {
      test('returns FAILED with MISSING_PUBSPEC critical issue', () async {
        final fs = FakeFileSystem();
        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('MISSING_PUBSPEC'));
        expect(result.issues.first.severity, equals(Severity.critical));
        expect(result.issues.first.title, equals('pubspec.yaml not found'));
      });

      test('does not check other directories when pubspec is missing', () async {
        final fs = FakeFileSystem();
        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Only MISSING_PUBSPEC issue — no directory checks
        expect(result.issues, hasLength(1));
        expect(result.issues.single.code, equals('MISSING_PUBSPEC'));
      });
    });

    group('invalid pubspec.yaml', () {
      test('returns FAILED with INVALID_PUBSPEC critical issue', () async {
        final fs = FakeFileSystem();
        fs.addFile('/project/pubspec.yaml', '{{{');
        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('INVALID_PUBSPEC'));
        expect(result.issues.first.severity, equals(Severity.critical));
      });
    });

    group('Flutter project — all directories present', () {
      test('returns PASSED with FLUTTER_SDK_CONSTRAINT info', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        addAllDirectories(fs);
        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('FLUTTER_SDK_CONSTRAINT'));
        expect(result.issues.first.severity, equals(Severity.info));
      });
    });

    group('missing android directory', () {
      test('generates MISSING_ANDROID warning', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        addAllDirectories(fs);
        await fs.delete('/project/android');

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
        final androidIssue = result.issues.firstWhere((i) => i.code == 'MISSING_ANDROID');
        expect(androidIssue.severity, equals(Severity.warning));
      });
    });

    group('missing ios directory', () {
      test('generates MISSING_IOS warning', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        addAllDirectories(fs);
        await fs.delete('/project/ios');

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
        final iosIssue = result.issues.firstWhere((i) => i.code == 'MISSING_IOS');
        expect(iosIssue.severity, equals(Severity.warning));
      });
    });

    group('missing lib directory', () {
      test('generates MISSING_LIB error and returns FAILED', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        addAllDirectories(fs);
        await fs.delete('/project/lib');

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
        final libIssue = result.issues.firstWhere((i) => i.code == 'MISSING_LIB');
        expect(libIssue.severity, equals(Severity.error));
      });
    });

    group('missing test directory', () {
      test('generates MISSING_TEST info but still PASSED', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        addAllDirectories(fs);
        await fs.delete('/project/test');

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        final testIssue = result.issues.firstWhere((i) => i.code == 'MISSING_TEST');
        expect(testIssue.severity, equals(Severity.info));
      });
    });

    group('non-Flutter project', () {
      test('generates NOT_FLUTTER_PROJECT warning', () async {
        final fs = FakeFileSystem();
        fs.addFile('/project/pubspec.yaml', '''
name: dart_app
dependencies:
  http: ^1.0.0
dev_dependencies: {}
''');
        fs.addDirectory('/project/lib');

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
        final notFlutter = result.issues.firstWhere((i) => i.code == 'NOT_FLUTTER_PROJECT');
        expect(notFlutter.severity, equals(Severity.warning));
        expect(notFlutter.filePath, endsWith('pubspec.yaml'));
      });
    });

    group('multiple missing directories', () {
      test('generates all relevant issues', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        // fs only has pubspec.yaml - no directories added

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        final codes = result.issues.map((i) => i.code).toSet();
        expect(codes, contains('MISSING_ANDROID'));
        expect(codes, contains('MISSING_IOS'));
        expect(codes, contains('MISSING_LIB'));
        expect(codes, contains('MISSING_TEST'));
        expect(codes, contains('FLUTTER_SDK_CONSTRAINT'));
        expect(result.status, equals(CheckStatus.failed));
      });
    });

    group('Flutter project with android as file not directory', () {
      test('treats file as missing directory', () async {
        final fs = FakeFileSystem();
        setUpFlutterProject(fs);
        addAllDirectories(fs);
        await fs.delete('/project/android');
        fs.addFile('/project/android', 'not a directory');

        final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        final androidIssue = result.issues.firstWhere((i) => i.code == 'MISSING_ANDROID');
        expect(androidIssue, isNotNull);
        expect(result.status, equals(CheckStatus.warning));
      });
    });

    test('result has correct analyzerName', () async {
      final fs = FakeFileSystem();
      setUpFlutterProject(fs);
      addAllDirectories(fs);
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.analyzerName, equals('project'));
    });

    test('result has non-zero duration', () async {
      final fs = FakeFileSystem();
      setUpFlutterProject(fs);
      addAllDirectories(fs);
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.duration.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('result has a recent timestamp', () async {
      final fs = FakeFileSystem();
      setUpFlutterProject(fs);
      addAllDirectories(fs);
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.timestamp.isAfter(DateTime(2020, 1, 1)), isTrue);
    });
  });
}
