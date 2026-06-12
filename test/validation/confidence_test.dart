import 'package:test/test.dart';
import 'package:firedoctor/models/models.dart';

void main() {
  group('AnalyzerConfidence', () {
    test('has entries for all diagnostic codes', () {
      final expectedCodes = [
        // Project (6)
        'FD101', 'FD102', 'FD103', 'FD104', 'FD105', 'FD106',
        // Dependency (5)
        'FD201', 'FD202', 'FD203', 'FD204', 'FD205',
        // Firebase Core (6)
        'FD301', 'FD302', 'FD303', 'FD304', 'FD305', 'FD306',
        // Android (10)
        'FD401', 'FD402', 'FD403', 'FD404', 'FD405', 'FD406',
        'FD407', 'FD408', 'FD409', 'FD410',
        // iOS (12)
        'FD501', 'FD502', 'FD503', 'FD504', 'FD505', 'FD506',
        'FD507', 'FD508', 'FD509', 'FD510', 'FD511', 'FD512',
        // FCM (6)
        'FD600', 'FD601', 'FD602', 'FD603', 'FD604', 'FD605',
        // Crashlytics (10)
        'FD700', 'FD701', 'FD702', 'FD703', 'FD704', 'FD705',
        'FD706', 'FD707', 'FD708', 'FD709',
      ];

      final confidences = AnalyzerConfidence.defaults;

      expect(confidences.length, equals(expectedCodes.length));
      for (final code in expectedCodes) {
        expect(confidences.containsKey(code), isTrue,
            reason: 'Missing confidence entry for $code');
      }
    });

    test('all confidence values are between 0.0 and 1.0', () {
      for (final entry in AnalyzerConfidence.defaults.entries) {
        expect(
          entry.value.confidence,
          greaterThanOrEqualTo(0.0),
          reason: '${entry.key} confidence < 0.0',
        );
        expect(
          entry.value.confidence,
          lessThanOrEqualTo(1.0),
          reason: '${entry.key} confidence > 1.0',
        );
      }
    });

    test('all entries have reasoning', () {
      for (final entry in AnalyzerConfidence.defaults.entries) {
        expect(entry.value.reasoning, isNotEmpty,
            reason: '${entry.key} has empty reasoning');
      }
    });

    test('toJson produces correct format', () {
      final conf = AnalyzerConfidence.defaults['FD101']!;
      final json = conf.toJson();
      expect(json['code'], equals('FD101'));
      expect(json['confidence'], equals(1.0));
      expect(json['reasoning'], isNotEmpty);
    });
  });
}
