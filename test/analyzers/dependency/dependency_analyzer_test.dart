import 'package:test/test.dart';
import 'package:firedoctor/analyzers/dependency/dependency_analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

FakeFileSystem _createFs(String pubspecContent) {
  final fs = FakeFileSystem();
  fs.addFile('/project/pubspec.yaml', pubspecContent);
  return fs;
}

void main() {
  group('DependencyAnalyzer', () {
    late DependencyAnalyzer analyzer;

    setUp(() {
      analyzer = DependencyAnalyzer();
    });

    test('has correct metadata', () {
      expect(analyzer.name, equals('dependency'));
      expect(analyzer.description,
          equals('Analyzes Firebase dependencies in pubspec.yaml'));
      expect(analyzer.category, equals('dependency'));
    });

    group('empty / no Firebase', () {
      test('returns passed with no issues when no Firebase packages in pubspec',
          () async {
        final fs = _createFs('''
name: test_app
dependencies: {}
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });

      test(
          'returns passed with no issues when pubspec has only non-Firebase packages',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  http: ^1.0.0
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    group('missing pubspec', () {
      test('returns skipped when pubspec.yaml does not exist', () async {
        final fs = FakeFileSystem();
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });

      test('returns skipped with no issues when pubspec.yaml does not exist',
          () async {
        final fs = FakeFileSystem();
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, hasLength(0));
      });
    });

    group('invalid pubspec', () {
      test('returns skipped when pubspec.yaml content is invalid', () async {
        final fs = _createFs('{{{');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });
    });

    group('missing firebase_core (FD200)', () {
      test(
          'returns critical FD200 when firebase_auth exists without firebase_core',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_auth: ^1.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('FD200'));
        expect(result.issues.first.severity, equals(Severity.critical));
      });

      test(
          'returns critical FD200 when cloud_firestore exists without firebase_core',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  cloud_firestore: ^5.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('FD200'));
        expect(result.issues.first.severity, equals(Severity.critical));
      });

      test('FD200 has recommendation field set', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_auth: ^1.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.first.recommendation, isNotEmpty);
        expect(result.issues.first.recommendation, contains('firebase_core'));
      });
    });

    group('firebase_core present', () {
      test(
          'does not produce FD200 when firebase_core is present with other packages',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^1.0.0
  cloud_firestore: ^5.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD200'), isEmpty);
      });

      test('returns passed when only firebase_core is present', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    group('dev_dependencies check (FD201)', () {
      test('returns error FD201 for each Firebase package in dev_dependencies',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
dev_dependencies:
  firebase_auth: ^1.0.0
  firebase_analytics: ^11.0.0
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        final fd201Issues =
            result.issues.where((i) => i.code == 'FD201').toList();
        expect(fd201Issues, hasLength(2));
        expect(fd201Issues.every((i) => i.severity == Severity.error), isTrue);
      });

      test(
          'returns correct status (failed) when packages are in dev_dependencies',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
dev_dependencies:
  firebase_auth: ^1.0.0
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
      });

      test(
          'produces both FD201 and FD200 when packages in dev_deps without firebase_core',
          () async {
        final fs = _createFs('''
name: test_app
dependencies: {}
dev_dependencies:
  firebase_auth: ^1.0.0
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD200'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD201'), isTrue);
      });
    });

    group('version issues (FD202)', () {
      test('returns warning FD202 for "any" version constraint', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: any
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('FD202'));
        expect(result.issues.first.severity, equals(Severity.warning));
      });

      test('returns warning FD202 for "*" version constraint', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: '*'
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('FD202'));
        expect(result.issues.first.severity, equals(Severity.warning));
      });

      test('returns warning FD202 for empty version constraint', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ''
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues, hasLength(1));
        expect(result.issues.first.code, equals('FD202'));
        expect(result.issues.first.severity, equals(Severity.warning));
      });

      test('does not produce FD202 for proper caret version constraint',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD202'), isEmpty);
      });

      test('does not produce FD202 for proper pinned version constraint',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: 3.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD202'), isEmpty);
      });
    });

    group('combined scenarios', () {
      test(
          'produces all three issue types (FD200, FD201, FD202) in a complex pubspec',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_auth: any
dev_dependencies:
  firebase_analytics: ^11.0.0
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD200'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD201'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD202'), isTrue);
      });

      test('returns correct CheckStatus.failed when critical issues exist',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_auth: ^1.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.failed));
      });

      test('returns correct CheckStatus.warning when only warning issues exist',
          () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: any
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.warning));
      });
    });

    group('edge cases', () {
      test('handles case-sensitive package names', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  Firebase_Auth: ^1.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // Firebase_Auth is not a recognized Firebase package, so no issues
        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });

      test('correctly identifies all 10 Firebase packages by name', () async {
        final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^1.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^2.0.0
  firebase_messaging: ^15.0.0
  firebase_crashlytics: ^4.0.0
  firebase_analytics: ^11.0.0
  firebase_remote_config: ^5.0.0
  firebase_database: ^4.0.0
  firebase_app_check: ^3.0.0
dev_dependencies: {}
''');
        final context =
            AnalyzerContext(projectPath: '/project', fileSystem: fs);
        final result = await analyzer.analyze(context);

        // firebase_core is present, so no FD200
        // all are in dependencies, so no FD201
        // all have caret constraints, so no FD202
        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    test('result has correct analyzerName', () async {
      final fs = _createFs('''
name: test_app
dependencies:
  firebase_core: ^3.0.0
dev_dependencies: {}
''');
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.analyzerName, equals('dependency'));
    });

    test('result has non-zero duration', () async {
      final fs = _createFs('''
name: test_app
dependencies: {}
dev_dependencies: {}
''');
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.duration.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('result has a recent timestamp', () async {
      final fs = _createFs('''
name: test_app
dependencies: {}
dev_dependencies: {}
''');
      final context = AnalyzerContext(projectPath: '/project', fileSystem: fs);
      final result = await analyzer.analyze(context);

      expect(result.timestamp.isAfter(DateTime(2020, 1, 1)), isTrue);
    });
  });
}
