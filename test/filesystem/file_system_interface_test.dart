import 'package:test/test.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class FakeFileSystem implements FileSystem {
  final Map<String, String> _files = {};
  final Set<String> _directories = {};
  final String _currentDirectory = '/test';

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
  String get currentDirectory => _currentDirectory;

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
  Future<void> copy(String source, String destination) async {
    if (_files.containsKey(source)) {
      _files[destination] = _files[source]!;
    } else if (_directories.contains(source)) {
      _directories.add(destination);
    }
  }

  @override
  Future<void> delete(String path) async {
    _files.remove(path);
    _directories.remove(path);
    _files.keys
        .where((k) => k.startsWith('$path/'))
        .toList()
        .forEach(_files.remove);
    _directories
        .where((d) => d.startsWith('$path/'))
        .toList()
        .forEach(_directories.remove);
  }
}

void main() {
  late FakeFileSystem fs;

  setUp(() {
    fs = FakeFileSystem();
  });

  group('FakeFileSystem (FileSystem interface implementation)', () {
    group('exists', () {
      test('returns true for added files', () {
        fs.addFile('/test/file.txt', 'content');
        expect(fs.exists('/test/file.txt'), isTrue);
      });

      test('returns true for added directories', () {
        fs.addDirectory('/test/subdir');
        expect(fs.exists('/test/subdir'), isTrue);
      });

      test('returns false for non-existent paths', () {
        expect(fs.exists('/nonexistent'), isFalse);
      });
    });

    group('readAsString', () {
      test('returns content of added file', () {
        fs.addFile('/test/file.txt', 'hello world');
        expect(fs.readAsString('/test/file.txt'), equals('hello world'));
      });

      test('throws for non-existent file', () {
        expect(() => fs.readAsString('/nonexistent'), throwsException);
      });
    });

    group('readAsStringAsync', () {
      test('returns content of added file', () async {
        fs.addFile('/test/file.txt', 'async content');
        final result = await fs.readAsStringAsync('/test/file.txt');
        expect(result, equals('async content'));
      });
    });

    group('writeAsString', () {
      test('stores file content', () {
        fs.writeAsString('/test/new.txt', 'new content');
        expect(fs.readAsString('/test/new.txt'), equals('new content'));
      });

      test('overwrites existing file', () {
        fs.writeAsString('/test/file.txt', 'original');
        fs.writeAsString('/test/file.txt', 'updated');
        expect(fs.readAsString('/test/file.txt'), equals('updated'));
      });
    });

    group('writeAsStringAsync', () {
      test('stores file content asynchronously', () async {
        await fs.writeAsStringAsync('/test/async.txt', 'async');
        expect(fs.readAsString('/test/async.txt'), equals('async'));
      });
    });

    group('listDirectory', () {
      test('lists files in directory', () {
        fs.addFile('/test/a.txt', 'a');
        fs.addFile('/test/b.txt', 'b');
        final entries = fs.listDirectory('/test');
        expect(entries, contains('/test/a.txt'));
        expect(entries, contains('/test/b.txt'));
      });

      test('returns empty for non-existent directory', () {
        expect(fs.listDirectory('/nonexistent'), isEmpty);
      });
    });

    group('isDirectory', () {
      test('returns true for added directories', () {
        fs.addDirectory('/test/sub');
        expect(fs.isDirectory('/test/sub'), isTrue);
      });

      test('returns false for files', () {
        fs.addFile('/test/file.txt', 'content');
        expect(fs.isDirectory('/test/file.txt'), isFalse);
      });
    });

    group('isFile', () {
      test('returns true for added files', () {
        fs.addFile('/test/file.txt', 'content');
        expect(fs.isFile('/test/file.txt'), isTrue);
      });

      test('returns false for directories', () {
        fs.addDirectory('/test/sub');
        expect(fs.isFile('/test/sub'), isFalse);
      });
    });

    group('currentDirectory', () {
      test('returns the current directory', () {
        expect(fs.currentDirectory, equals('/test'));
      });
    });

    group('join', () {
      test('joins two parts', () {
        expect(fs.join('/base', 'sub'), equals('/base/sub'));
      });

      test('joins three parts', () {
        expect(fs.join('/base', 'mid', 'file'), equals('/base/mid/file'));
      });

      test('joins single part', () {
        expect(fs.join('/base'), equals('/base'));
      });
    });
  });
}
