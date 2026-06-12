import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/health_score.dart';
import 'package:firedoctor/services/health_score_engine.dart';

final class DiagnosticReport {
  final String projectName;
  final String projectPath;
  final DateTime createdAt;
  final List<DiagnosticResult> results;
  final String? firebaseVersion;
  final Map<String, String> environment;
  final HealthScore? healthScore;

  const DiagnosticReport({
    required this.projectName,
    required this.projectPath,
    required this.createdAt,
    required this.results,
    this.firebaseVersion,
    this.environment = const {},
    this.healthScore,
  });

  int get totalIssues => results.fold(0, (sum, r) => sum + r.issueCount);
  int get totalErrors => results.fold(0, (sum, r) => sum + r.errorCount);
  int get totalWarnings => results.fold(0, (sum, r) => sum + r.warningCount);

  double get score {
    if (results.isEmpty) return 100.0;
    final total = totalIssues;
    if (total == 0) return 100.0;
    final weighted = totalErrors * 3 + totalWarnings * 1;
    final maxWeighted = total * 3;
    return ((maxWeighted - weighted) / maxWeighted * 100).clamp(0.0, 100.0);
  }

  bool get passed => results.every((r) => r.passed);

  /// The highest severity rank across all results.
  /// 0 = no issues, 1 = info only, 2 = warnings, 3 = errors, 4 = critical.
  int get mostSevereRank {
    var rank = 0;
    for (final r in results) {
      final rRank = r.mostSevereRank;
      if (rRank > rank) rank = rRank;
    }
    return rank;
  }

  /// CI-friendly exit code:
  ///   0 = no issues
  ///   1 = warnings only
  ///   2 = errors (but no critical)
  ///   3 = critical issues
  int get exitCode => AppConstants.exitCodeForSeverityRank(mostSevereRank);

  DiagnosticReport computeHealthScore({HealthScoreEngine? engine}) {
    final hse = engine ?? const HealthScoreEngine();
    return DiagnosticReport(
      projectName: projectName,
      projectPath: projectPath,
      createdAt: createdAt,
      results: results,
      firebaseVersion: firebaseVersion,
      environment: environment,
      healthScore: hse.compute(this),
    );
  }
}
