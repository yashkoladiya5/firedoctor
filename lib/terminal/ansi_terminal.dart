import 'dart:io';

import 'package:firedoctor/terminal/terminal_interface.dart';

final class AnsiTerminal implements Terminal {
  bool get _supportsAnsi {
    if (Platform.environment.containsKey('NO_COLOR')) return false;
    if (Platform.environment['TERM'] == 'dumb') return false;
    if (!stdout.hasTerminal) return false;
    return stdout.supportsAnsiEscapes;
  }

  @override
  void write(String message) {
    stdout.write(message);
  }

  @override
  void writeLine(String message) {
    stdout.writeln(message);
  }

  @override
  void writeSuccess(String message) {
    if (_supportsAnsi) {
      stdout.writeln('\x1B[32m$message\x1B[0m');
    } else {
      stdout.writeln('[SUCCESS] $message');
    }
  }

  @override
  void writeWarning(String message) {
    if (_supportsAnsi) {
      stdout.writeln('\x1B[33m$message\x1B[0m');
    } else {
      stdout.writeln('[WARN] $message');
    }
  }

  @override
  void writeError(String message) {
    if (_supportsAnsi) {
      stderr.writeln('\x1B[31m$message\x1B[0m');
    } else {
      stderr.writeln('ERROR: $message');
    }
  }

  @override
  void writeInfo(String message) {
    if (_supportsAnsi) {
      stdout.writeln('\x1B[34m$message\x1B[0m');
    } else {
      stdout.writeln('[INFO] $message');
    }
  }

  @override
  String? readLine() => stdin.readLineSync();

  @override
  void clear() {
    if (_supportsAnsi) {
      stdout.write('\x1B[2J\x1B[0;0H');
    }
  }
}
