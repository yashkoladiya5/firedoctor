import 'package:test/test.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/severity.dart';

void main() {
  group('DiagnosticIssue', () {
    group('constructor', () {
      test('assigns all required fields', () {
        const issue = DiagnosticIssue(
          severity: Severity.error,
          code: 'TEST_001',
          title: 'Test error',
          description: 'A test error description',
        );

        expect(issue.severity, equals(Severity.error));
        expect(issue.code, equals('TEST_001'));
        expect(issue.title, equals('Test error'));
        expect(issue.description, equals('A test error description'));
      });

      test('sets optional fields to null by default', () {
        const issue = DiagnosticIssue(
          severity: Severity.info,
          code: 'TEST_002',
          title: 'Test info',
          description: 'A test info description',
        );

        expect(issue.recommendation, isNull);
        expect(issue.filePath, isNull);
        expect(issue.lineNumber, isNull);
        expect(issue.metadata, isNull);
      });

      test('accepts all optional fields', () {
        const issue = DiagnosticIssue(
          severity: Severity.critical,
          code: 'CRIT_001',
          title: 'Critical issue',
          description: 'A critical issue',
          recommendation: 'Fix immediately',
          filePath: 'lib/main.dart',
          lineNumber: 42,
          metadata: {'key': 'value'},
        );

        expect(issue.recommendation, equals('Fix immediately'));
        expect(issue.filePath, equals('lib/main.dart'));
        expect(issue.lineNumber, equals(42));
        expect(issue.metadata, equals({'key': 'value'}));
      });
    });

    group('copyWith', () {
      test('returns identical copy when no arguments', () {
        const issue = DiagnosticIssue(
          severity: Severity.error,
          code: 'ERR_001',
          title: 'Original',
          description: 'Original description',
          recommendation: 'Original recommendation',
          filePath: 'lib/file.dart',
          lineNumber: 10,
          metadata: {'original': 'value'},
        );

        final copy = issue.copyWith();
        expect(copy.severity, equals(issue.severity));
        expect(copy.code, equals(issue.code));
        expect(copy.title, equals(issue.title));
        expect(copy.description, equals(issue.description));
        expect(copy.recommendation, equals(issue.recommendation));
        expect(copy.filePath, equals(issue.filePath));
        expect(copy.lineNumber, equals(issue.lineNumber));
        expect(copy.metadata, equals(issue.metadata));
      });

      test('overrides specified fields', () {
        const issue = DiagnosticIssue(
          severity: Severity.warning,
          code: 'WARN_001',
          title: 'Original title',
          description: 'Original description',
        );

        final copy = issue.copyWith(
          severity: Severity.error,
          code: 'ERR_002',
          title: 'Updated title',
        );

        expect(copy.severity, equals(Severity.error));
        expect(copy.code, equals('ERR_002'));
        expect(copy.title, equals('Updated title'));
        expect(copy.description, equals('Original description'));
      });

      test('sets nullable fields to null when sentinel provided', () {
        const issue = DiagnosticIssue(
          severity: Severity.info,
          code: 'INF_001',
          title: 'Info',
          description: 'Info description',
          recommendation: 'Some recommendation',
          filePath: 'lib/file.dart',
          lineNumber: 5,
          metadata: {'key': 'value'},
        );

        final copy = issue.copyWith(
          recommendation: () => null,
          filePath: () => null,
          lineNumber: () => null,
          metadata: () => null,
        );

        expect(copy.recommendation, isNull);
        expect(copy.filePath, isNull);
        expect(copy.lineNumber, isNull);
        expect(copy.metadata, isNull);
      });

      test('keeps existing nullable fields when not overridden', () {
        const issue = DiagnosticIssue(
          severity: Severity.error,
          code: 'ERR_003',
          title: 'Error',
          description: 'Error description',
          recommendation: 'Fix this',
          filePath: 'lib/error.dart',
          lineNumber: 99,
          metadata: {'err': 'true'},
        );

        final copy = issue.copyWith(severity: Severity.warning);

        expect(copy.recommendation, equals('Fix this'));
        expect(copy.filePath, equals('lib/error.dart'));
        expect(copy.lineNumber, equals(99));
        expect(copy.metadata, equals({'err': 'true'}));
      });
    });
  });
}
