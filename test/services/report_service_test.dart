import 'dart:convert';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/services/report_service.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class MockTerminal extends Mock implements Terminal {}

class MockFileSystem extends Mock implements FileSystem {}

DiagnosticIssue _issue(Severity severity, {String code = 'TEST'}) {
  return DiagnosticIssue(
    severity: severity,
    code: code,
    title: 'Test issue',
    description: 'Test description',
  );
}

DiagnosticResult _result(
  CheckStatus status,
  List<DiagnosticIssue> issues, {
  String analyzerName = 'TestAnalyzer',
}) {
  return DiagnosticResult(
    analyzerName: analyzerName,
    status: status,
    issues: issues,
    duration: const Duration(milliseconds: 100),
    timestamp: DateTime(2024, 6, 15, 10, 30, 0),
  );
}

void main() {
  late MockTerminal terminal;
  late ReportService service;

  setUp(() {
    terminal = MockTerminal();
    service = ReportService(terminal: terminal);
    when(() => terminal.writeLine(any())).thenReturn(null);
  });

  group('ReportService', () {
    group('generateReport', () {
      test('creates DiagnosticReport with provided values', () {
        final results = [
          _result(CheckStatus.passed, [_issue(Severity.info)]),
        ];

        final report = service.generateReport(
          results: results,
          projectName: 'MyProject',
          projectPath: '/path/to/project',
          firebaseVersion: '13.0.0',
          environment: {'CI': 'true'},
        );

        expect(report.projectName, equals('MyProject'));
        expect(report.projectPath, equals('/path/to/project'));
        expect(report.firebaseVersion, equals('13.0.0'));
        expect(report.environment, equals({'CI': 'true'}));
        expect(report.results.length, equals(1));
      });

      test('uses defaults for optional fields', () {
        final report = service.generateReport(results: []);
        expect(report.projectName, equals('unknown'));
        expect(report.projectPath, equals(''));
        expect(report.firebaseVersion, isNull);
        expect(report.environment, isEmpty);
      });

      test('computes healthScore by default', () {
        final report = service.generateReport(results: []);
        expect(report.healthScore, isNotNull);
        expect(report.healthScore!.overallScore, equals(100.0));
      });

      test('can skip healthScore computation', () {
        final report = service.generateReport(
          results: [],
          computeHealthScore: false,
        );
        expect(report.healthScore, isNull);
      });

      test('healthScore reflects issues in results', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [
              _issue(Severity.error, code: 'FD400'),
            ]),
          ],
        );
        expect(report.healthScore, isNotNull);
        expect(report.healthScore!.overallScore, lessThan(100.0));
        expect(
          report.healthScore!.priorityGroups[PriorityGroup.high]!.length,
          equals(1),
        );
      });
    });

    group('printReport', () {
      test('does not throw when printing', () {
        final report = service.generateReport(results: []);
        expect(() => service.printReport(report), returnsNormally);
      });

      test('prints report with issues', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [_issue(Severity.error)]),
          ],
          projectName: 'Test',
        );

        expect(() => service.printReport(report), returnsNormally);
      });

      test('prints health score sections when healthScore present', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [
              _issue(Severity.error),
              _issue(Severity.warning),
            ]),
          ],
          projectName: 'HealthTest',
        );

        expect(() => service.printReport(report), returnsNormally);
      });
    });

    group('toJson', () {
      test('produces valid JSON string', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.passed, [
              const DiagnosticIssue(
                severity: Severity.warning,
                code: 'WARN_001',
                title: 'Warning title',
                description: 'Warning description',
                recommendation: 'Fix it',
                filePath: 'lib/main.dart',
                lineNumber: 42,
              ),
            ]),
          ],
          projectName: 'Test',
        );

        final jsonStr = service.toJson(report);
        final decoded = json.decode(jsonStr);
        expect(decoded, isA<Map<String, dynamic>>());
        expect(decoded['projectName'], equals('Test'));
        expect(decoded['analyzerResults'], isA<List<dynamic>>());
        expect(decoded['schemaVersion'], equals('1.0.0'));
        expect(decoded['firedoctorVersion'], equals('0.1.0'));
        expect(decoded['generatedAt'], isA<String>());
        expect(decoded['exitCode'], equals(1)); // warning → exitWarningsOnly
        expect(decoded['mostSevereRank'], equals(2));
      });

      test('includes all fields in JSON output', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [
              _issue(Severity.error),
              _issue(Severity.warning),
            ]),
          ],
          projectName: 'JSON Test',
          firebaseVersion: '12.0.0',
        );

        final jsonStr = service.toJson(report);
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        expect(decoded['projectName'], equals('JSON Test'));
        expect(decoded['firebaseVersion'], equals('12.0.0'));
        expect(decoded['totalIssues'], equals(2));
        expect(decoded['passed'], isFalse);
        expect(decoded['schemaVersion'], equals('1.0.0'));
        expect(decoded['firedoctorVersion'], equals('0.1.0'));
        expect(decoded['generatedAt'], isA<String>());
        expect(decoded['exitCode'], equals(2));
        expect(decoded['mostSevereRank'], equals(3));
        expect((decoded['analyzerResults'] as List).length, equals(1));
      });

      test('includes healthScore when present', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [
              _issue(Severity.critical, code: 'FD000'),
            ]),
          ],
        );

        final jsonStr = service.toJson(report);
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        expect(decoded.containsKey('healthScore'), isTrue);
        final hs = decoded['healthScore'] as Map<String, dynamic>;
        expect(hs.containsKey('overallScore'), isTrue);
        expect(hs.containsKey('categoryScores'), isTrue);
        expect(hs.containsKey('priorityGroups'), isTrue);
        expect(hs.containsKey('recommendations'), isTrue);
        expect(hs['overallScore'], equals(0.0));
      });

      test('healthScore JSON has correct structure', () {
        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [
              _issue(Severity.error, code: 'FD400'),
              _issue(Severity.warning, code: 'FD405'),
            ], analyzerName: 'android'),
          ],
        );

        final jsonStr = service.toJson(report);
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        final hs = decoded['healthScore'] as Map<String, dynamic>;

        expect(hs['overallScore'], isA<double>());
        expect(hs['totalIssues'], equals(2));
        expect(hs['categoryScores'], isA<List<dynamic>>());
        expect((hs['categoryScores'] as List).length, equals(1));

        final priorityGroups = hs['priorityGroups'] as Map<String, dynamic>;
        expect(priorityGroups.containsKey('high'), isTrue);
        expect(priorityGroups.containsKey('medium'), isTrue);

        final recommendations = hs['recommendations'] as List<dynamic>;
        expect(recommendations.length, greaterThan(0));
      });

      test('skips healthScore when not computed', () {
        final report = service.generateReport(
          results: [],
          computeHealthScore: false,
        );

        final jsonStr = service.toJson(report);
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        expect(decoded.containsKey('healthScore'), isFalse);
      });
    });

    group('saveReport', () {
      test('writes JSON to filesystem', () async {
        final fs = MockFileSystem();
        when(
          () => fs.writeAsStringAsync(any(), any()),
        ).thenAnswer((_) async {});

        final report = service.generateReport(results: []);

        await service.saveReport(report, fs, '/output/report.json');

        verify(() => fs.writeAsStringAsync(any(), any())).called(1);
      });
    });
  });
}
