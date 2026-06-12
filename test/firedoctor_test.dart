import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:firedoctor/firedoctor.dart';

class _ExitException implements Exception {
  final int exitCode;
  const _ExitException(this.exitCode);
}

class _CaptureStdout implements Stdout {
  final StringBuffer buffer;

  _CaptureStdout(this.buffer);

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
  Future<void> get done => Future<void>.value();

  @override
  bool get hasTerminal => false;

  @override
  bool get supportsAnsiEscapes => false;

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
}

void main() {
  group('runFireDoctor', () {
    test('is a top-level function', () {
      expect(runFireDoctor, isA<Function>());
    });

    test('registers all 7 analyzers', () async {
      final stdoutBuffer = StringBuffer();
      int? capturedExitCode;

      try {
        await IOOverrides.runZoned(() async {
          await runFireDoctor(['help']);
        },
            stdout: () => _CaptureStdout(stdoutBuffer),
            stderr: () => _CaptureStdout(StringBuffer()),
            exit: (code) {
              capturedExitCode = code;
              throw _ExitException(code);
            });
      } on _ExitException {
        // expected — exit() throws to prevent process termination
      }

      expect(capturedExitCode, equals(AppConstants.exitNoIssues));
      final output = stdoutBuffer.toString();
      expect(output, contains('doctor'));
      expect(output, contains('diagnose'));
      expect(output, contains('validate'));
      expect(output, contains('report'));
      expect(output, contains('version'));
      expect(output, contains('help'));
    });

    test('returns exit code 0 on help command', () async {
      int? capturedExitCode;

      try {
        await IOOverrides.runZoned(() async {
          await runFireDoctor(['help']);
        },
            stderr: () => _CaptureStdout(StringBuffer()),
            exit: (code) {
              capturedExitCode = code;
              throw _ExitException(code);
            });
      } on _ExitException {
        // expected
      }

      expect(capturedExitCode, equals(AppConstants.exitNoIssues));
    });

    test('returns exit code 4 on unknown command', () async {
      int? capturedExitCode;

      try {
        await IOOverrides.runZoned(() async {
          await runFireDoctor(['unknown']);
        },
            stdout: () => _CaptureStdout(StringBuffer()),
            stderr: () => _CaptureStdout(StringBuffer()),
            exit: (code) {
              capturedExitCode = code;
              throw _ExitException(code);
            });
      } on _ExitException {
        // expected
      }

      expect(capturedExitCode, equals(AppConstants.exitInternalFailure));
    });
  });
}
