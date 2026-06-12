import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:firedoctor/filesystem/file_system_interface.dart';

/// Core class.
final class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  /// Public method or function.
  bool exists(String path) =>
      File(path).existsSync() || Directory(path).existsSync();

  @override
  /// Public method or function.
  String readAsString(String path) => File(path).readAsStringSync();

  @override
  /// Public method or function.
  Future<String> readAsStringAsync(String path) => File(path).readAsString();

  @override
  /// Public method or function.
  void writeAsString(String path, String content) =>
      File(path).writeAsStringSync(content);

  @override
  /// Public method or function.
  Future<void> writeAsStringAsync(String path, String content) =>
      File(path).writeAsString(content);

  @override
  /// Public method or function.
  List<String> listDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir.listSync().map((e) => e.path).toList();
  }

  @override
  /// Public method or function.
  bool isDirectory(String path) => Directory(path).existsSync();

  @override
  /// Public method or function.
  bool isFile(String path) => File(path).existsSync();

  @override
  String get currentDirectory => Directory.current.path;

  @override
  /// Public method or function.
  String join(String part1, [String? part2, String? part3]) {
    final parts = [part1, if (part2 != null) part2, if (part3 != null) part3];
    return p.joinAll(parts);
  }

  @override
  /// Public method or function.
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  /// Public method or function.
  Future<void> delete(String path) async {
    if (isDirectory(path)) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  @override
  /// Public method or function.
  Future<void> copy(String source, String destination) async {
    await File(source).copy(destination);
  }
}