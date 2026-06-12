import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/services/validation_service.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class ValidateCommand extends Command {
  @override
  String get name => 'validate';
  @override
  String get description =>
      'Run validation suite against test projects and report accuracy metrics';
  @override
  List<String> get aliases => ['val'];

  final Logger logger;
  final Terminal terminal;
  final FileSystem fileSystem;
  final AnalyzerService analyzerService;

  ValidateCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
    required this.analyzerService,
  });

  @override
  Future<int> execute(List<String> args) async {
    String? projectsDir;
    String? outputPath;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--output' && i + 1 < args.length) {
        outputPath = args[++i];
      } else {
        projectsDir = arg;
      }
    }

    // Default: look for validation/projects/ relative to cwd
    projectsDir ??= fileSystem.join(
      fileSystem.currentDirectory,
      'validation',
      'projects',
    );

    // Also try as relative to the package root
    if (!fileSystem.exists(projectsDir)) {
      // Try relative to current directory
      projectsDir = fileSystem.join(
        fileSystem.currentDirectory,
        'validation',
        'projects',
      );
    }

    if (!fileSystem.exists(projectsDir) ||
        !fileSystem.isDirectory(projectsDir)) {
      terminal.writeError(
        'Validation projects directory not found: $projectsDir',
      );
      terminal.writeLine('Run this from the package root or specify a path.');
      return AppConstants.exitInternalFailure;
    }

    terminal.writeLine('FireDoctor Validation Suite');
    terminal.writeLine('═══════════════════════════');
    terminal.writeLine('');
    terminal.writeLine('Projects directory: $projectsDir');
    terminal.writeLine('');

    final service = ValidationService(
      analyzerService: analyzerService,
      fileSystem: fileSystem,
      logger: logger,
    );

    ValidationReport report;
    try {
      report = await service.validateAll(projectsDir, progressLogger: logger);
    } catch (e) {
      terminal.writeError('Validation failed: $e');
      return AppConstants.exitInternalFailure;
    }

    // Print summary
    terminal.writeLine('');
    terminal.writeLine('Results');
    terminal.writeLine('───────');
    terminal.writeLine('');

    for (final entry in report.entries) {
      terminal.writeLine('  ${entry.projectName}');
      terminal.writeLine(
        '    Accuracy:  ${(entry.accuracy * 100).toStringAsFixed(1)}%',
      );
      terminal.writeLine(
        '    Precision: ${(entry.precision * 100).toStringAsFixed(1)}%',
      );
      terminal.writeLine(
        '    Recall:    ${(entry.recall * 100).toStringAsFixed(1)}%',
      );
      terminal.writeLine(
        '    TP: ${entry.truePositives.length}  FP: ${entry.falsePositives.length}  FN: ${entry.falseNegatives.length}',
      );
      if (entry.falsePositives.isNotEmpty) {
        terminal.writeLine('    False Positives:');
        for (final fp in entry.falsePositives) {
          terminal.writeLine('      - [${fp.code}] ${fp.title}');
        }
      }
      if (entry.falseNegatives.isNotEmpty) {
        terminal.writeLine('    False Negatives:');
        for (final fn in entry.falseNegatives) {
          terminal.writeLine('      - [${fn.code}] (${fn.analyzerName})');
        }
      }
      terminal.writeLine('');
    }

    terminal.writeLine('Overall Metrics');
    terminal.writeLine('───────────────');
    terminal.writeLine(
      '  Accuracy:      ${(report.overallAccuracy * 100).toStringAsFixed(1)}%',
    );
    terminal.writeLine(
      '  Precision:     ${(report.overallPrecision * 100).toStringAsFixed(1)}%',
    );
    terminal.writeLine(
      '  Recall:        ${(report.overallRecall * 100).toStringAsFixed(1)}%',
    );
    terminal.writeLine('  True Positives:   ${report.totalTruePositives}');
    terminal.writeLine('  False Positives:  ${report.totalFalsePositives}');
    terminal.writeLine('  False Negatives:  ${report.totalFalseNegatives}');

    terminal.writeLine('');
    terminal.writeLine('Per-Analyzer Precision');
    for (final entry in report.analyzerPrecision.entries) {
      terminal.writeLine(
        '  ${entry.key.padRight(16)} ${(entry.value * 100).toStringAsFixed(1)}%',
      );
    }

    terminal.writeLine('');
    terminal.writeLine('Per-Analyzer Recall');
    for (final entry in report.analyzerRecall.entries) {
      terminal.writeLine(
        '  ${entry.key.padRight(16)} ${(entry.value * 100).toStringAsFixed(1)}%',
      );
    }

    // Save report
    if (outputPath != null) {
      try {
        final json = report.toJsonString();
        await fileSystem.writeAsStringAsync(outputPath, json);
        terminal.writeLine('');
        terminal.writeLine('Report saved to: $outputPath');
      } catch (e) {
        terminal.writeError('Failed to save report: $e');
        return AppConstants.exitInternalFailure;
      }
    }

    terminal.writeLine('');
    terminal.writeLine('Validation complete.');
    return AppConstants.exitNoIssues;
  }
}
