import 'dart:convert';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/terminal/terminal.dart';
import 'package:firedoctor/filesystem/filesystem.dart';

final class ReportService {
  final Terminal terminal;

  const ReportService({required this.terminal});

  DiagnosticReport generateReport({
    required List<DiagnosticResult> results,
    String? projectName,
    String? projectPath,
    String? firebaseVersion,
    Map<String, String>? environment,
  }) {
    return DiagnosticReport(
      projectName: projectName ?? 'unknown',
      projectPath: projectPath ?? '',
      createdAt: DateTime.now(),
      results: results,
      firebaseVersion: firebaseVersion,
      environment: environment ?? {},
    );
  }

  void printReport(DiagnosticReport report) {
    terminal.writeLine('');
    terminal.writeLine('═══════════════════════════════════════════');
    terminal.writeLine('  FireDoctor Diagnostic Report');
    terminal.writeLine('═══════════════════════════════════════════');
    terminal.writeLine('');
    terminal.writeLine('  Project: ${report.projectName}');
    terminal.writeLine('  Path: ${report.projectPath}');
    terminal.writeLine('  Score: ${report.score.toStringAsFixed(1)}/100');
    terminal.writeLine('  Status: ${report.passed ? "PASSED" : "FAILED"}');
    terminal.writeLine('');
    terminal.writeLine('  Issues: ${report.totalIssues}');
    terminal.writeLine('  Errors: ${report.totalErrors}');
    terminal.writeLine('  Warnings: ${report.totalWarnings}');
    terminal.writeLine('');

    for (final result in report.results) {
      terminal.writeLine('  ${result.analyzerName}: ${result.status.label}');
      for (final issue in result.issues) {
        terminal.writeLine(
            '    ${issue.severity.emoji} [${issue.code}] ${issue.title}');
      }
    }
    terminal.writeLine('');
  }

  String toJson(DiagnosticReport report) {
    final map = {
      'projectName': report.projectName,
      'projectPath': report.projectPath,
      'createdAt': report.createdAt.toIso8601String(),
      'score': report.score,
      'passed': report.passed,
      'totalIssues': report.totalIssues,
      'totalErrors': report.totalErrors,
      'totalWarnings': report.totalWarnings,
      'environment': report.environment,
      if (report.firebaseVersion != null)
        'firebaseVersion': report.firebaseVersion,
      'results': report.results
          .map((r) => {
                'analyzerName': r.analyzerName,
                'status': r.status.name,
                'duration': r.duration.inMilliseconds,
                'timestamp': r.timestamp.toIso8601String(),
                'issueCount': r.issueCount,
                'issues': r.issues
                    .map((i) => {
                          'severity': i.severity.name,
                          'code': i.code,
                          'title': i.title,
                          'description': i.description,
                          if (i.recommendation != null)
                            'recommendation': i.recommendation,
                          if (i.filePath != null) 'filePath': i.filePath,
                          if (i.lineNumber != null) 'lineNumber': i.lineNumber,
                        })
                    .toList(),
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<void> saveReport(
      DiagnosticReport report, FileSystem fs, String outputPath) async {
    final json = toJson(report);
    await fs.writeAsStringAsync(outputPath, json);
  }
}
