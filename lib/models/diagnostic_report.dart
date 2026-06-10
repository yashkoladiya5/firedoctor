import 'package:firedoctor/models/diagnostic_result.dart';

final class DiagnosticReport {
  final String projectName;
  final String projectPath;
  final DateTime createdAt;
  final List<DiagnosticResult> results;
  final String? firebaseVersion;
  final Map<String, String> environment;

  const DiagnosticReport({
    required this.projectName,
    required this.projectPath,
    required this.createdAt,
    required this.results,
    this.firebaseVersion,
    this.environment = const {},
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
}
