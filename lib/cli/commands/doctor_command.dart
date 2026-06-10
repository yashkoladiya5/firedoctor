import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class DoctorCommand extends Command {
  @override
  String get name => 'doctor';
  @override
  String get description => 'Run all FireDoctor checks and generate analysis';

  final Logger logger;
  final Terminal terminal;
  final FileSystem fileSystem;

  DoctorCommand({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
  });

  @override
  Future<int> execute(List<String> args) async {
    terminal.writeInfo('FireDoctor analysis coming soon.');
    return AppConstants.exitSuccess;
  }
}
