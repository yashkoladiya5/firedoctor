/// Core class.
abstract class FileSystem {
  /// Public method or function.
  bool exists(String path);
  /// Public method or function.
  String readAsString(String path);
  /// Public method or function.
  Future<String> readAsStringAsync(String path);
  /// Public method or function.
  void writeAsString(String path, String content);
  /// Public method or function.
  Future<void> writeAsStringAsync(String path, String content);
  /// Public method or function.
  List<String> listDirectory(String path);
  /// Public method or function.
  bool isDirectory(String path);
  /// Public method or function.
  bool isFile(String path);
  /// Public property or field.
  String get currentDirectory;
  /// Public method or function.
  String join(String part1, [String? part2, String? part3]);
  /// Public method or function.
  Future<void> createDirectory(String path);
  /// Public method or function.
  Future<void> delete(String path);
  /// Public method or function.
  Future<void> copy(String source, String destination);
}