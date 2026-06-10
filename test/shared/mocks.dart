import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';
import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/services/analyzer_service.dart';

class MockTerminal extends Mock implements Terminal {}

class MockFileSystem extends Mock implements FileSystem {}

class MockAnalyzer extends Mock implements Analyzer {}

class MockAnalyzerService extends Mock implements AnalyzerService {}

class FakeTerminal implements Terminal {
  final buffer = StringBuffer();

  @override
  void write(String m) => buffer.write(m);

  @override
  void writeLine(String m) => buffer.writeln(m);

  @override
  void writeSuccess(String m) => buffer.writeln('[SUCCESS] $m');

  @override
  void writeWarning(String m) => buffer.writeln('[WARN] $m');

  @override
  void writeError(String m) => buffer.writeln('[ERROR] $m');

  @override
  void writeInfo(String m) => buffer.writeln('[INFO] $m');

  @override
  String? readLine() => null;

  @override
  void clear() => buffer.clear();
}

class FakeFileSystem implements FileSystem {
  final Map<String, String> _files = {};
  final Set<String> _directories = {};

  void addFile(String path, String content) {
    _files[path] = content;
    final parts = path.split('/');
    for (var i = 1; i < parts.length; i++) {
      _directories.add(parts.take(i).join('/'));
    }
  }

  void addDirectory(String path) {
    _directories.add(path);
  }

  @override
  bool exists(String path) =>
      _files.containsKey(path) || _directories.contains(path);

  @override
  String readAsString(String path) =>
      _files[path] ?? (throw Exception('File not found: $path'));

  @override
  Future<String> readAsStringAsync(String path) async =>
      _files[path] ?? (throw Exception('File not found: $path'));

  @override
  void writeAsString(String path, String content) {
    _files[path] = content;
  }

  @override
  Future<void> writeAsStringAsync(String path, String content) async {
    _files[path] = content;
  }

  @override
  List<String> listDirectory(String path) {
    if (!_directories.contains(path)) return [];
    return _files.keys
        .where((f) =>
            f.startsWith('$path/') && f.indexOf('/', path.length + 1) == -1)
        .toList()
      ..sort();
  }

  @override
  bool isDirectory(String path) => _directories.contains(path);

  @override
  bool isFile(String path) => _files.containsKey(path);

  @override
  String get currentDirectory => '/test';

  @override
  String join(String part1, [String? part2, String? part3]) {
    final parts = [part1, if (part2 != null) part2, if (part3 != null) part3];
    return parts.join('/');
  }

  @override
  Future<void> createDirectory(String path) async {
    _directories.add(path);
  }

  @override
  Future<void> delete(String path) async {
    _files.remove(path);
    _directories.remove(path);
  }

  @override
  Future<void> copy(String source, String destination) async {
    if (_files.containsKey(source)) {
      _files[destination] = _files[source]!;
    }
  }
}
