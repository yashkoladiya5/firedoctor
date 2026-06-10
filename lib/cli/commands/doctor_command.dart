import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/services/report_service.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class DoctorCommand extends Command {
  @override
  String get name => 'doctor';
  @override
  String get description => 'Run all FireDoctor checks and generate analysis';

  final Logger logger;
  final Terminal terminal;
  final FileSystem fileSystem;
  final AnalyzerService analyzerService;

  DoctorCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
    required this.analyzerService,
  });

  @override
  Future<int> execute(List<String> args) async {
    final projectPath =
        args.isNotEmpty ? args.first : fileSystem.currentDirectory;

    if (!fileSystem.exists(projectPath) ||
        !fileSystem.isDirectory(projectPath)) {
      terminal.writeError('Project path does not exist: $projectPath');
      return AppConstants.exitFailure;
    }

    terminal.writeLine('Running FireDoctor analysis on $projectPath...');
    terminal.writeLine('');

    final context = AnalyzerContext(
      projectPath: projectPath,
      fileSystem: fileSystem,
    );

    List<DiagnosticResult> results;
    try {
      results = await analyzerService.runAll(context);
    } catch (e) {
      terminal.writeError('Analysis failed: $e');
      return AppConstants.exitFailure;
    }

    final projectName = _extractProjectName(results);

    final report = ReportService(terminal: terminal).generateReport(
      results: results,
      projectName: projectName,
      projectPath: projectPath,
    );

    ReportService(terminal: terminal).printReport(report);

    final hasCriticalOrError = results.any(
      (r) => r.issues.any(
        (i) => i.severity == Severity.error || i.severity == Severity.critical,
      ),
    );

    return hasCriticalOrError
        ? AppConstants.exitFailure
        : AppConstants.exitSuccess;
  }

  String _extractProjectName(List<DiagnosticResult> results) {
    for (final result in results) {
      if (result.analyzerName == 'project') {
        for (final issue in result.issues) {
          if (issue.code == 'MISSING_PUBSPEC') return 'unknown';
        }
      }
    }
    return 'unknown';
  }
}
