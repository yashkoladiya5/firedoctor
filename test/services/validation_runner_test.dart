import 'dart:convert';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/validation_runner.dart';
import '../shared/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      AnalyzerContext(projectPath: '', fileSystem: FakeFileSystem()),
    );
  });

  late MockAnalyzerService analyzerService;
  late Logger logger;
  late ValidationRunner runner;

  group('ValidationRunner', () {
    setUp(() {
      analyzerService = MockAnalyzerService();
      logger = Logger(terminal: FakeTerminal());
    });

    group('runAll', () {
      test('returns ValidationReport', () async {
        final fileSystem = FakeFileSystem();

        const projectsDir = '/test_projects';
        fileSystem.addDirectory(projectsDir);
        fileSystem.addDirectory('$projectsDir/app1');
        fileSystem.addFile(
          '$projectsDir/app1/expected_findings.json',
          jsonEncode({
            'projectName': 'app1',
            'expectedFindings': [
              {
                'analyzerName': 'project',
                'code': 'FD101',
                'shouldBeFound': true,
              },
            ],
          }),
        );

        when(() => analyzerService.runAll(any())).thenAnswer(
          (_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'FD101',
                  title: 'Missing pubspec',
                  description: 'pubspec.yaml not found',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ],
        );

        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: fileSystem,
          logger: logger,
        );

        final report = await runner.runAll(projectsDir: projectsDir);

        expect(report, isA<ValidationReport>());
        expect(report.entries.length, equals(1));
        expect(report.entries[0].projectName, equals('app1'));
      });
    });

    group('saveReport', () {
      test('writes JSON string to filesystem', () async {
        final fileSystem = FakeFileSystem();

        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: fileSystem,
          logger: logger,
        );

        const entry = ValidationEntry(
          projectName: 'app1',
          projectPath: '/projects/app1',
          totalChecks: 1,
          truePositives: [
            ExpectedFinding(
              analyzerName: 'project',
              code: 'FD101',
              shouldBeFound: true,
            ),
          ],
          falseNegatives: [],
          falsePositives: [],
          accuracy: 1.0,
          precision: 1.0,
          recall: 1.0,
        );

        final report = ValidationReport(
          entries: [entry],
          generatedAt: DateTime(2024, 1, 1),
        );

        const outputPath = '/tmp/report.json';
        await runner.saveReport(report, outputPath);

        expect(fileSystem.exists(outputPath), isTrue);
        final savedJson = jsonDecode(fileSystem.readAsString(outputPath));
        expect(savedJson, isA<Map<String, dynamic>>());
        expect(savedJson['overallAccuracy'], equals(1.0));
      });
    });

    group('getConfidenceScores', () {
      test('returns 55 entries', () {
        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: FakeFileSystem(),
          logger: logger,
        );

        final scores = runner.getConfidenceScores();

        expect(scores.length, equals(55));
      });

      test('all values are between 0 and 1', () {
        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: FakeFileSystem(),
          logger: logger,
        );

        final scores = runner.getConfidenceScores();

        for (final value in scores.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('contains all expected FD codes', () {
        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: FakeFileSystem(),
          logger: logger,
        );

        final scores = runner.getConfidenceScores();

        expect(scores.containsKey('FD101'), isTrue);
        expect(scores.containsKey('FD709'), isTrue);
        expect(scores.containsKey('FD600'), isTrue);
      });
    });

    group('getConfidenceByCategory', () {
      test('returns 7 category averages', () {
        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: FakeFileSystem(),
          logger: logger,
        );

        final byCategory = runner.getConfidenceByCategory();

        expect(byCategory.length, equals(7));
        expect(byCategory.containsKey('project'), isTrue);
        expect(byCategory.containsKey('dependency'), isTrue);
        expect(byCategory.containsKey('firebase_core'), isTrue);
        expect(byCategory.containsKey('android'), isTrue);
        expect(byCategory.containsKey('ios'), isTrue);
        expect(byCategory.containsKey('fcm'), isTrue);
        expect(byCategory.containsKey('crashlytics'), isTrue);
      });

      test('all averages are between 0 and 1', () {
        runner = ValidationRunner(
          analyzerService: analyzerService,
          fileSystem: FakeFileSystem(),
          logger: logger,
        );

        final byCategory = runner.getConfidenceByCategory();

        for (final value in byCategory.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });
    });
  });
}
