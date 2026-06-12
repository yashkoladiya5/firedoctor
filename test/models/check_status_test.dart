import 'package:test/test.dart';
import 'package:firedoctor/models/check_status.dart';

void main() {
  group('CheckStatus', () {
    test('has all 5 variants', () {
      expect(CheckStatus.passed, isA<CheckStatus>());
      expect(CheckStatus.failed, isA<CheckStatus>());
      expect(CheckStatus.warning, isA<CheckStatus>());
      expect(CheckStatus.skipped, isA<CheckStatus>());
      expect(CheckStatus.notApplicable, isA<CheckStatus>());
    });

    group('passed', () {
      test('has correct name', () {
        expect(CheckStatus.passed.name, equals('passed'));
      });

      test('has correct label', () {
        expect(CheckStatus.passed.label, equals('Passed'));
      });

      test('isPassed returns true', () {
        expect(CheckStatus.passed.isPassed, isTrue);
      });

      test('isFailed returns false', () {
        expect(CheckStatus.passed.isFailed, isFalse);
      });

      test('isWarning returns false', () {
        expect(CheckStatus.passed.isWarning, isFalse);
      });
    });

    group('failed', () {
      test('has correct name', () {
        expect(CheckStatus.failed.name, equals('failed'));
      });

      test('has correct label', () {
        expect(CheckStatus.failed.label, equals('Failed'));
      });

      test('isFailed returns true', () {
        expect(CheckStatus.failed.isFailed, isTrue);
      });

      test('isPassed returns false', () {
        expect(CheckStatus.failed.isPassed, isFalse);
      });
    });

    group('warning', () {
      test('has correct name', () {
        expect(CheckStatus.warning.name, equals('warning'));
      });

      test('has correct label', () {
        expect(CheckStatus.warning.label, equals('Warning'));
      });

      test('isWarning returns true', () {
        expect(CheckStatus.warning.isWarning, isTrue);
      });

      test('isPassed returns false', () {
        expect(CheckStatus.warning.isPassed, isFalse);
      });
    });

    group('skipped', () {
      test('has correct name', () {
        expect(CheckStatus.skipped.name, equals('skipped'));
      });

      test('has correct label', () {
        expect(CheckStatus.skipped.label, equals('Skipped'));
      });
    });

    group('notApplicable', () {
      test('has correct name', () {
        expect(CheckStatus.notApplicable.name, equals('not_applicable'));
      });

      test('has correct label', () {
        expect(CheckStatus.notApplicable.label, equals('N/A'));
      });
    });

    group('fromName', () {
      test('returns passed for "passed"', () {
        expect(CheckStatus.fromName('passed'), equals(CheckStatus.passed));
      });

      test('returns failed for "failed"', () {
        expect(CheckStatus.fromName('failed'), equals(CheckStatus.failed));
      });

      test('returns warning for "warning"', () {
        expect(CheckStatus.fromName('warning'), equals(CheckStatus.warning));
      });

      test('returns skipped for "skipped"', () {
        expect(CheckStatus.fromName('skipped'), equals(CheckStatus.skipped));
      });

      test('returns notApplicable for "not_applicable"', () {
        expect(
          CheckStatus.fromName('not_applicable'),
          equals(CheckStatus.notApplicable),
        );
      });

      test('throws for invalid name', () {
        expect(() => CheckStatus.fromName('invalid'), throwsArgumentError);
      });
    });
  });
}
