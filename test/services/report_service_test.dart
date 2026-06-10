import 'dart:convert';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/services/report_service.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class MockTerminal extends Mock implements Terminal {}

class MockFileSystem extends Mock implements FileSystem {}

DiagnosticIssue _issue(Severity severity) {
  return DiagnosticIssue(
    severity: severity,
    code: 'TEST',
    title: 'Test issue',
    description: 'Test description',
  );
}

DiagnosticResult _result(CheckStatus status, List<DiagnosticIssue> issues) {
  return DiagnosticResult(
    analyzerName: 'TestAnalyzer',
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
    });

    group('printReport', () {
      test('does not throw when printing', () {
        when(() => terminal.writeLine(any())).thenReturn(null);

        final report = service.generateReport(results: []);
        expect(() => service.printReport(report), returnsNormally);
      });

      test('prints report with issues', () {
        when(() => terminal.writeLine(any())).thenReturn(null);

        final report = service.generateReport(
          results: [
            _result(CheckStatus.failed, [_issue(Severity.error)]),
          ],
          projectName: 'Test',
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
        expect(decoded['results'], isA<List<dynamic>>());
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
        expect((decoded['results'] as List).length, equals(1));
      });
    });

    group('saveReport', () {
      test('writes JSON to filesystem', () async {
        when(() => terminal.writeLine(any())).thenReturn(null);
        final fs = MockFileSystem();
        when(() => fs.writeAsStringAsync(any(), any()))
            .thenAnswer((_) async {});

        final report = service.generateReport(results: []);

        await service.saveReport(report, fs, '/output/report.json');

        verify(() => fs.writeAsStringAsync(any(), any())).called(1);
      });
    });
  });
}
