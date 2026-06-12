import 'package:firedoctor/filesystem/file_system_interface.dart';

/// Core class.
class SourceFileCache {
  /// Public property or field.
  final FileSystem fs;
  final Map<String, List<String>> _dartFiles = {};
  final Map<String, String> _dartContent = {};
  final Map<String, String> _dartCleaned = {};
  final Map<String, List<String>> _dartLines = {};
  bool _scanned = false;

  SourceFileCache(this.fs);

  /// Public method or function.
  void scanProject(String projectPath) {
    if (_scanned) return;
    final libPath = fs.join(projectPath, 'lib');
    if (!fs.exists(libPath) || !fs.isDirectory(libPath)) {
      _scanned = true;
      return;
    }
    _dartFiles[projectPath] = _findDartFiles(libPath);
    for (final filePath in _dartFiles[projectPath]!) {
      final content = fs.readAsString(filePath);
      _dartContent[filePath] = content;
      final cleaned = _stripCommentsAndStrings(content);
      _dartCleaned[filePath] = cleaned;
      _dartLines[filePath] = cleaned.split('\n');
    }
    _scanned = true;
  }

  /// Public method or function.
  List<String> getDartFiles(String projectPath) =>
      _dartFiles[projectPath] ?? [];

  String? getContent(String filePath) => _dartContent[filePath];

  String? getCleaned(String filePath) => _dartCleaned[filePath];

  List<String>? getLines(String filePath) => _dartLines[filePath];

  /// Public method or function.
  void reset() {
    _dartFiles.clear();
    _dartContent.clear();
    _dartCleaned.clear();
    _dartLines.clear();
    _scanned = false;
  }

  List<String> _findDartFiles(String dirPath) {
    final files = <String>[];
    if (!fs.exists(dirPath) || !fs.isDirectory(dirPath)) return files;

    for (final entry in fs.listDirectory(dirPath)) {
      if (fs.isDirectory(entry)) {
        files.addAll(_findDartFiles(entry));
      } else if (entry.endsWith('.dart')) {
        files.add(entry);
      }
    }
    return files;
  }

  String _stripCommentsAndStrings(String source) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < source.length) {
      if (i < source.length - 1 && source[i] == '/' && source[i + 1] == '/') {
        buffer.write(' ');
        i++;
        while (i < source.length && source[i] != '\n') {
          buffer.write(' ');
          i++;
        }
        if (i < source.length) {
          buffer.write(source[i]);
          i++;
        }
        continue;
      }
      if (i < source.length - 1 && source[i] == '/' && source[i + 1] == '*') {
        buffer.write('  ');
        i += 2;
        while (i < source.length - 1 &&
            !(source[i] == '*' && source[i + 1] == '/')) {
          buffer.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
        if (i < source.length - 1) {
          buffer.write('  ');
          i += 2;
        }
        continue;
      }
      if (source[i] == '"' || source[i] == "'") {
        final quote = source[i];
        buffer.write(quote);
        i++;
        if (i + 1 < source.length &&
            source[i] == quote &&
            source[i + 1] == quote) {
          buffer.write('$quote$quote');
          i += 2;
          while (i < source.length - 2 &&
              !(source[i] == quote &&
                  source[i + 1] == quote &&
                  source[i + 2] == quote)) {
            buffer.write(source[i] == '\n' ? '\n' : ' ');
            i++;
          }
          if (i < source.length - 2) {
            buffer.write('$quote$quote$quote');
            i += 3;
          }
        } else {
          while (i < source.length && source[i] != quote) {
            if (source[i] == '\\' && i + 1 < source.length) {
              buffer.write('  ');
              i += 2;
            } else {
              buffer.write(source[i] == '\n' ? '\n' : ' ');
              i++;
            }
          }
          if (i < source.length) {
            buffer.write(quote);
            i++;
          }
        }
        continue;
      }
      buffer.write(source[i]);
      i++;
    }
    return buffer.toString();
  }
}