import 'package:firedoctor/models/check_status.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/severity.dart';

final class DiagnosticResult {
  final String analyzerName;
  final CheckStatus status;
  final List<DiagnosticIssue> issues;
  final Duration duration;
  final DateTime timestamp;
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
      .where((i) =>
          i.severity == Severity.error || i.severity == Severity.critical)
      .length;
  int get warningCount =>
      issues.where((i) => i.severity == Severity.warning).length;
  bool get passed => status.isPassed;
}
