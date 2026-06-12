import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

/// Core class.
final class CommandRunner {
  /// Public property or field.
  final Logger logger;
  /// Public property or field.
  final Terminal terminal;
  /// Public property or field.
  final FileSystem fileSystem;
  final List<Command> _commands = [];

  CommandRunner({
    required this.logger,
    required this.terminal,
    required this.fileSystem,
  });

  /// Public method or function.
  void register(Command command) {
    _commands.add(command);
  }

  /// Public method or function.
  void registerAll(List<Command> commands) {
    _commands.addAll(commands);
  }

  Command? findCommand(String name) {
    return _commands
        .where((c) => c.name == name || c.aliases.contains(name))
        .firstOrNull;
  }

  /// Public method or function.
  Future<int> run(List<String> args) async {
    if (args.isEmpty) {
      printUsage();
      return AppConstants.exitNoIssues;
    }

    final commandName = args.first;
    final commandArgs = args.skip(1).toList();

    if (commandName == 'help') {
      final helpCmd = findCommand('help');
      if (helpCmd != null) {
        return helpCmd.execute(commandArgs);
      }
    }

    final command = findCommand(commandName);
    if (command == null) {
      terminal.writeError('Unknown command: $commandName\n');
      printUsage();
      return AppConstants.exitInternalFailure;
    }

    return command.execute(commandArgs);
  }

  /// Public method or function.
  void printUsage() {
    terminal.writeLine('FireDoctor v${AppConstants.version}');
    terminal.writeLine(AppConstants.description);
    terminal.writeLine('');
    terminal.writeLine('Usage: firedoctor <command> [arguments]');
    terminal.writeLine('');
    terminal.writeLine('Commands:');
    for (final cmd in _commands) {
      final aliases = cmd.aliases.isEmpty ? '' : ' (${cmd.aliases.join(", ")})';
      terminal.writeLine(
        '  ${cmd.name.padRight(16)}$aliases  ${cmd.description}',
      );
    }
    terminal.writeLine('');
    terminal.writeLine('Run "firedoctor help <command>" for more info.');
  }
}