import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class DiagnoseCommand extends Command {
  @override
  String get name => 'diagnose';
  @override
  String get description => 'Run Firebase diagnostics on the project';

  final Logger logger;
  final Terminal terminal;
  final FileSystem fileSystem;

  DiagnoseCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
  });

  @override
  Future<int> execute(List<String> args) async {
    terminal.writeInfo('Firebase diagnostics coming in Phase 2.');
    return AppConstants.exitSuccess;
  }
}
