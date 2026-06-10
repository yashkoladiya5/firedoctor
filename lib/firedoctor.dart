import 'dart:io';
import 'package:firedoctor/cli/cli.dart';
import 'package:firedoctor/logging/logging.dart';
import 'package:firedoctor/terminal/terminal.dart';
import 'package:firedoctor/filesystem/filesystem.dart';
import 'package:firedoctor/analyzers/dependency/dependency_analyzer.dart';
import 'package:firedoctor/analyzers/firebase_core/firebase_core_analyzer.dart';
import 'package:firedoctor/analyzers/project/project_analyzer.dart';
import 'package:firedoctor/services/analyzer_service.dart';

export 'package:firedoctor/models/models.dart';
export 'package:firedoctor/constants/constants.dart';
export 'package:firedoctor/exceptions/exceptions.dart';
export 'package:firedoctor/utils/utils.dart';
export 'package:firedoctor/cli/cli.dart';
export 'package:firedoctor/logging/logging.dart';
export 'package:firedoctor/terminal/terminal.dart';
export 'package:firedoctor/filesystem/filesystem.dart';
export 'package:firedoctor/analyzers/analyzers.dart';
export 'package:firedoctor/services/services.dart';

Future<void> runFireDoctor(List<String> args) async {
  final terminal = AnsiTerminal();
  const fileSystem = LocalFileSystem();
  final logger = Logger(terminal: terminal, name: 'firedoctor');

  final runner = CommandRunner(
    logger: logger,
    terminal: terminal,
    fileSystem: fileSystem,
  );

  runner.registerAll([
    HelpCommand(logger: logger, terminal: terminal, runner: runner),
    VersionCommand(logger: logger, terminal: terminal),
    DiagnoseCommand(logger: logger, terminal: terminal, fileSystem: fileSystem),
    DoctorCommand(logger: logger, terminal: terminal, fileSystem: fileSystem),
    ReportCommand(logger: logger, terminal: terminal, fileSystem: fileSystem),
  ]);

  // Initialize analyzers for future use
  final analyzerService = AnalyzerService(logger: logger);
  analyzerService.register(ProjectAnalyzer());
  analyzerService.register(DependencyAnalyzer());
  analyzerService.register(FirebaseCoreAnalyzer());

  final exitCode = await runner.run(args);
  exit(exitCode);
}
