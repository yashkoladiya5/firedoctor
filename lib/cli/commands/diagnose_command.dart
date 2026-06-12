import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/diagnostic_issue.dart';
import 'package:firedoctor/models/diagnostic_report.dart';
import 'package:firedoctor/models/diagnostic_result.dart';
import 'package:firedoctor/models/check_status.dart';
import 'package:firedoctor/models/severity.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

/// Core class.
final class DiagnoseCommand extends Command {
  @override
  String get name => 'diagnose';
  @override
  String get description => 'Run Firebase diagnostics on the project';

  /// Public property or field.
  final Logger logger;
  /// Public property or field.
  final Terminal terminal;
  /// Public property or field.
  final FileSystem fileSystem;
  /// Public property or field.
  final AnalyzerService analyzerService;

  DiagnoseCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
    required this.analyzerService,
  });

  @override
  /// Public method or function.
  Future<int> execute(List<String> args) async {
    final projectPath = args.isNotEmpty
        ? args.first
        : fileSystem.currentDirectory;

    if (!fileSystem.exists(projectPath) ||
        !fileSystem.isDirectory(projectPath)) {
      terminal.writeError('Project path does not exist: $projectPath');
      return AppConstants.exitInternalFailure;
    }

    terminal.writeLine('Diagnosing Firebase setup in $projectPath...');
    terminal.writeLine('');

    final context = AnalyzerContext(
      projectPath: projectPath,
      fileSystem: fileSystem,
    );

    List<DiagnosticResult> results;
    try {
      results = await analyzerService.runAll(context);
    } catch (e) {
      terminal.writeError('Diagnosis failed: $e');
      return AppConstants.exitInternalFailure;
    }

    for (final result in results) {
      _printAnalyzerHeader(result);

      if (result.issues.isEmpty) {
        terminal.writeSuccess('  No issues found.');
        terminal.writeLine('');
        continue;
      }

      for (final issue in result.issues) {
        _printIssue(issue);
      }
      terminal.writeLine('');
    }

    _printSummary(results);

    // Deterministic exit codes
    final report = DiagnosticReport(
      projectName: '',
      projectPath: '',
      createdAt: DateTime.now(),
      results: results,
    );
    return report.exitCode;
  }

  void _printAnalyzerHeader(DiagnosticResult result) {
    terminal.writeLine(
      '── ${result.analyzerName} ── ${result.status.label} ──',
    );
  }

  void _printIssue(DiagnosticIssue issue) {
    terminal.writeLine('${issue.severity.emoji} ${issue.code}');
    terminal.writeLine('  ${issue.title}');

    if (issue.filePath != null) {
      final location = issue.lineNumber != null
          ? '${issue.filePath}:${issue.lineNumber}'
          : issue.filePath!;
      terminal.writeLine('  Location: $location');
    }

    if (issue.recommendation != null) {
      terminal.writeLine(
        '  Recommendation: ${issue.recommendation!.replaceAll('\n', '\n    ')}',
      );
    }
    terminal.writeLine('');
  }

  void _printSummary(List<DiagnosticResult> results) {
    var totalErrors = 0;
    var totalWarnings = 0;
    var totalInfos = 0;
    var totalSkipped = 0;
    var totalPassed = 0;

    for (final r in results) {
      for (final i in r.issues) {
        if (i.severity == Severity.critical || i.severity == Severity.error) {
          totalErrors++;
        } else if (i.severity == Severity.warning) {
          totalWarnings++;
        } else {
          totalInfos++;
        }
      }
      if (r.status == CheckStatus.skipped) {
        totalSkipped++;
      } else if (r.status.isPassed) {
        totalPassed++;
      }
    }

    terminal.writeLine('══ Summary ══');
    terminal.writeLine('  Analyzers run: ${results.length}');
    terminal.writeLine('  Passed: $totalPassed | Skipped: $totalSkipped');
    terminal.writeLine(
      '  Errors: $totalErrors | Warnings: $totalWarnings | Info: $totalInfos',
    );
    terminal.writeLine('');
  }
}