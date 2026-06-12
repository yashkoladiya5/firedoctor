import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/severity.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/services/report_service.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class ReportCommand extends Command {
  @override
  String get name => 'report';
  @override
  String get description => 'Generate a diagnostic report for the project';

  final Logger logger;
  final Terminal terminal;
  final FileSystem fileSystem;
  final AnalyzerService analyzerService;

  ReportCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
    required this.analyzerService,
  });

  @override
  Future<int> execute(List<String> args) async {
    var asJson = false;
    Severity failOn = Severity.error;
    double? minScore;
    String? outputPath;
    String? projectPath;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--json') {
        asJson = true;
      } else if (arg == '--output') {
        if (i + 1 < args.length) {
          outputPath = args[++i];
        } else {
          terminal.writeError('Missing value for --output flag');
          return AppConstants.exitInternalFailure;
        }
      } else if (arg == '--fail-on') {
        if (i + 1 < args.length) {
          failOn = _parseSeverity(args[++i]);
        } else {
          terminal.writeError('Missing value for --fail-on flag');
          return AppConstants.exitInternalFailure;
        }
      } else if (arg == '--min-score') {
        if (i + 1 < args.length) {
          final parsed = double.tryParse(args[++i]);
          if (parsed == null || parsed < 0 || parsed > 100) {
            terminal.writeError(
                'Invalid --min-score value. Must be a number between 0 and 100.');
            return AppConstants.exitInternalFailure;
          }
          minScore = parsed;
        } else {
          terminal.writeError('Missing value for --min-score flag');
          return AppConstants.exitInternalFailure;
        }
      } else {
        projectPath = arg;
      }
    }

    projectPath ??= fileSystem.currentDirectory;

    if (!fileSystem.exists(projectPath) ||
        !fileSystem.isDirectory(projectPath)) {
      terminal.writeError('Project path does not exist: $projectPath');
      return AppConstants.exitInternalFailure;
    }

    terminal.writeLine('Generating report for $projectPath...');
    terminal.writeLine('');

    final context = AnalyzerContext(
      projectPath: projectPath,
      fileSystem: fileSystem,
    );

    List<DiagnosticResult> results;
    try {
      results = await analyzerService.runAll(context);
    } catch (e) {
      terminal.writeError('Report generation failed: $e');
      return AppConstants.exitInternalFailure;
    }

    final reportService = ReportService(terminal: terminal);

    final projectName = results
        .map((r) => r.projectName)
        .firstWhere((n) => n != null, orElse: () => null);

    var report = reportService.generateReport(
      results: results,
      projectName: projectName,
      projectPath: projectPath,
    );

    // Re-compute health score if minScore is set to ensure it's always present
    if (minScore != null && report.healthScore == null) {
      report = report.computeHealthScore();
    }

    if (asJson && outputPath != null) {
      await reportService.saveReport(report, fileSystem, outputPath);
      terminal.writeSuccess('Report saved to $outputPath');
      terminal.writeLine('');
    } else if (asJson) {
      terminal.writeLine(reportService.toJson(report));
    } else if (outputPath != null) {
      await reportService.saveReport(report, fileSystem, outputPath);
      terminal.writeSuccess('Report saved to $outputPath');
      terminal.writeLine('');
    } else {
      reportService.printReport(report);
    }

    // Check --min-score threshold
    if (minScore != null) {
      final score = report.healthScore?.overallScore ?? report.score;
      if (score < minScore) {
        terminal.writeWarning(
            'Score ${score.toStringAsFixed(1)} is below threshold $minScore');
        return AppConstants.exitInternalFailure;
      }
    }

    // Check --fail-on threshold
    final mostSevere = report.mostSevereRank;
    final failOnRank = failOn.value + 1;
    if (mostSevere >= failOnRank) {
      return report.exitCode;
    }

    return AppConstants.exitNoIssues;
  }

  Severity _parseSeverity(String value) {
    switch (value.toLowerCase()) {
      case 'warning':
      case 'warn':
        return Severity.warning;
      case 'error':
        return Severity.error;
      case 'critical':
        return Severity.critical;
      default:
        return Severity.error;
    }
  }
}
