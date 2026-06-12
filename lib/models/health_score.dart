import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/score_weights.dart';
import 'package:firedoctor/models/severity.dart';

enum PriorityGroup {
  critical('Critical Fixes', 0),
  high('High Priority', 1),
  medium('Medium Priority', 2),
  low('Low Priority', 3);

  /// Public property or field.
  final String label;
  /// Public property or field.
  final int rank;
  const PriorityGroup(this.label, this.rank);

  static PriorityGroup fromSeverity(Severity severity) {
    if (severity == Severity.critical) return PriorityGroup.critical;
    if (severity == Severity.error) return PriorityGroup.high;
    if (severity == Severity.warning) return PriorityGroup.medium;
    return PriorityGroup.low;
  }
}

/// Core class.
final class CategoryScore {
  /// Public property or field.
  final String category;
  /// Public property or field.
  final String displayName;
  /// Public property or field.
  final double score;
  /// Public property or field.
  final int totalIssues;
  /// Public property or field.
  final int totalWeight;

  const CategoryScore({
    required this.category,
    required this.displayName,
    required this.score,
    required this.totalIssues,
    required this.totalWeight,
  });

  /// Public method or function.
  Map<String, dynamic> toJson() => {
    'category': category,
    'displayName': displayName,
    'score': score,
    'totalIssues': totalIssues,
    'totalWeight': totalWeight,
  };
}

/// Core class.
final class Recommendation {
  /// Public property or field.
  final String code;
  /// Public property or field.
  final String title;
  /// Public property or field.
  final String severity;
  /// Public property or field.
  final int weight;

  const Recommendation({
    required this.code,
    required this.title,
    required this.severity,
    required this.weight,
  });

  String get formatted => 'Fix $code: $title';

  /// Public method or function.
  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'severity': severity,
    'weight': weight,
  };
}

/// Core class.
final class HealthScore {
  /// Public property or field.
  final double overallScore;
  /// Public property or field.
  final List<CategoryScore> categoryScores;
  /// Public property or field.
  final Map<PriorityGroup, List<DiagnosticIssue>> priorityGroups;
  /// Public property or field.
  final List<Recommendation> recommendations;
  /// Public property or field.
  final int totalWeight;
  /// Public property or field.
  final int maxPossibleWeight;
  /// Public property or field.
  final ScoreWeights weights;

  const HealthScore({
    required this.overallScore,
    required this.categoryScores,
    required this.priorityGroups,
    required this.recommendations,
    required this.totalWeight,
    required this.maxPossibleWeight,
    required this.weights,
  });

  List<DiagnosticIssue> get criticalIssues =>
      priorityGroups[PriorityGroup.critical] ?? const [];

  List<DiagnosticIssue> get highPriorityIssues =>
      priorityGroups[PriorityGroup.high] ?? const [];

  List<DiagnosticIssue> get mediumPriorityIssues =>
      priorityGroups[PriorityGroup.medium] ?? const [];

  List<DiagnosticIssue> get lowPriorityIssues =>
      priorityGroups[PriorityGroup.low] ?? const [];

  int get totalIssues =>
      criticalIssues.length +
      highPriorityIssues.length +
      mediumPriorityIssues.length +
      lowPriorityIssues.length;

  /// Public method or function.
  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'totalIssues': totalIssues,
    'totalWeight': totalWeight,
    'maxPossibleWeight': maxPossibleWeight,
    'categoryScores': categoryScores.map((c) => c.toJson()).toList(),
    'priorityGroups': {
      for (final group in PriorityGroup.values)
        group.name: (priorityGroups[group] ?? [])
            .map(
              (issue) => {
                'code': issue.code,
                'severity': issue.severity.name,
                'title': issue.title,
                if (issue.filePath != null) 'filePath': issue.filePath,
                if (issue.lineNumber != null) 'lineNumber': issue.lineNumber,
              },
            )
            .toList(),
    },
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
  };
}