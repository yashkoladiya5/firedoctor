abstract class FileSystem {
  bool exists(String path);
  String readAsString(String path);
  Future<String> readAsStringAsync(String path);
  void writeAsString(String path, String content);
  Future<void> writeAsStringAsync(String path, String content);
  List<String> listDirectory(String path);
  bool isDirectory(String path);
  bool isFile(String path);
  String get currentDirectory;
  String join(String part1, [String? part2, String? part3]);
  Future<void> createDirectory(String path);
  Future<void> delete(String path);
  Future<void> copy(String source, String destination);
}
