import 'package:test/test.dart';
import 'package:firedoctor/models/diagnostic_report.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/check_status.dart';
import 'package:firedoctor/models/severity.dart';

DiagnosticResult _result(CheckStatus status, List<DiagnosticIssue> issues) {
  return DiagnosticResult(
    analyzerName: 'test',
    status: status,
    issues: issues,
    duration: Duration.zero,
    timestamp: DateTime(2024, 1, 1),
  );
}

DiagnosticIssue _issue(Severity severity) {
  return DiagnosticIssue(
    severity: severity,
    code: 'TEST',
    title: 'Test',
    description: 'Test description',
  );
}

void main() {
  group('DiagnosticReport', () {
    group('totalIssues', () {
      test('aggregates issues across results', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.passed, [_issue(Severity.info), _issue(Severity.warning)]),
            _result(CheckStatus.passed, [_issue(Severity.error)]),
          ],
        );
        expect(report.totalIssues, equals(3));
      });

      test('returns 0 for empty results', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [],
        );
        expect(report.totalIssues, equals(0));
      });
    });

    group('totalErrors', () {
      test('aggregates error and critical issues across results', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.failed, [_issue(Severity.error), _issue(Severity.critical)]),
            _result(CheckStatus.passed, [_issue(Severity.warning)]),
          ],
        );
        expect(report.totalErrors, equals(2));
      });
    });

    group('totalWarnings', () {
      test('aggregates warning issues across results', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.warning, [_issue(Severity.warning), _issue(Severity.warning)]),
            _result(CheckStatus.passed, [_issue(Severity.info)]),
          ],
        );
        expect(report.totalWarnings, equals(2));
      });
    });

    group('score', () {
      test('returns 100 when no results', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [],
        );
        expect(report.score, equals(100.0));
      });

      test('returns 100 when no issues', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.passed, []),
            _result(CheckStatus.passed, []),
          ],
        );
        expect(report.score, equals(100.0));
      });

      test('returns lower score for errors', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.failed, [_issue(Severity.error)]),
          ],
        );
        expect(report.score, lessThan(100.0));
      });

      test('returns 0 for all errors', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.failed, [
              _issue(Severity.error),
              _issue(Severity.error),
              _issue(Severity.error),
            ]),
          ],
        );
        expect(report.score, equals(0.0));
      });
    });

    group('passed', () {
      test('returns true when all results pass', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.passed, [_issue(Severity.info)]),
            _result(CheckStatus.passed, []),
          ],
        );
        expect(report.passed, isTrue);
      });

      test('returns false when any result fails', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.passed, []),
            _result(CheckStatus.failed, [_issue(Severity.error)]),
          ],
        );
        expect(report.passed, isFalse);
      });

      test('returns true when all results have passed status even with errors', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result(CheckStatus.passed, []),
            _result(CheckStatus.passed, [_issue(Severity.error)]),
          ],
        );
        expect(report.passed, isTrue);
      });
    });
  });
}
