import 'dart:io';
import 'package:firedoctor/firedoctor.dart';

Future<void> main(List<String> args) async {
  final terminal = AnsiTerminal();
  const fileSystem = LocalFileSystem();
  final logger = Logger(terminal: terminal, name: 'validate');

  terminal.writeLine('FireDoctor Validation Runner');
  terminal.writeLine('═══════════════════════════');
  terminal.writeLine('');

  final analyzerService = AnalyzerService(logger: logger);
  analyzerService.register(ProjectAnalyzer());
  analyzerService.register(DependencyAnalyzer());
  analyzerService.register(FirebaseCoreAnalyzer());
  analyzerService.register(AndroidAnalyzer());
  analyzerService.register(IOSAnalyzer());
  analyzerService.register(FCMAnalyzer());
  analyzerService.register(CrashlyticsAnalyzer());

  final projectsDir = fileSystem.join(
    fileSystem.currentDirectory,
    'validation',
    'projects',
  );

  if (!fileSystem.exists(projectsDir)) {
    stderr.writeln('Validation projects directory not found: $projectsDir');
    exit(1);
  }

  final runner = ValidationRunner(
    analyzerService: analyzerService,
    fileSystem: fileSystem,
    logger: logger,
  );

  try {
    final report = await runner.runAll(projectsDir: projectsDir);

    terminal.writeLine('');
    terminal.writeLine('Overall Results');
    terminal.writeLine('───────────────');
    terminal.writeLine(
      '  Accuracy:  ${(report.overallAccuracy * 100).toStringAsFixed(1)}%',
    );
    terminal.writeLine(
      '  Precision: ${(report.overallPrecision * 100).toStringAsFixed(1)}%',
    );
    terminal.writeLine(
      '  Recall:    ${(report.overallRecall * 100).toStringAsFixed(1)}%',
    );
    terminal.writeLine(
      '  TP: ${report.totalTruePositives}  FP: ${report.totalFalsePositives}  FN: ${report.totalFalseNegatives}',
    );

    // Save report
    final outputPath = fileSystem.join(
      fileSystem.currentDirectory,
      'validation',
      'validation_report.json',
    );
    await runner.saveReport(report, outputPath);
    terminal.writeLine('');
    terminal.writeLine('Report saved to: validation/validation_report.json');

    terminal.writeLine('');
    terminal.writeLine('Validation complete.');
  } catch (e) {
    stderr.writeln('Validation failed: $e');
    exit(1);
  }
}
