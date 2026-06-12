import 'package:test/test.dart';
import 'package:firedoctor/services/health_score_engine.dart';
import 'package:firedoctor/models/models.dart';

DiagnosticIssue _issue(Severity severity, {String code = 'TEST'}) {
  return DiagnosticIssue(
    severity: severity,
    code: code,
    title: 'Test $code',
    description: 'Description for $code',
  );
}

DiagnosticResult _result(String analyzer, List<DiagnosticIssue> issues) {
  return DiagnosticResult(
    analyzerName: analyzer,
    status: issues.isEmpty ? CheckStatus.passed : CheckStatus.failed,
    issues: issues,
    duration: Duration.zero,
    timestamp: DateTime(2024, 1, 1),
  );
}

void main() {
  late HealthScoreEngine engine;

  setUp(() {
    engine = const HealthScoreEngine();
  });

  group('HealthScoreEngine', () {
    group('empty / no issues', () {
      test('empty results returns perfect score', () {
        final score = engine.computeFromResults([]);

        expect(score.overallScore, equals(100.0));
        expect(score.totalWeight, equals(0));
        expect(score.maxPossibleWeight, equals(1));
        expect(score.categoryScores, isEmpty);
        expect(score.recommendations, isEmpty);
        for (final group in PriorityGroup.values) {
          expect(score.priorityGroups[group], isEmpty);
        }
      });

      test('results with empty issue lists returns perfect score', () {
        final score = engine.computeFromResults([
          _result('project', []),
          _result('android', []),
        ]);

        expect(score.overallScore, equals(100.0));
        expect(score.totalWeight, equals(0));
        expect(score.maxPossibleWeight, equals(1));
        expect(score.categoryScores, hasLength(2));
        for (final cat in score.categoryScores) {
          expect(cat.score, equals(100.0));
          expect(cat.totalIssues, equals(0));
          expect(cat.totalWeight, equals(0));
        }
        expect(score.recommendations, isEmpty);
        for (final group in PriorityGroup.values) {
          expect(score.priorityGroups[group], isEmpty);
        }
      });
    });

    group('single issue', () {
      test('single error produces correct score and priority', () {
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.error, code: 'ERR001')]),
        ]);

        // ((1*25 - 15) / (1*25)) * 100 = 40.0
        expect(score.overallScore, closeTo(40.0, 0.01));
        expect(score.totalWeight, equals(15));
        expect(score.maxPossibleWeight, equals(25));

        expect(score.categoryScores, hasLength(1));
        expect(score.categoryScores.first.score, closeTo(40.0, 0.01));
        expect(score.categoryScores.first.totalIssues, equals(1));
        expect(score.categoryScores.first.totalWeight, equals(15));

        expect(score.priorityGroups[PriorityGroup.high], hasLength(1));
        expect(
          score.priorityGroups[PriorityGroup.high]!.first.code,
          equals('ERR001'),
        );
        expect(score.priorityGroups[PriorityGroup.critical], isEmpty);
        expect(score.priorityGroups[PriorityGroup.medium], isEmpty);
        expect(score.priorityGroups[PriorityGroup.low], isEmpty);
      });

      test('single critical produces correct score and priority', () {
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.critical, code: 'CRIT001')]),
        ]);

        // ((1*25 - 25) / (1*25)) * 100 = 0.0
        expect(score.overallScore, closeTo(0.0, 0.01));
        expect(score.totalWeight, equals(25));
        expect(score.maxPossibleWeight, equals(25));

        expect(score.priorityGroups[PriorityGroup.critical], hasLength(1));
        expect(
          score.priorityGroups[PriorityGroup.critical]!.first.code,
          equals('CRIT001'),
        );
        expect(score.priorityGroups[PriorityGroup.high], isEmpty);
        expect(score.priorityGroups[PriorityGroup.medium], isEmpty);
        expect(score.priorityGroups[PriorityGroup.low], isEmpty);
      });
    });

    group('multiple issues', () {
      test('multiple issues across severities', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.error, code: 'ERR001'),
            _issue(Severity.warning, code: 'WARN001'),
            _issue(Severity.error, code: 'ERR002'),
          ]),
        ]);

        // totalWeight = 15 + 5 + 15 = 35
        // maxPossibleWeight = 3 * 25 = 75
        // overallScore = ((75 - 35) / 75) * 100 = 53.33...
        expect(score.overallScore, closeTo(53.33, 0.01));
        expect(score.totalWeight, equals(35));
        expect(score.maxPossibleWeight, equals(75));

        expect(score.priorityGroups[PriorityGroup.high], hasLength(2));
        expect(score.priorityGroups[PriorityGroup.medium], hasLength(1));
        expect(score.priorityGroups[PriorityGroup.critical], isEmpty);
        expect(score.priorityGroups[PriorityGroup.low], isEmpty);
      });

      test('all severity types populate all priority groups', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.critical, code: 'CRIT'),
            _issue(Severity.error, code: 'ERR'),
            _issue(Severity.warning, code: 'WARN'),
            _issue(Severity.info, code: 'INFO'),
          ]),
        ]);

        // totalWeight = 25 + 15 + 5 + 1 = 46
        // maxPossibleWeight = 4 * 25 = 100
        // overallScore = ((100 - 46) / 100) * 100 = 54.0
        expect(score.overallScore, closeTo(54.0, 0.01));
        expect(score.totalWeight, equals(46));
        expect(score.maxPossibleWeight, equals(100));

        expect(score.priorityGroups[PriorityGroup.critical], hasLength(1));
        expect(score.priorityGroups[PriorityGroup.high], hasLength(1));
        expect(score.priorityGroups[PriorityGroup.medium], hasLength(1));
        expect(score.priorityGroups[PriorityGroup.low], hasLength(1));
      });
    });

    group('category scores', () {
      test('separate analysers produce independent category scores', () {
        // project: 1 error  → score=40, android: 1 warning → score=80
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.error, code: 'P001')]),
          _result('android', [_issue(Severity.warning, code: 'A001')]),
        ]);

        // overall: totalWeight = 20, maxPossibleWeight = 50
        // score = ((50 - 20) / 50) * 100 = 60.0
        expect(score.overallScore, closeTo(60.0, 0.01));
        expect(score.categoryScores, hasLength(2));

        final projectCat = score.categoryScores.firstWhere(
          (c) => c.category == 'project',
        );
        expect(projectCat.score, closeTo(40.0, 0.01));
        expect(projectCat.totalIssues, equals(1));
        expect(projectCat.totalWeight, equals(15));

        final androidCat = score.categoryScores.firstWhere(
          (c) => c.category == 'android',
        );
        expect(androidCat.score, closeTo(80.0, 0.01));
        expect(androidCat.totalIssues, equals(1));
        expect(androidCat.totalWeight, equals(5));
      });

      test('category display names for known analyzers', () {
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.error)]),
          _result('dependency', [_issue(Severity.error)]),
          _result('firebase_core', [_issue(Severity.error)]),
          _result('android', [_issue(Severity.error)]),
          _result('ios', [_issue(Severity.error)]),
          _result('fcm', [_issue(Severity.error)]),
          _result('crashlytics', [_issue(Severity.error)]),
        ]);

        final names = {
          for (final c in score.categoryScores) c.category: c.displayName,
        };

        expect(names['project'], equals('Project Health'));
        expect(names['dependency'], equals('Dependencies Health'));
        expect(names['firebase_core'], equals('Firebase Core Health'));
        expect(names['android'], equals('Android Health'));
        expect(names['ios'], equals('iOS Health'));
        expect(names['fcm'], equals('Messaging Health'));
        expect(names['crashlytics'], equals('Crashlytics Health'));
      });

      test('unknown analyzer display name uses title case', () {
        final score = engine.computeFromResults([
          _result('custom_analyzer', [_issue(Severity.error)]),
          _result('my_checker', [_issue(Severity.error)]),
        ]);

        final names = {
          for (final c in score.categoryScores) c.category: c.displayName,
        };

        expect(names['custom_analyzer'], equals('Custom Analyzer'));
        expect(names['my_checker'], equals('My Checker'));
      });
    });

    group('recommendations', () {
      test('sorts by weight descending and returns top issues', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.info, code: 'INFO'),
            _issue(Severity.critical, code: 'CRIT'),
            _issue(Severity.warning, code: 'WARN'),
            _issue(Severity.error, code: 'ERR'),
          ]),
        ]);

        expect(score.recommendations, hasLength(3));
        expect(score.recommendations[0].weight, equals(25));
        expect(score.recommendations[0].code, equals('CRIT'));
        expect(score.recommendations[1].weight, equals(15));
        expect(score.recommendations[1].code, equals('ERR'));
        expect(score.recommendations[2].weight, equals(5));
        expect(score.recommendations[2].code, equals('WARN'));
      });

      test('respects maxRecommendations limit', () {
        const limited = HealthScoreEngine(maxRecommendations: 2);
        final score = limited.computeFromResults([
          _result('project', [
            _issue(Severity.critical, code: 'CRIT'),
            _issue(Severity.error, code: 'ERR'),
            _issue(Severity.warning, code: 'WARN'),
          ]),
        ]);

        expect(score.recommendations, hasLength(2));
        expect(score.recommendations[0].code, equals('CRIT'));
        expect(score.recommendations[1].code, equals('ERR'));
      });

      test('sorts by code when weights are equal', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.info, code: 'C'),
            _issue(Severity.info, code: 'A'),
            _issue(Severity.info, code: 'B'),
          ]),
        ]);

        expect(score.recommendations, hasLength(3));
        expect(score.recommendations[0].code, equals('A'));
        expect(score.recommendations[1].code, equals('B'));
        expect(score.recommendations[2].code, equals('C'));
      });
    });

    group('custom weights', () {
      test('produces different scores with custom weight values', () {
        const custom = HealthScoreEngine(
          weights: ScoreWeights(critical: 100, error: 50, warning: 20, info: 5),
        );

        final defaultScore = engine.computeFromResults([
          _result('project', [_issue(Severity.error, code: 'ERR')]),
        ]);

        final customScore = custom.computeFromResults([
          _result('project', [_issue(Severity.error, code: 'ERR')]),
        ]);

        // Default: ((25-15)/25)*100 = 40.0
        expect(defaultScore.overallScore, closeTo(40.0, 0.01));
        expect(defaultScore.totalWeight, equals(15));
        expect(defaultScore.maxPossibleWeight, equals(25));

        // Custom (crit=100): ((100-50)/100)*100 = 50.0
        expect(customScore.overallScore, closeTo(50.0, 0.01));
        expect(customScore.totalWeight, equals(50));
        expect(customScore.maxPossibleWeight, equals(100));
      });
    });

    group('edge cases', () {
      test('maxPossibleWeight equals issues.length * maxScorePerIssue', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.warning),
            _issue(Severity.info),
            _issue(Severity.warning),
          ]),
        ]);

        // 3 issues * 25 (critical weight) = 75
        expect(score.maxPossibleWeight, equals(75));
      });

      test('score drops to 0 when totalWeight equals maxPossibleWeight', () {
        // 2 critical issues: totalWeight = 50, maxPossibleWeight = 50
        // score = ((50-50)/50)*100 = 0
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.critical, code: 'C1'),
            _issue(Severity.critical, code: 'C2'),
          ]),
        ]);

        expect(score.overallScore, closeTo(0.0, 0.01));
        expect(score.totalWeight, equals(50));
        expect(score.maxPossibleWeight, equals(50));
      });

      test('score is clamped at 0 when weight exceeds max', () {
        // 2 critical issues: totalWeight = 50, maxPossibleWeight = 50
        // Just verify clamp behavior
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.critical),
            _issue(Severity.critical),
          ]),
        ]);

        expect(score.overallScore, closeTo(0.0, 0.01));
        expect(score.overallScore, isNonNegative);
      });
    });

    group('compute(DiagnosticReport)', () {
      test('delegates to computeFromResults with report.results', () {
        final report = DiagnosticReport(
          projectName: 'test',
          projectPath: '/test',
          createdAt: DateTime(2024, 1, 1),
          results: [
            _result('project', [
              _issue(Severity.error, code: 'ERR'),
              _issue(Severity.warning, code: 'WARN'),
            ]),
          ],
        );

        final fromReport = engine.compute(report);
        final fromResults = engine.computeFromResults(report.results);

        expect(fromReport.overallScore, equals(fromResults.overallScore));
        expect(fromReport.totalWeight, equals(fromResults.totalWeight));
        expect(
          fromReport.maxPossibleWeight,
          equals(fromResults.maxPossibleWeight),
        );
        expect(
          fromReport.categoryScores.length,
          equals(fromResults.categoryScores.length),
        );
        expect(
          fromReport.recommendations.length,
          equals(fromResults.recommendations.length),
        );
      });
    });

    group('regression', () {
      test('empty issues yields overall score 100.0', () {
        final score = engine.computeFromResults([_result('project', [])]);

        expect(score.overallScore, equals(100.0));
        expect(score.categoryScores.first.score, equals(100.0));
      });

      test('all critical issues yields overall score 0.0', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.critical),
            _issue(Severity.critical),
            _issue(Severity.critical),
          ]),
        ]);

        expect(score.overallScore, equals(0.0));
        for (final cat in score.categoryScores) {
          expect(cat.score, equals(0.0));
        }
      });

      test('mixed severities produces score in [0, 100]', () {
        final score = engine.computeFromResults([
          _result('project', [
            _issue(Severity.critical),
            _issue(Severity.warning),
            _issue(Severity.info),
          ]),
        ]);

        expect(score.overallScore, greaterThanOrEqualTo(0.0));
        expect(score.overallScore, lessThanOrEqualTo(100.0));
      });

      test('single issue produces correct score', () {
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.error)]),
        ]);

        expect(score.overallScore, closeTo(40.0, 0.01));
        expect(score.categoryScores.first.score, closeTo(40.0, 0.01));
      });

      test('no issues across categories yields 100.0 overall', () {
        final score = engine.computeFromResults([
          _result('project', []),
          _result('android', []),
          _result('ios', []),
        ]);

        expect(score.overallScore, equals(100.0));
        for (final cat in score.categoryScores) {
          expect(cat.score, equals(100.0));
        }
      });

      test('negative score regression — score never drops below 0', () {
        const custom = HealthScoreEngine(
          weights: ScoreWeights(critical: 10, error: 20),
        );
        final score = custom.computeFromResults([
          _result('project', [_issue(Severity.error), _issue(Severity.error)]),
        ]);

        expect(score.overallScore, isNonNegative);
        expect(score.overallScore, equals(0.0));
      });

      test('overflow regression — score never exceeds 100', () {
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.info), _issue(Severity.info)]),
        ]);

        expect(score.overallScore, lessThanOrEqualTo(100.0));
        expect(score.overallScore, closeTo(96.0, 0.01));
      });

      test('category with 1 critical yields category score 0.0', () {
        final score = engine.computeFromResults([
          _result('project', [_issue(Severity.critical)]),
        ]);

        expect(score.categoryScores.first.score, equals(0.0));
        expect(score.overallScore, equals(0.0));
      });
    });
  });
}
