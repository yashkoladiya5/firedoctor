import 'package:firedoctor/terminal/terminal_interface.dart';

/// Core class.
final class Logger {
  /// Public property or field.
  final Terminal terminal;
  /// Public property or field.
  final String? name;

  const Logger({required this.terminal, this.name});

  /// Public method or function.
  void info(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeInfo('$prefix $message'.trim());
  }

  /// Public method or function.
  void success(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeSuccess('$prefix $message'.trim());
  }

  /// Public method or function.
  void warning(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeWarning('$prefix $message'.trim());
  }

  /// Public method or function.
  void error(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeError('$prefix $message'.trim());
  }

  /// Public method or function.
  void header(String title) {
    terminal.writeLine('');
    terminal.writeLine('=== $title ===');
    terminal.writeLine('');
  }

  /// Public method or function.
  void blank() {
    terminal.writeLine('');
  }
}