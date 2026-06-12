import 'package:firedoctor/models/check_status.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/severity.dart';

/// Core class.
final class DiagnosticResult {
  /// Public property or field.
  final String analyzerName;
  /// Public property or field.
  final CheckStatus status;
  /// Public property or field.
  final List<DiagnosticIssue> issues;
  /// Public property or field.
  final Duration duration;
  /// Public property or field.
  final DateTime timestamp;
  /// Public property or field.
  final String? projectName;

  const DiagnosticResult({
    required this.analyzerName,
    required this.status,
    required this.issues,
    required this.duration,
    required this.timestamp,
    this.projectName,
  });

  int get issueCount => issues.length;
  int get errorCount => issues
      .where(
        (i) => i.severity == Severity.error || i.severity == Severity.critical,
      )
      .length;
  int get warningCount =>
      issues.where((i) => i.severity == Severity.warning).length;
  bool get passed => status.isPassed;

  /// The highest severity rank among all issues.
  /// Returns 0 if no issues.
  int get mostSevereRank {
    var rank = 0;
    for (final issue in issues) {
      final r = issue.severity.value + 1;
      if (r > rank) rank = r;
    }
    return rank;
  }
}