import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
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
          return AppConstants.exitFailure;
        }
      } else {
        projectPath = arg;
      }
    }

    projectPath ??= fileSystem.currentDirectory;

    if (!fileSystem.exists(projectPath) ||
        !fileSystem.isDirectory(projectPath)) {
      terminal.writeError('Project path does not exist: $projectPath');
      return AppConstants.exitFailure;
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
      return AppConstants.exitFailure;
    }

    final reportService = ReportService(terminal: terminal);

    final projectName = results
        .map((r) => r.projectName)
        .firstWhere((n) => n != null, orElse: () => null);

    final report = reportService.generateReport(
      results: results,
      projectName: projectName,
      projectPath: projectPath,
    );

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

    final hasCriticalOrError = results.any(
      (r) => r.issues.any(
        (i) => i.severity == Severity.error || i.severity == Severity.critical,
      ),
    );

    return hasCriticalOrError
        ? AppConstants.exitFailure
        : AppConstants.exitSuccess;
  }
}
