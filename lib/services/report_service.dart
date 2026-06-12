import 'dart:convert';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/health_score_engine.dart';
import 'package:firedoctor/terminal/terminal.dart';
import 'package:firedoctor/filesystem/filesystem.dart';

final class ReportService {
  final Terminal terminal;
  final HealthScoreEngine healthScoreEngine;

  const ReportService({
    required this.terminal,
    this.healthScoreEngine = const HealthScoreEngine(),
  });

  DiagnosticReport generateReport({
    required List<DiagnosticResult> results,
    String? projectName,
    String? projectPath,
    String? firebaseVersion,
    Map<String, String>? environment,
    bool computeHealthScore = true,
  }) {
    var report = DiagnosticReport(
      projectName: projectName ?? 'unknown',
      projectPath: projectPath ?? '',
      createdAt: DateTime.now(),
      results: results,
      firebaseVersion: firebaseVersion,
      environment: environment ?? {},
    );

    if (computeHealthScore) {
      report = report.computeHealthScore(engine: healthScoreEngine);
    }

    return report;
  }

  void printReport(DiagnosticReport report) {
    terminal.writeLine('');
    terminal.writeLine('═══════════════════════════════════════════');
    terminal.writeLine('  FireDoctor Diagnostic Report');
    terminal.writeLine('═══════════════════════════════════════════');
    terminal.writeLine('');

    terminal.writeLine('  ┌─ Project');
    terminal.writeLine('  │ Project: ${report.projectName}');
    terminal.writeLine('  │ Path: ${report.projectPath}');
    terminal.writeLine('  └─');

    if (report.healthScore != null) {
      final hs = report.healthScore!;
      terminal.writeLine('');
      terminal.writeLine('  ┌─ Health Score');
      terminal.writeLine(
          '  │ Overall: ${_formatScore(hs.overallScore)}/100');
      terminal.writeLine('  │ Issues: ${hs.totalIssues}');
      terminal.writeLine(
          '  │ Weight: ${hs.totalWeight}/${hs.maxPossibleWeight}');
      terminal.writeLine('  └─');

      terminal.writeLine('');
      terminal.writeLine('  ┌─ Category Scores');
      for (final cat in hs.categoryScores) {
        final bar = _scoreBar(cat.score);
        terminal.writeLine(
          '  │ ${cat.displayName}: ${_formatScore(cat.score)}/100 $bar',
        );
      }
      terminal.writeLine('  └─');

      terminal.writeLine('');
      terminal.writeLine('  ┌─ Priority Breakdown');
      for (final group in PriorityGroup.values) {
        final count = hs.priorityGroups[group]?.length ?? 0;
        if (count > 0) {
          terminal.writeLine('  │ ${group.label}: $count');
        }
      }
      terminal.writeLine('  └─');

      if (hs.recommendations.isNotEmpty) {
        terminal.writeLine('');
        terminal.writeLine('  ┌─ Recommended Next Actions');
        for (var i = 0; i < hs.recommendations.length; i++) {
          final rec = hs.recommendations[i];
          terminal.writeLine(
            '  │ ${i + 1}. ${rec.formatted}',
          );
        }
        terminal.writeLine('  └─');
      }
    }

    terminal.writeLine('');
    terminal.writeLine('  ┌─ Analyzer Results');
    for (final result in report.results) {
      terminal.writeLine('  │ ${result.analyzerName}: ${result.status.label}');
      for (final issue in result.issues) {
        terminal.writeLine(
            '  │   ${issue.severity.emoji} [${issue.code}] ${issue.title}');
      }
    }
    terminal.writeLine('  └─');

    terminal.writeLine('');
    terminal.writeLine('  Score: ${report.score.toStringAsFixed(1)}/100');
    terminal.writeLine(
        '  Status: ${report.passed ? "PASSED" : "FAILED"}');
    terminal.writeLine('');
    terminal.writeLine('  Issues: ${report.totalIssues}');
    terminal.writeLine('  Errors: ${report.totalErrors}');
    terminal.writeLine('  Warnings: ${report.totalWarnings}');
    terminal.writeLine('');
  }

  String toJson(DiagnosticReport report) {
    final map = <String, dynamic>{
      'schemaVersion': AppConstants.jsonSchemaVersion,
      'firedoctorVersion': AppConstants.version,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'projectName': report.projectName,
      'projectPath': report.projectPath,
      'createdAt': report.createdAt.toIso8601String(),
      'score': report.score,
      'passed': report.passed,
      'exitCode': report.exitCode,
      'mostSevereRank': report.mostSevereRank,
      'totalIssues': report.totalIssues,
      'totalErrors': report.totalErrors,
      'totalWarnings': report.totalWarnings,
      'environment': report.environment,
      if (report.firebaseVersion != null)
        'firebaseVersion': report.firebaseVersion,
      'analyzerResults': report.results
          .map((r) => {
                'analyzerName': r.analyzerName,
                'status': r.status.name,
                'duration': r.duration.inMilliseconds,
                'timestamp': r.timestamp.toIso8601String(),
                'issueCount': r.issueCount,
                'errorCount': r.errorCount,
                'warningCount': r.warningCount,
                'mostSevereRank': r.mostSevereRank,
                'issues': r.issues
                    .map((i) => {
                          'severity': i.severity.name,
                          'code': i.code,
                          'title': i.title,
                          'description': i.description,
                          if (i.recommendation != null)
                            'recommendation': i.recommendation,
                          if (i.filePath != null) 'filePath': i.filePath,
                          if (i.lineNumber != null)
                            'lineNumber': i.lineNumber,
                        })
                    .toList(),
              })
          .toList(),
    };

    if (report.healthScore != null) {
      map['healthScore'] = report.healthScore!.toJson();
    }

    // Top-level category scores (shorthand)
    if (report.healthScore != null) {
      map['categoryScores'] = report.healthScore!.categoryScores
          .map((c) => c.toJson())
          .toList();
      map['recommendations'] = report.healthScore!.recommendations
          .map((r) => r.toJson())
          .toList();
    }

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<void> saveReport(
      DiagnosticReport report, FileSystem fs, String outputPath) async {
    final json = toJson(report);
    await fs.writeAsStringAsync(outputPath, json);
  }

  String _formatScore(double score) => score.toStringAsFixed(1);

  String _scoreBar(double score) {
    final filled = (score / 20).round().clamp(0, 5);
    final empty = 5 - filled;
    final bar = StringBuffer();
    bar.write('[');
    bar.write('█' * filled);
    bar.write('░' * empty);
    bar.write(']');
    return bar.toString();
  }
}
