import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
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
      logger: logger,
      terminal: terminal,
      fileSystem: fileSystem,
    );
  });

  group('CommandRunner', () {
    group('register', () {
      test('adds a command', () {
        final command = MockCommand();
        when(() => command.name).thenReturn('test');
        when(() => command.aliases).thenReturn([]);
        runner.register(command);
        expect(runner.findCommand('test'), equals(command));
      });
    });

    group('registerAll', () {
      test('adds multiple commands', () {
        final cmd1 = MockCommand();
        final cmd2 = MockCommand();
        when(() => cmd1.name).thenReturn('cmd1');
        when(() => cmd1.aliases).thenReturn([]);
        when(() => cmd2.name).thenReturn('cmd2');
        when(() => cmd2.aliases).thenReturn([]);
        runner.registerAll([cmd1, cmd2]);
        expect(runner.findCommand('cmd1'), equals(cmd1));
        expect(runner.findCommand('cmd2'), equals(cmd2));
      });
    });

    group('findCommand', () {
      test('returns null for unknown command', () {
        expect(runner.findCommand('unknown'), isNull);
      });

      test('finds by name', () {
        final command = MockCommand();
        when(() => command.name).thenReturn('test');
        when(() => command.aliases).thenReturn([]);
        runner.register(command);
        expect(runner.findCommand('test'), equals(command));
      });

      test('finds by alias', () {
        final command = MockCommand();
        when(() => command.name).thenReturn('test');
        when(() => command.aliases).thenReturn(['t', '--test']);
        runner.register(command);
        expect(runner.findCommand('t'), equals(command));
        expect(runner.findCommand('--test'), equals(command));
      });
    });

    group('run', () {
      test('with no args calls printUsage and returns exitNoIssues', () async {
        when(() => terminal.writeLine(any())).thenReturn(null);
        final exitCode = await runner.run([]);
        verify(
          () => terminal.writeLine(any(that: contains('Usage'))),
        ).called(1);
        expect(exitCode, equals(AppConstants.exitNoIssues));
      });

      test('with unknown command returns exitInternalFailure', () async {
        when(() => terminal.writeError(any())).thenReturn(null);
        when(() => terminal.writeLine(any())).thenReturn(null);
        final exitCode = await runner.run(['unknown']);
        expect(exitCode, equals(AppConstants.exitInternalFailure));
      });

      test('with known command executes it', () async {
        final command = MockCommand();
        when(() => command.name).thenReturn('testcmd');
        when(() => command.aliases).thenReturn([]);
        when(
          () => command.execute(any()),
        ).thenAnswer((_) async => AppConstants.exitNoIssues);
        when(() => terminal.writeLine(any())).thenReturn(null);

        runner.register(command);
        final exitCode = await runner.run(['testcmd']);
        expect(exitCode, equals(AppConstants.exitNoIssues));
        verify(() => command.execute([])).called(1);
      });
    });
  });
}
