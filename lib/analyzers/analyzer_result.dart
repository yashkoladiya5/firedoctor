import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/severity.dart';

extension AnalyzerResultExtension on DiagnosticResult {
  bool get hasCriticalIssues => issues.any((i) => i.severity == Severity.critical);
  bool get hasErrors => issues.any((i) => i.severity == Severity.error);
  bool get hasWarnings => issues.any((i) => i.severity == Severity.warning);

  List<DiagnosticIssue> get issuesBySeverity {
    final sorted = List<DiagnosticIssue>.from(issues);
    sorted.sort((a, b) => b.severity.compareTo(a.severity));
    return sorted;
  }
}
