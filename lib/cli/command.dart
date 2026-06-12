/// Core class.
abstract class Command {
  /// Public property or field.
  String get name;
  /// Public property or field.
  String get description;
  List<String> get aliases => [];
  /// Public method or function.
  Future<int> execute(List<String> args);
}