import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:firedoctor/filesystem/file_system_interface.dart';

final class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  bool exists(String path) => File(path).existsSync() || Directory(path).existsSync();

  @override
  String readAsString(String path) => File(path).readAsStringSync();

  @override
  Future<String> readAsStringAsync(String path) => File(path).readAsString();

  @override
  void writeAsString(String path, String content) =>
      File(path).writeAsStringSync(content);

  @override
  Future<void> writeAsStringAsync(String path, String content) =>
      File(path).writeAsString(content);

  @override
  List<String> listDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir.listSync().map((e) => e.path).toList();
  }

  @override
  bool isDirectory(String path) => Directory(path).existsSync();

  @override
  bool isFile(String path) => File(path).existsSync();

  @override
  String get currentDirectory => Directory.current.path;

  @override
  String join(String part1, [String? part2, String? part3]) {
    final parts = [part1, if (part2 != null) part2, if (part3 != null) part3];
    return p.joinAll(parts);
  }

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  Future<void> delete(String path) async {
    if (isDirectory(path)) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  @override
  Future<void> copy(String source, String destination) async {
    await File(source).copy(destination);
  }
}
