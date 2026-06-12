import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:firedoctor/terminal/ansi_terminal.dart';

class _CaptureStdout implements Stdout {
  final StringBuffer buffer = StringBuffer();

  @override
  void write(Object? object) => buffer.write(object?.toString() ?? '');

  @override
  void writeln([Object? object = ""]) => buffer.writeln(object.toString());

  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) =>
      buffer.writeAll(objects, separator);

  @override
  void add(List<int> data) => buffer.write(utf8.decode(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}

  @override
  Future<dynamic> get done => Future.value();

  @override
  bool get hasTerminal => _ansiSupported;

  @override
  bool get supportsAnsiEscapes => _ansiSupported;

  @override
  int get terminalColumns => 80;

  @override
  int get terminalLines => 24;

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding encoding) {}

  @override
  IOSink get nonBlocking => this;

  @override
  String get lineTerminator => '\n';

  @override
  set lineTerminator(String lt) {}

  bool _ansiSupported = false;

  void setAnsiSupported(bool supported) {
    _ansiSupported = supported;
  }
}

void main() {
  group('AnsiTerminal (with ANSI support)', () {
    test('writeSuccess uses green ANSI codes', () async {
      final captureStdout = _CaptureStdout()..setAnsiSupported(true);
      final captureStderr = _CaptureStdout()..setAnsiSupported(true);

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeSuccess('done');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('\x1B[32mdone\x1B[0m\n'));
    });

    test('writeWarning uses yellow ANSI codes', () async {
      final captureStdout = _CaptureStdout()..setAnsiSupported(true);
      final captureStderr = _CaptureStdout()..setAnsiSupported(true);

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeWarning('caution');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('\x1B[33mcaution\x1B[0m\n'));
    });

    test('writeError uses red ANSI codes to stderr', () async {
      final captureStdout = _CaptureStdout()..setAnsiSupported(true);
      final captureStderr = _CaptureStdout()..setAnsiSupported(true);

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeError('fail');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStderr.buffer.toString(), equals('\x1B[31mfail\x1B[0m\n'));
    });

    test('writeInfo uses blue ANSI codes', () async {
      final captureStdout = _CaptureStdout()..setAnsiSupported(true);
      final captureStderr = _CaptureStdout()..setAnsiSupported(true);

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeInfo('note');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('\x1B[34mnote\x1B[0m\n'));
    });

    test('clear writes ANSI escape codes', () async {
      final captureStdout = _CaptureStdout()..setAnsiSupported(true);
      final captureStderr = _CaptureStdout()..setAnsiSupported(true);

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.clear();
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(),
          equals('\x1B[2J\x1B[0;0H'));
    });
  });

  group('AnsiTerminal (without ANSI support)', () {
    test('writes to stdout', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.write('hello');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('hello'));
    });

    test('writeLine appends newline', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeLine('hello');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('hello\n'));
    });

    test('writeSuccess uses fallback prefix', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeSuccess('done');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('[SUCCESS] done\n'));
    });

    test('writeWarning uses fallback prefix', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeWarning('caution');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('[WARN] caution\n'));
    });

    test('writeError uses fallback prefix to stderr', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeError('fail');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStderr.buffer.toString(), equals('ERROR: fail\n'));
    });

    test('writeInfo uses fallback prefix', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeInfo('note');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('[INFO] note\n'));
    });

    test('clear does nothing when ANSI not supported', () async {
      final captureStdout = _CaptureStdout();
      final captureStderr = _CaptureStdout();

      await IOOverrides.runZoned(() {
        final terminal = AnsiTerminal();
        terminal.writeLine('before');
        terminal.clear();
        terminal.writeLine('after');
      }, stdout: () => captureStdout, stderr: () => captureStderr);

      expect(captureStdout.buffer.toString(), equals('before\nafter\n'));
    });
  });
}
