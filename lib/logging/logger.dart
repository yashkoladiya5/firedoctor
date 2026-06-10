import 'package:firedoctor/terminal/terminal_interface.dart';

final class Logger {
  final Terminal terminal;
  final String? name;

  const Logger({required this.terminal, this.name});

  void info(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeInfo('$prefix $message'.trim());
  }

  void success(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeSuccess('$prefix $message'.trim());
  }

  void warning(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeWarning('$prefix $message'.trim());
  }

  void error(String message) {
    final prefix = name != null ? '[$name]' : '';
    terminal.writeError('$prefix $message'.trim());
  }

  void header(String title) {
    terminal.writeLine('');
    terminal.writeLine('=== $title ===');
    terminal.writeLine('');
  }

  void blank() {
    terminal.writeLine('');
  }
}
