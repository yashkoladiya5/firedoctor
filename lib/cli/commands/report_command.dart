import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class ReportCommand extends Command {
  @override
  String get name => 'report';
  @override
  String get description => 'Generate a diagnostic report for the project';

  final Logger logger;
  final Terminal terminal;
  final FileSystem fileSystem;

  ReportCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
  });

  @override
  Future<int> execute(List<String> args) async {
    terminal.writeInfo('Report generation coming soon.');
    return AppConstants.exitSuccess;
  }
}
