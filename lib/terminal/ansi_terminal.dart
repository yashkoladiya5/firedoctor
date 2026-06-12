import 'dart:io';

import 'package:firedoctor/terminal/terminal_interface.dart';

/// Core class.
final class AnsiTerminal implements Terminal {
  bool get _supportsAnsi {
    if (Platform.environment.containsKey('NO_COLOR')) return false;
    if (Platform.environment['TERM'] == 'dumb') return false;
    if (!stdout.hasTerminal) return false;
    return stdout.supportsAnsiEscapes;
  }

  @override
  /// Public method or function.
  void write(String message) {
    stdout.write(message);
  }

  @override
  /// Public method or function.
  void writeLine(String message) {
    stdout.writeln(message);
  }

  @override
  /// Public method or function.
  void writeSuccess(String message) {
    if (_supportsAnsi) {
      stdout.writeln('\x1B[32m$message\x1B[0m');
    } else {
      stdout.writeln('[SUCCESS] $message');
    }
  }

  @override
  /// Public method or function.
  void writeWarning(String message) {
    if (_supportsAnsi) {
      stdout.writeln('\x1B[33m$message\x1B[0m');
    } else {
      stdout.writeln('[WARN] $message');
    }
  }

  @override
  /// Public method or function.
  void writeError(String message) {
    if (_supportsAnsi) {
      stderr.writeln('\x1B[31m$message\x1B[0m');
    } else {
      stderr.writeln('ERROR: $message');
    }
  }

  @override
  /// Public method or function.
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
  /// Public method or function.
  void clear() {
    if (_supportsAnsi) {
      stdout.write('\x1B[2J\x1B[0;0H');
    }
  }
}