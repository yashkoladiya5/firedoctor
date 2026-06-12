import 'package:test/test.dart';
import 'package:firedoctor/models/health_score.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/score_weights.dart';
import 'package:firedoctor/models/severity.dart';

void main() {
  group('PriorityGroup', () {
    test('fromSeverity maps critical severity', () {
      expect(PriorityGroup.fromSeverity(Severity.critical), PriorityGroup.critical);
    });

    test('fromSeverity maps error severity', () {
      expect(PriorityGroup.fromSeverity(Severity.error), PriorityGroup.high);
    });

    test('fromSeverity maps warning severity', () {
      expect(PriorityGroup.fromSeverity(Severity.warning), PriorityGroup.medium);
    });

    test('fromSeverity maps info severity', () {
      expect(PriorityGroup.fromSeverity(Severity.info), PriorityGroup.low);
    });

    test('critical has correct label and rank', () {
      expect(PriorityGroup.critical.label, 'Critical Fixes');
      expect(PriorityGroup.critical.rank, 0);
    });

    test('high has correct label and rank', () {
      expect(PriorityGroup.high.label, 'High Priority');
      expect(PriorityGroup.high.rank, 1);
    });

    test('medium has correct label and rank', () {
      expect(PriorityGroup.medium.label, 'Medium Priority');
      expect(PriorityGroup.medium.rank, 2);
    });

    test('low has correct label and rank', () {
      expect(PriorityGroup.low.label, 'Low Priority');
      expect(PriorityGroup.low.rank, 3);
    });
  });

  group('CategoryScore', () {
    test('constructor assigns all fields', () {
      const score = CategoryScore(
        category: 'performance',
        displayName: 'Performance',
        score: 85.5,
        totalIssues: 10,
        totalWeight: 100,
      );
      expect(score.category, 'performance');
      expect(score.displayName, 'Performance');
      expect(score.score, 85.5);
      expect(score.totalIssues, 10);
      expect(score.totalWeight, 100);
    });

    test('toJson produces correct map', () {
      const score = CategoryScore(
        category: 'performance',
        displayName: 'Performance',
        score: 85.5,
        totalIssues: 10,
        totalWeight: 100,
      );
      expect(score.toJson(), {
        'category': 'performance',
        'displayName': 'Performance',
        'score': 85.5,
        'totalIssues': 10,
        'totalWeight': 100,
      });
    });
  });

  group('Recommendation', () {
    test('constructor assigns all fields', () {
      const rec = Recommendation(
        code: 'PERF001',
        title: 'Avoid unnecessary rebuilds',
        severity: 'warning',
        weight: 5,
      );
      expect(rec.code, 'PERF001');
      expect(rec.title, 'Avoid unnecessary rebuilds');
      expect(rec.severity, 'warning');
      expect(rec.weight, 5);
    });

    test('formatted returns "Fix CODE: TITLE"', () {
      const rec = Recommendation(
        code: 'PERF001',
        title: 'Avoid unnecessary rebuilds',
        severity: 'warning',
        weight: 5,
      );
      expect(rec.formatted, 'Fix PERF001: Avoid unnecessary rebuilds');
    });

    test('toJson produces correct map', () {
      const rec = Recommendation(
        code: 'PERF001',
        title: 'Avoid unnecessary rebuilds',
        severity: 'warning',
        weight: 5,
      );
      expect(rec.toJson(), {
        'code': 'PERF001',
        'title': 'Avoid unnecessary rebuilds',
        'severity': 'warning',
        'weight': 5,
      });
    });
  });

  group('HealthScore', () {
    const criticalIssue = DiagnosticIssue(
      severity: Severity.critical,
      code: 'CRIT001',
      title: 'Critical bug',
      description: 'A critical issue',
      filePath: 'lib/main.dart',
      lineNumber: 10,
    );
    const errorIssue = DiagnosticIssue(
      severity: Severity.error,
      code: 'ERR001',
      title: 'Error bug',
      description: 'An error issue',
    );
    const warningIssue = DiagnosticIssue(
      severity: Severity.warning,
      code: 'WARN001',
      title: 'Warning bug',
      description: 'A warning issue',
      filePath: 'lib/utils.dart',
    );
    const infoIssue = DiagnosticIssue(
      severity: Severity.info,
      code: 'INFO001',
      title: 'Info suggestion',
      description: 'An info issue',
      lineNumber: 42,
    );
    const infoIssue2 = DiagnosticIssue(
      severity: Severity.info,
      code: 'INFO002',
      title: 'Another suggestion',
      description: 'Another info issue',
    );

    const categoryScore = CategoryScore(
      category: 'performance',
      displayName: 'Performance',
      score: 92.0,
      totalIssues: 4,
      totalWeight: 46,
    );

    const recommendation = Recommendation(
      code: 'CRIT001',
      title: 'Critical bug',
      severity: 'critical',
      weight: 25,
    );

    const weights = ScoreWeights(
      critical: 25,
      error: 15,
      warning: 5,
      info: 1,
    );

    HealthScore createScore({
      List<DiagnosticIssue> critical = const [],
      List<DiagnosticIssue> high = const [],
      List<DiagnosticIssue> medium = const [],
      List<DiagnosticIssue> low = const [],
    }) {
      return HealthScore(
        overallScore: 92.0,
        categoryScores: [categoryScore],
        priorityGroups: {
          PriorityGroup.critical: critical,
          PriorityGroup.high: high,
          PriorityGroup.medium: medium,
          PriorityGroup.low: low,
        },
        recommendations: [recommendation],
        totalWeight: 46,
        maxPossibleWeight: 100,
        weights: weights,
      );
    }

    test('constructor assigns all fields', () {
      final score = createScore(
        critical: [criticalIssue],
        low: [infoIssue],
      );
      expect(score.overallScore, 92.0);
      expect(score.categoryScores, [categoryScore]);
      expect(score.recommendations, [recommendation]);
      expect(score.totalWeight, 46);
      expect(score.maxPossibleWeight, 100);
      expect(score.weights, weights);
    });

    test('priorityGroups stores issues correctly per group', () {
      final score = createScore(
        critical: [criticalIssue],
        high: [errorIssue],
        medium: [warningIssue],
        low: [infoIssue, infoIssue2],
      );
      expect(score.priorityGroups[PriorityGroup.critical], [criticalIssue]);
      expect(score.priorityGroups[PriorityGroup.high], [errorIssue]);
      expect(score.priorityGroups[PriorityGroup.medium], [warningIssue]);
      expect(score.priorityGroups[PriorityGroup.low], [infoIssue, infoIssue2]);
    });

    test('criticalIssues returns correct list', () {
      final score = createScore(critical: [criticalIssue]);
      expect(score.criticalIssues, [criticalIssue]);
    });

    test('criticalIssues returns empty list when no critical issues', () {
      final score = createScore();
      expect(score.criticalIssues, isEmpty);
    });

    test('highPriorityIssues returns correct list', () {
      final score = createScore(high: [errorIssue]);
      expect(score.highPriorityIssues, [errorIssue]);
    });

    test('highPriorityIssues returns empty list when no high issues', () {
      final score = createScore();
      expect(score.highPriorityIssues, isEmpty);
    });

    test('mediumPriorityIssues returns correct list', () {
      final score = createScore(medium: [warningIssue]);
      expect(score.mediumPriorityIssues, [warningIssue]);
    });

    test('mediumPriorityIssues returns empty list when no medium issues', () {
      final score = createScore();
      expect(score.mediumPriorityIssues, isEmpty);
    });

    test('lowPriorityIssues returns correct list', () {
      final score = createScore(low: [infoIssue, infoIssue2]);
      expect(score.lowPriorityIssues, [infoIssue, infoIssue2]);
    });

    test('lowPriorityIssues returns empty list when no low issues', () {
      final score = createScore();
      expect(score.lowPriorityIssues, isEmpty);
    });

    test('totalIssues sums all groups', () {
      final score = createScore(
        critical: [criticalIssue],
        high: [errorIssue],
        medium: [warningIssue],
        low: [infoIssue, infoIssue2],
      );
      expect(score.totalIssues, 5);
    });

    test('totalIssues is zero when no issues', () {
      final score = createScore();
      expect(score.totalIssues, 0);
    });

    test('toJson includes all expected keys', () {
      final score = createScore(
        critical: [criticalIssue],
        low: [infoIssue],
      );
      final json = score.toJson();
      expect(json.keys, containsAll([
        'overallScore',
        'totalIssues',
        'totalWeight',
        'maxPossibleWeight',
        'categoryScores',
        'priorityGroups',
        'recommendations',
      ]));
    });

    test('toJson produces correct nested structure for categoryScores', () {
      final score = createScore();
      final json = score.toJson();
      expect(json['categoryScores'], [
        {
          'category': 'performance',
          'displayName': 'Performance',
          'score': 92.0,
          'totalIssues': 4,
          'totalWeight': 46,
        },
      ]);
    });

    test('toJson produces correct nested structure for priorityGroups', () {
      final score = createScore(
        critical: [criticalIssue],
        high: [errorIssue],
        medium: [warningIssue],
        low: [infoIssue, infoIssue2],
      );
      final json = score.toJson();
      final groups = json['priorityGroups'] as Map<String, dynamic>;

      expect(groups['critical'], [
        {
          'code': 'CRIT001',
          'severity': 'critical',
          'title': 'Critical bug',
          'filePath': 'lib/main.dart',
          'lineNumber': 10,
        },
      ]);

      expect(groups['high'], [
        {
          'code': 'ERR001',
          'severity': 'error',
          'title': 'Error bug',
        },
      ]);

      expect(groups['medium'], [
        {
          'code': 'WARN001',
          'severity': 'warning',
          'title': 'Warning bug',
          'filePath': 'lib/utils.dart',
        },
      ]);

      expect(groups['low'], [
        {
          'code': 'INFO001',
          'severity': 'info',
          'title': 'Info suggestion',
          'lineNumber': 42,
        },
        {
          'code': 'INFO002',
          'severity': 'info',
          'title': 'Another suggestion',
        },
      ]);
    });

    test('toJson produces correct nested structure for recommendations', () {
      final score = createScore();
      final json = score.toJson();
      expect(json['recommendations'], [
        {
          'code': 'CRIT001',
          'title': 'Critical bug',
          'severity': 'critical',
          'weight': 25,
        },
      ]);
    });

    test('toJson totalIssues matches sum of all groups', () {
      final score = createScore(
        critical: [criticalIssue],
        high: [errorIssue],
        medium: [warningIssue],
        low: [infoIssue, infoIssue2],
      );
      final json = score.toJson();
      expect(json['totalIssues'], 5);
    });
  });
}
