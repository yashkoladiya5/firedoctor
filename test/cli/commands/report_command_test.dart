import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/cli/commands/report_command.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class MockTerminal extends Mock implements Terminal {}
class MockFileSystem extends Mock implements FileSystem {}

void main() {
  group('ReportCommand', () {
    test('execute prints coming soon message and returns exitSuccess', () async {
      final terminal = MockTerminal();
      final fileSystem = MockFileSystem();
      final logger = Logger(terminal: terminal);
      when(() => terminal.writeInfo(any())).thenReturn(null);

      final cmd = ReportCommand(logger: logger, terminal: terminal, fileSystem: fileSystem);
      final exitCode = await cmd.execute([]);

      verify(() => terminal.writeInfo('Report generation coming soon.')).called(1);
      expect(exitCode, equals(AppConstants.exitSuccess));
    });
  });
}
