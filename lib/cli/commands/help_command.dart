import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/cli/command_runner.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

final class HelpCommand extends Command {
  @override
  String get name => 'help';
  @override
  String get description => 'Shows help information for commands';
  @override
  List<String> get aliases => ['h', '-h', '--help'];

  final Logger logger;
  final Terminal terminal;
  final CommandRunner _runner;

  HelpCommand({
    required this.logger,
    required this.terminal,
    required CommandRunner runner,
  }) : _runner = runner;

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      _runner.printUsage();
      return AppConstants.exitNoIssues;
    }

    final command = _runner.findCommand(args.first);
    if (command == null) {
      terminal.writeError('Unknown command: ${args.first}');
      return AppConstants.exitInternalFailure;
    }

    terminal.writeLine('');
    terminal.writeLine('Command: ${command.name}');
    terminal.writeLine('Description: ${command.description}');
    if (command.aliases.isNotEmpty) {
      terminal.writeLine('Aliases: ${command.aliases.join(", ")}');
    }
    terminal.writeLine('');
    return AppConstants.exitNoIssues;
  }
}
