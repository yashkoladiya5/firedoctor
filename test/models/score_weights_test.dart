import 'package:test/test.dart';
import 'package:firedoctor/models/score_weights.dart';
import 'package:firedoctor/models/severity.dart';

void main() {
  group('ScoreWeights', () {
    group('default weights', () {
      final weights = const ScoreWeights();

      test('critical defaults to 25', () {
        expect(weights.critical, equals(25));
      });

      test('error defaults to 15', () {
        expect(weights.error, equals(15));
      });

      test('warning defaults to 5', () {
        expect(weights.warning, equals(5));
      });

      test('info defaults to 1', () {
        expect(weights.info, equals(1));
      });
    });

    group('weightFor', () {
      final weights = const ScoreWeights();

      test('returns critical weight for Severity.critical', () {
        expect(weights.weightFor(Severity.critical), equals(25));
      });

      test('returns error weight for Severity.error', () {
        expect(weights.weightFor(Severity.error), equals(15));
      });

      test('returns warning weight for Severity.warning', () {
        expect(weights.weightFor(Severity.warning), equals(5));
      });

      test('returns info weight for Severity.info', () {
        expect(weights.weightFor(Severity.info), equals(1));
      });
    });

    group('custom weights', () {
      test('constructor accepts custom values', () {
        const weights = ScoreWeights(
          critical: 50,
          error: 30,
          warning: 10,
          info: 2,
        );
        expect(weights.critical, equals(50));
        expect(weights.error, equals(30));
        expect(weights.warning, equals(10));
        expect(weights.info, equals(2));
      });

      test('partial custom values use defaults', () {
        const weights = ScoreWeights(critical: 100);
        expect(weights.critical, equals(100));
        expect(weights.error, equals(15));
        expect(weights.warning, equals(5));
        expect(weights.info, equals(1));
      });
    });

    group('copyWith', () {
      const base = ScoreWeights(
        critical: 10,
        error: 8,
        warning: 4,
        info: 2,
      );

      test('produces new instance with all overridden fields', () {
        final copy = base.copyWith(
          critical: 1,
          error: 2,
          warning: 3,
          info: 4,
        );
        expect(copy.critical, equals(1));
        expect(copy.error, equals(2));
        expect(copy.warning, equals(3));
        expect(copy.info, equals(4));
      });

      test('keeps existing values when no arguments given', () {
        final copy = base.copyWith();
        expect(copy.critical, equals(10));
        expect(copy.error, equals(8));
        expect(copy.warning, equals(4));
        expect(copy.info, equals(2));
      });

      test('overrides only specified fields', () {
        final copy = base.copyWith(critical: 99);
        expect(copy.critical, equals(99));
        expect(copy.error, equals(8));
        expect(copy.warning, equals(4));
        expect(copy.info, equals(2));
      });

      test('returns a new instance', () {
        final copy = base.copyWith();
        expect(identical(copy, base), isFalse);
      });
    });

    group('maxScorePerIssue', () {
      test('returns the critical weight', () {
        const weights = ScoreWeights(critical: 42);
        expect(weights.maxScorePerIssue, equals(42));
      });
    });

    group('defaultWeights', () {
      test('is a const ScoreWeights with default values', () {
        expect(ScoreWeights.defaultWeights, isA<ScoreWeights>());
        expect(ScoreWeights.defaultWeights.critical, equals(25));
        expect(ScoreWeights.defaultWeights.error, equals(15));
        expect(ScoreWeights.defaultWeights.warning, equals(5));
        expect(ScoreWeights.defaultWeights.info, equals(1));
      });

      test('is identical to default constructor', () {
        expect(
          identical(ScoreWeights.defaultWeights, const ScoreWeights()),
          isTrue,
        );
      });
    });
  });
}
