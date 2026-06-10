import 'dart:io';
import 'package:test/test.dart';
import 'package:firedoctor/filesystem/local_file_system.dart';

void main() {
  late LocalFileSystem fs;
  late Directory tempDir;

  setUp(() {
    fs = const LocalFileSystem();
    tempDir = Directory.systemTemp.createTempSync('firedoctor_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('LocalFileSystem', () {
    group('exists', () {
      test('returns true for existing file', () {
        final file = File('${tempDir.path}/test.txt');
        file.writeAsStringSync('content');
        expect(fs.exists(file.path), isTrue);
      });

      test('returns false for non-existent path', () {
        expect(fs.exists('${tempDir.path}/nonexistent.txt'), isFalse);
      });
    });

    group('readAsString', () {
      test('reads file content', () {
        final file = File('${tempDir.path}/read_test.txt');
        file.writeAsStringSync('hello world');
        expect(fs.readAsString(file.path), equals('hello world'));
      });
    });

    group('readAsStringAsync', () {
      test('reads file content asynchronously', () async {
        final file = File('${tempDir.path}/async_read_test.txt');
        await file.writeAsString('async content');
        final result = await fs.readAsStringAsync(file.path);
        expect(result, equals('async content'));
      });
    });

    group('writeAsString', () {
      test('writes content to file', () {
        final path = '${tempDir.path}/write_test.txt';
        fs.writeAsString(path, 'written content');
        expect(File(path).readAsStringSync(), equals('written content'));
      });
    });

    group('writeAsStringAsync', () {
      test('writes content asynchronously', () async {
        final path = '${tempDir.path}/async_write_test.txt';
        await fs.writeAsStringAsync(path, 'async written');
        expect(await File(path).readAsString(), equals('async written'));
      });
    });

    group('listDirectory', () {
      test('lists entries in directory', () {
        File('${tempDir.path}/a.txt').writeAsStringSync('a');
        File('${tempDir.path}/b.txt').writeAsStringSync('b');
        final entries = fs.listDirectory(tempDir.path);
        expect(entries, contains('${tempDir.path}/a.txt'));
        expect(entries, contains('${tempDir.path}/b.txt'));
      });

      test('returns empty for non-existent directory', () {
        expect(fs.listDirectory('${tempDir.path}/nonexistent'), isEmpty);
      });
    });

    group('isDirectory', () {
      test('returns true for directory', () {
        expect(fs.isDirectory(tempDir.path), isTrue);
      });

      test('returns false for file', () {
        final file = File('${tempDir.path}/file.txt');
        file.writeAsStringSync('content');
        expect(fs.isDirectory(file.path), isFalse);
      });
    });

    group('isFile', () {
      test('returns true for file', () {
        final file = File('${tempDir.path}/file.txt');
        file.writeAsStringSync('content');
        expect(fs.isFile(file.path), isTrue);
      });

      test('returns false for directory', () {
        expect(fs.isFile(tempDir.path), isFalse);
      });
    });

    group('currentDirectory', () {
      test('returns non-null current directory', () {
        expect(fs.currentDirectory, isNotEmpty);
      });
    });

    group('join', () {
      test('joins two path parts', () {
        expect(fs.join('/base', 'sub'), equals('/base/sub'));
      });

      test('joins three path parts', () {
        expect(fs.join('/base', 'mid', 'file'), equals('/base/mid/file'));
      });
    });
  });
}
