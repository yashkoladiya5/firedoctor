import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/cli/commands/help_command.dart';
import 'package:firedoctor/cli/command_runner.dart';
import 'package:firedoctor/cli/command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class MockTerminal extends Mock implements Terminal {}

class MockFileSystem extends Mock implements FileSystem {}

class MockCommand extends Mock implements Command {}

void main() {
  late MockTerminal terminal;
  late MockFileSystem fileSystem;
  late Logger logger;
  late CommandRunner runner;

  setUp(() {
    terminal = MockTerminal();
    fileSystem = MockFileSystem();
    logger = Logger(terminal: terminal);
    runner = CommandRunner(
        logger: logger, terminal: terminal, fileSystem: fileSystem);
  });

  group('HelpCommand', () {
    group('execute', () {
      test('with no args calls printUsage and returns exitNoIssues', () async {
        when(() => terminal.writeLine(any())).thenReturn(null);

        final cmd =
            HelpCommand(logger: logger, terminal: terminal, runner: runner);
        final exitCode = await cmd.execute([]);

        verify(() => terminal.writeLine(any(that: contains('Usage'))))
            .called(1);
        expect(exitCode, equals(AppConstants.exitNoIssues));
      });

      test('with valid command name shows command help', () async {
        final mockCommand = MockCommand();
        when(() => mockCommand.name).thenReturn('version');
        when(() => mockCommand.description).thenReturn('Shows the version');
        when(() => mockCommand.aliases).thenReturn(['v', '-v']);
        when(() => terminal.writeLine(any())).thenReturn(null);

        runner.register(mockCommand);

        final cmd =
            HelpCommand(logger: logger, terminal: terminal, runner: runner);
        final exitCode = await cmd.execute(['version']);

        verify(() => terminal.writeLine('Command: version')).called(1);
        verify(() => terminal.writeLine('Description: Shows the version'))
            .called(1);
        verify(() => terminal.writeLine('Aliases: v, -v')).called(1);
        expect(exitCode, equals(AppConstants.exitNoIssues));
      });

      test('with command name without aliases omits aliases line', () async {
        final mockCommand = MockCommand();
        when(() => mockCommand.name).thenReturn('simple');
        when(() => mockCommand.description).thenReturn('Simple command');
        when(() => mockCommand.aliases).thenReturn([]);
        when(() => terminal.writeLine(any())).thenReturn(null);

        runner.register(mockCommand);

        final cmd =
            HelpCommand(logger: logger, terminal: terminal, runner: runner);
        final exitCode = await cmd.execute(['simple']);

        verify(() => terminal.writeLine('Command: simple')).called(1);
        verifyNever(() => terminal.writeLine(any(that: startsWith('Aliases'))));
        expect(exitCode, equals(AppConstants.exitNoIssues));
      });

      test('with unknown command name returns exitInternalFailure', () async {
        when(() => terminal.writeError(any())).thenReturn(null);

        final cmd =
            HelpCommand(logger: logger, terminal: terminal, runner: runner);
        final exitCode = await cmd.execute(['unknown']);

        verify(() => terminal.writeError('Unknown command: unknown')).called(1);
        expect(exitCode, equals(AppConstants.exitInternalFailure));
      });
    });
  });
}
