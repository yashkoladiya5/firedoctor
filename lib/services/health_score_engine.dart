import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/diagnostic_report.dart';
import 'package:firedoctor/models/health_score.dart';
import 'package:firedoctor/models/score_weights.dart';

final class HealthScoreEngine {
  final ScoreWeights weights;
  final int maxRecommendations;

  const HealthScoreEngine({
    this.weights = const ScoreWeights(),
    this.maxRecommendations = 3,
  });

  static const categoryDisplayNames = {
    'project': 'Project Health',
    'dependency': 'Dependencies Health',
    'firebase_core': 'Firebase Core Health',
    'android': 'Android Health',
    'ios': 'iOS Health',
    'fcm': 'Messaging Health',
    'crashlytics': 'Crashlytics Health',
  };

  HealthScore compute(DiagnosticReport report) {
    return computeFromResults(report.results);
  }

  HealthScore computeFromResults(List<DiagnosticResult> results) {
    final allIssues = <DiagnosticIssue>[];
    final analyzerIssues = <String, List<DiagnosticIssue>>{};

    for (final result in results) {
      for (final issue in result.issues) {
        allIssues.add(issue);
        analyzerIssues.putIfAbsent(result.analyzerName, () => []);
        analyzerIssues[result.analyzerName]!.add(issue);
      }
    }

    final categoryScores = _computeCategoryScores(results, analyzerIssues);
    final priorityGroups = _buildPriorityGroups(allIssues);
    final totalWeight = _computeTotalWeight(allIssues);
    final maxPossibleWeight = _computeMaxPossibleWeight(allIssues);
    final overallScore = _computeOverallScore(totalWeight, maxPossibleWeight);
    final recommendations = _generateRecommendations(
      allIssues,
      maxRecommendations,
    );

    return HealthScore(
      overallScore: overallScore,
      categoryScores: categoryScores,
      priorityGroups: priorityGroups,
      recommendations: recommendations,
      totalWeight: totalWeight,
      maxPossibleWeight: maxPossibleWeight,
      weights: weights,
    );
  }

  List<CategoryScore> _computeCategoryScores(
    List<DiagnosticResult> results,
    Map<String, List<DiagnosticIssue>> analyzerIssues,
  ) {
    final scores = <CategoryScore>[];
    final analyzedCategories = <String>{};

    for (final result in results) {
      final category = result.analyzerName;
      analyzedCategories.add(category);
      final issues = analyzerIssues[category] ?? [];
      final totalWeight =
          issues.fold(0, (sum, i) => sum + weights.weightFor(i.severity));

      double score;
      if (issues.isEmpty) {
        score = 100.0;
      } else {
        final categoryMaxWeight = issues.length * weights.maxScorePerIssue;
        if (categoryMaxWeight <= 0) {
          score = 100.0;
        } else {
          score =
              ((categoryMaxWeight - totalWeight) / categoryMaxWeight * 100)
                  .clamp(0.0, 100.0);
        }
      }

      scores.add(CategoryScore(
        category: category,
        displayName: categoryDisplayNames[category] ?? _titleCase(category),
        score: score,
        totalIssues: issues.length,
        totalWeight: totalWeight,
      ));
    }

    return scores;
  }

  Map<PriorityGroup, List<DiagnosticIssue>> _buildPriorityGroups(
    List<DiagnosticIssue> issues,
  ) {
    final groups = <PriorityGroup, List<DiagnosticIssue>>{};
    for (final group in PriorityGroup.values) {
      groups[group] = [];
    }

    for (final issue in issues) {
      final group = PriorityGroup.fromSeverity(issue.severity);
      groups[group]!.add(issue);
    }

    return groups;
  }

  int _computeTotalWeight(List<DiagnosticIssue> issues) {
    return issues.fold(0, (sum, i) => sum + weights.weightFor(i.severity));
  }

  int _computeMaxPossibleWeight(List<DiagnosticIssue> issues) {
    if (issues.isEmpty) return 1;
    return issues.length * weights.maxScorePerIssue;
  }

  double _computeOverallScore(int totalWeight, int maxPossibleWeight) {
    if (maxPossibleWeight == 0) return 100.0;
    return ((maxPossibleWeight - totalWeight) / maxPossibleWeight * 100)
        .clamp(0.0, 100.0);
  }

  List<Recommendation> _generateRecommendations(
    List<DiagnosticIssue> issues,
    int count,
  ) {
    final sorted = List<DiagnosticIssue>.from(issues)
      ..sort((a, b) {
        final weightCompare =
            weights.weightFor(b.severity).compareTo(weights.weightFor(a.severity));
        if (weightCompare != 0) return weightCompare;
        return a.code.compareTo(b.code);
      });

    return sorted.take(count).map((issue) {
      return Recommendation(
        code: issue.code,
        title: issue.title,
        severity: issue.severity.name,
        weight: weights.weightFor(issue.severity),
      );
    }).toList();
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(RegExp(r'[_\s]'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}
