import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class VersionCommand extends Command {
  @override
  String get name => 'version';
  @override
  String get description => 'Shows the FireDoctor version';
  @override
  List<String> get aliases => ['v', '-v', '--version'];

  final Logger logger;
  final Terminal terminal;

  VersionCommand({required this.logger, required this.terminal});

  @override
  Future<int> execute(List<String> args) async {
    terminal.writeLine('FireDoctor v${AppConstants.version}');
    return AppConstants.exitSuccess;
  }
}
