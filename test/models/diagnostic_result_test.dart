import 'package:test/test.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/check_status.dart';
import 'package:firedoctor/models/severity.dart';

DiagnosticIssue _issue(Severity severity) {
  return DiagnosticIssue(
    severity: severity,
    code: 'TEST',
    title: 'Test',
    description: 'Test description',
  );
}

void main() {
  group('DiagnosticResult', () {
    group('issueCount', () {
      test('returns number of issues', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [_issue(Severity.info), _issue(Severity.warning)],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.issueCount, equals(2));
      });

      test('returns 0 for empty issues list', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.issueCount, equals(0));
      });
    });

    group('errorCount', () {
      test('counts error and critical issues', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.failed,
          issues: [
            _issue(Severity.info),
            _issue(Severity.warning),
            _issue(Severity.error),
            _issue(Severity.critical),
          ],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.errorCount, equals(2));
      });

      test('returns 0 when no errors', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [_issue(Severity.info)],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.errorCount, equals(0));
      });
    });

    group('warningCount', () {
      test('counts warning issues', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.warning,
          issues: [
            _issue(Severity.info),
            _issue(Severity.warning),
            _issue(Severity.warning),
          ],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.warningCount, equals(2));
      });

      test('returns 0 when no warnings', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [_issue(Severity.info)],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.warningCount, equals(0));
      });
    });

    group('passed', () {
      test('returns true when status is passed and no errors', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [_issue(Severity.info)],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.passed, isTrue);
      });

      test('returns true when status is passed even with errors', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [_issue(Severity.error)],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.passed, isTrue);
      });

      test('returns false when status is failed', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.failed,
          issues: [],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.passed, isFalse);
      });

      test('returns true when status is passed even with critical issues', () {
        final result = DiagnosticResult(
          analyzerName: 'test',
          status: CheckStatus.passed,
          issues: [_issue(Severity.critical)],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );
        expect(result.passed, isTrue);
      });
    });
  });
}
