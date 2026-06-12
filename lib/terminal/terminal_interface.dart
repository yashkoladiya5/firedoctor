/// Core class.
abstract class Terminal {
  /// Public method or function.
  void write(String message);
  /// Public method or function.
  void writeLine(String message);
  /// Public method or function.
  void writeSuccess(String message);
  /// Public method or function.
  void writeWarning(String message);
  /// Public method or function.
  void writeError(String message);
  /// Public method or function.
  void writeInfo(String message);
  String? readLine();
  /// Public method or function.
  void clear();
}