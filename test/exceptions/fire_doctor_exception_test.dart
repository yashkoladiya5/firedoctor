import 'package:test/test.dart';
import 'package:firedoctor/exceptions/fire_doctor_exception.dart';

void main() {
  group('FireDoctorException', () {
    test('creates exception with just a message', () {
      const ex = FireDoctorException('Something went wrong');
      expect(ex.message, equals('Something went wrong'));
      expect(ex.code, isNull);
      expect(ex.stackTrace, isNull);
    });

    test('creates exception with message and code', () {
      const ex = FireDoctorException('Invalid config', code: 'INVALID_CONFIG');
      expect(ex.message, equals('Invalid config'));
      expect(ex.code, equals('INVALID_CONFIG'));
    });

    test('implements Exception', () {
      const ex = FireDoctorException('test');
      expect(ex, isA<Exception>());
    });

    group('toString', () {
      test('formats with just message', () {
        const ex = FireDoctorException('test error');
        expect(ex.toString(), equals('FireDoctorException: test error'));
      });

      test('formats with message and code', () {
        const ex = FireDoctorException('config error', code: 'CFG_ERR');
        expect(ex.toString(), equals('FireDoctorException: config error (code: CFG_ERR)'));
      });
    });
  });
}
