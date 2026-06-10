import 'package:test/test.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

class FakeTerminal implements Terminal {
  final buffer = StringBuffer();

  @override
  void write(String message) => buffer.write(message);

  @override
  void writeLine(String message) => buffer.writeln(message);

  @override
  void writeSuccess(String message) => buffer.writeln('[SUCCESS] $message');

  @override
  void writeWarning(String message) => buffer.writeln('[WARN] $message');

  @override
  void writeError(String message) => buffer.writeln('[ERROR] $message');

  @override
  void writeInfo(String message) => buffer.writeln('[INFO] $message');

  @override
  String? readLine() => null;

  @override
  void clear() => buffer.clear();
}

void main() {
  late FakeTerminal terminal;

  setUp(() {
    terminal = FakeTerminal();
  });

  group('FakeTerminal (Terminal interface implementation)', () {
    group('write', () {
      test('writes without newline', () {
        terminal.write('hello');
        expect(terminal.buffer.toString(), equals('hello'));
      });

      test('appends to buffer', () {
        terminal.write('hello ');
        terminal.write('world');
        expect(terminal.buffer.toString(), equals('hello world'));
      });
    });

    group('writeLine', () {
      test('writes with newline', () {
        terminal.writeLine('hello');
        expect(terminal.buffer.toString(), equals('hello\n'));
      });
    });

    group('writeSuccess', () {
      test('writes with success prefix', () {
        terminal.writeSuccess('done');
        expect(terminal.buffer.toString(), equals('[SUCCESS] done\n'));
      });
    });

    group('writeWarning', () {
      test('writes with warning prefix', () {
        terminal.writeWarning('caution');
        expect(terminal.buffer.toString(), equals('[WARN] caution\n'));
      });
    });

    group('writeError', () {
      test('writes with error prefix', () {
        terminal.writeError('fail');
        expect(terminal.buffer.toString(), equals('[ERROR] fail\n'));
      });
    });

    group('writeInfo', () {
      test('writes with info prefix', () {
        terminal.writeInfo('note');
        expect(terminal.buffer.toString(), equals('[INFO] note\n'));
      });
    });

    group('readLine', () {
      test('returns null', () {
        expect(terminal.readLine(), isNull);
      });
    });

    group('clear', () {
      test('clears the buffer', () {
        terminal.writeLine('something');
        expect(terminal.buffer.toString(), isNotEmpty);
        terminal.clear();
        expect(terminal.buffer.toString(), isEmpty);
      });
    });
  });
}
