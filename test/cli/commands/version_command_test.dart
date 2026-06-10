import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/cli/commands/version_command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

class MockTerminal extends Mock implements Terminal {}

void main() {
  group('VersionCommand', () {
    test('execute prints version string and returns exitSuccess', () async {
      final terminal = MockTerminal();
      final logger = Logger(terminal: terminal);
      when(() => terminal.writeLine(any())).thenReturn(null);

      final cmd = VersionCommand(logger: logger, terminal: terminal);
      final exitCode = await cmd.execute([]);

      verify(() => terminal.writeLine('FireDoctor v${AppConstants.version}'))
          .called(1);
      expect(exitCode, equals(AppConstants.exitSuccess));
    });
  });
}
