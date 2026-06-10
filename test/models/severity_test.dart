import 'package:test/test.dart';
import 'package:firedoctor/models/severity.dart';

void main() {
  group('Severity', () {
    test('has all 4 variants', () {
      expect(Severity.info, isA<Severity>());
      expect(Severity.warning, isA<Severity>());
      expect(Severity.error, isA<Severity>());
      expect(Severity.critical, isA<Severity>());
    });

    group('info', () {
      test('has correct name', () {
        expect(Severity.info.name, equals('info'));
      });

      test('has correct value', () {
        expect(Severity.info.value, equals(0));
      });

      test('has correct label', () {
        expect(Severity.info.label, equals('Info'));
      });

      test('has correct emoji', () {
        expect(Severity.info.emoji, equals('ℹ️'));
      });
    });

    group('warning', () {
      test('has correct name', () {
        expect(Severity.warning.name, equals('warning'));
      });

      test('has correct value', () {
        expect(Severity.warning.value, equals(1));
      });

      test('has correct label', () {
        expect(Severity.warning.label, equals('Warning'));
      });

      test('has correct emoji', () {
        expect(Severity.warning.emoji, equals('⚠️'));
      });
    });

    group('error', () {
      test('has correct name', () {
        expect(Severity.error.name, equals('error'));
      });

      test('has correct value', () {
        expect(Severity.error.value, equals(2));
      });

      test('has correct label', () {
        expect(Severity.error.label, equals('Error'));
      });

      test('has correct emoji', () {
        expect(Severity.error.emoji, equals('❌'));
      });
    });

    group('critical', () {
      test('has correct name', () {
        expect(Severity.critical.name, equals('critical'));
      });

      test('has correct value', () {
        expect(Severity.critical.value, equals(3));
      });

      test('has correct label', () {
        expect(Severity.critical.label, equals('Critical'));
      });

      test('has correct emoji', () {
        expect(Severity.critical.emoji, equals('🚨'));
      });
    });

    group('compareTo', () {
      test('info < warning', () {
        expect(Severity.info.compareTo(Severity.warning), lessThan(0));
      });

      test('warning < error', () {
        expect(Severity.warning.compareTo(Severity.error), lessThan(0));
      });

      test('error < critical', () {
        expect(Severity.error.compareTo(Severity.critical), lessThan(0));
      });

      test('critical > info', () {
        expect(Severity.critical.compareTo(Severity.info), greaterThan(0));
      });

      test('equal values return 0', () {
        expect(Severity.info.compareTo(Severity.info), equals(0));
      });
    });

    group('fromValue', () {
      test('returns info for 0', () {
        expect(Severity.fromValue(0), equals(Severity.info));
      });

      test('returns warning for 1', () {
        expect(Severity.fromValue(1), equals(Severity.warning));
      });

      test('returns error for 2', () {
        expect(Severity.fromValue(2), equals(Severity.error));
      });

      test('returns critical for 3', () {
        expect(Severity.fromValue(3), equals(Severity.critical));
      });

      test('throws for invalid value', () {
        expect(() => Severity.fromValue(-1), throwsArgumentError);
        expect(() => Severity.fromValue(4), throwsArgumentError);
      });
    });
  });
}
