import 'dart:convert';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/validation_service.dart';
import '../shared/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      AnalyzerContext(projectPath: '', fileSystem: FakeFileSystem()),
    );
  });

  group('ValidationService', () {
    late MockAnalyzerService mockAnalyzerService;

    setUp(() {
      mockAnalyzerService = MockAnalyzerService();
    });

    group('loadExpectedFindings', () {
      test('parses expected_findings.json correctly', () async {
        final fs = FakeFileSystem();
        const projectPath = '/test_projects/my_app';
        fs.addFile(
          '$projectPath/expected_findings.json',
          jsonEncode({
            'projectName': 'my_app',
            'expectedFindings': [
              {
                'analyzerName': 'project',
                'code': 'FD101',
                'shouldBeFound': true,
              },
              {
                'analyzerName': 'dependency',
                'code': 'FD201',
                'shouldBeFound': false,
              },
            ],
          }),
        );

        final service = ValidationService(
          analyzerService: mockAnalyzerService,
          fileSystem: fs,
        );

        final findings = await service.loadExpectedFindings(projectPath);

        expect(findings.length, equals(2));
        expect(findings[0].code, equals('FD101'));
        expect(findings[0].shouldBeFound, isTrue);
        expect(findings[0].analyzerName, equals('project'));
        expect(findings[1].code, equals('FD201'));
        expect(findings[1].shouldBeFound, isFalse);
        expect(findings[1].analyzerName, equals('dependency'));
      });

      test('returns empty list when file does not exist', () async {
        final fs = FakeFileSystem();
        final service = ValidationService(
          analyzerService: mockAnalyzerService,
          fileSystem: fs,
        );

        final findings = await service.loadExpectedFindings('/nonexistent');

        expect(findings, isEmpty);
      });
    });

    group('validateProject', () {
      test('computes correct TP/FP/FN counts and metrics', () async {
        final fs = FakeFileSystem();
        const projectPath = '/test_projects/my_app';
        fs.addFile(
          '$projectPath/expected_findings.json',
          jsonEncode({
            'projectName': 'my_app',
            'expectedFindings': [
              {
                'analyzerName': 'project',
                'code': 'FD101',
                'shouldBeFound': true,
              },
              {
                'analyzerName': 'project',
                'code': 'FD102',
                'shouldBeFound': true,
              },
              {
                'analyzerName': 'dependency',
                'code': 'FD201',
                'shouldBeFound': false,
              },
            ],
          }),
        );

        when(() => mockAnalyzerService.runAll(any())).thenAnswer(
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
            DiagnosticResult(
              analyzerName: 'dependency',
              status: CheckStatus.passed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'FD201',
                  title: 'Missing dependency',
                  description: 'Recommended dependency not found',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ],
        );

        final service = ValidationService(
          analyzerService: mockAnalyzerService,
          fileSystem: fs,
        );

        final entry = await service.validateProject(projectPath);

        expect(entry.projectName, equals('my_app'));
        expect(entry.totalChecks, equals(3));
        expect(entry.truePositives.length, equals(1));
        expect(entry.truePositives[0].code, equals('FD101'));
        expect(entry.falseNegatives.length, equals(1));
        expect(entry.falseNegatives[0].code, equals('FD102'));
        expect(entry.falsePositives.length, equals(1));
        expect(entry.falsePositives[0].code, equals('FD201'));
        expect(entry.accuracy, closeTo(0.333, 0.001));
        expect(entry.precision, closeTo(0.5, 0.001));
        expect(entry.recall, closeTo(0.5, 0.001));
      });
    });
  });

  group('ValidationReport', () {
    test('aggregate metrics are correct', () {
      const entry1 = ValidationEntry(
        projectName: 'app1',
        projectPath: '/projects/app1',
        totalChecks: 3,
        truePositives: [
          ExpectedFinding(
            analyzerName: 'project',
            code: 'FD101',
            shouldBeFound: true,
          ),
        ],
        falseNegatives: [
          ExpectedFinding(
            analyzerName: 'project',
            code: 'FD102',
            shouldBeFound: true,
          ),
        ],
        falsePositives: [
          DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD201',
            title: 'FP',
            description: 'desc',
          ),
        ],
        accuracy: 0.333,
        precision: 0.5,
        recall: 0.5,
      );

      const entry2 = ValidationEntry(
        projectName: 'app2',
        projectPath: '/projects/app2',
        totalChecks: 2,
        truePositives: [
          ExpectedFinding(
            analyzerName: 'project',
            code: 'FD103',
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
        entries: [entry1, entry2],
        generatedAt: DateTime(2024, 1, 1),
      );

      expect(report.totalTruePositives, equals(2));
      expect(report.totalFalsePositives, equals(1));
      expect(report.totalFalseNegatives, equals(1));
      expect(report.overallAccuracy, closeTo(0.8, 0.001));
      expect(report.overallPrecision, closeTo((0.5 + 1.0) / 2, 0.001));
      expect(report.overallRecall, closeTo((0.5 + 1.0) / 2, 0.001));
    });

    test('empty report returns zero metrics', () {
      final report = ValidationReport(
        entries: [],
        generatedAt: DateTime(2024, 1, 1),
      );

      expect(report.totalTruePositives, equals(0));
      expect(report.totalFalsePositives, equals(0));
      expect(report.totalFalseNegatives, equals(0));
      expect(report.overallAccuracy, equals(0.0));
      expect(report.overallPrecision, equals(0.0));
      expect(report.overallRecall, equals(0.0));
    });

    test('analyzerPrecision groups correctly', () {
      const entry = ValidationEntry(
        projectName: 'app',
        projectPath: '/projects/app',
        totalChecks: 3,
        truePositives: [
          ExpectedFinding(
            analyzerName: 'project',
            code: 'FD101',
            shouldBeFound: true,
          ),
          ExpectedFinding(
            analyzerName: 'dependency',
            code: 'FD201',
            shouldBeFound: true,
          ),
        ],
        falseNegatives: [],
        falsePositives: [
          DiagnosticIssue(
            severity: Severity.warning,
            code: 'FD301',
            title: 'FP',
            description: 'desc',
          ),
        ],
        accuracy: 0.667,
        precision: 0.667,
        recall: 1.0,
      );

      final report = ValidationReport(
        entries: [entry],
        generatedAt: DateTime(2024, 1, 1),
      );

      final precision = report.analyzerPrecision;
      expect(precision['project'], closeTo(1.0, 0.001));
      expect(precision['dependency'], closeTo(1.0, 0.001));
    });

    test('analyzerRecall groups correctly', () {
      const entry = ValidationEntry(
        projectName: 'app',
        projectPath: '/projects/app',
        totalChecks: 3,
        truePositives: [
          ExpectedFinding(
            analyzerName: 'project',
            code: 'FD101',
            shouldBeFound: true,
          ),
        ],
        falseNegatives: [
          ExpectedFinding(
            analyzerName: 'project',
            code: 'FD102',
            shouldBeFound: true,
          ),
          ExpectedFinding(
            analyzerName: 'dependency',
            code: 'FD201',
            shouldBeFound: true,
          ),
        ],
        falsePositives: [],
        accuracy: 0.333,
        precision: 1.0,
        recall: 0.333,
      );

      final report = ValidationReport(
        entries: [entry],
        generatedAt: DateTime(2024, 1, 1),
      );

      final recall = report.analyzerRecall;
      expect(recall['project'], closeTo(0.5, 0.001));
      expect(recall['dependency'], closeTo(0.0, 0.001));
    });

    test('toJsonString produces valid JSON', () {
      const entry = ValidationEntry(
        projectName: 'app',
        projectPath: '/projects/app',
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

      final jsonStr = report.toJsonString();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['overallAccuracy'], equals(1.0));
      expect(decoded['totalTruePositives'], equals(1));
      expect(decoded['totalFalsePositives'], equals(0));
      expect(decoded['entries'], isA<List<dynamic>>());
      expect((decoded['entries'] as List).length, equals(1));
    });
  });
}
