abstract class Terminal {
  void write(String message);
  void writeLine(String message);
  void writeSuccess(String message);
  void writeWarning(String message);
  void writeError(String message);
  void writeInfo(String message);
  String? readLine();
  void clear();
}
