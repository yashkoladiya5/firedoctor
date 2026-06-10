abstract class Command {
  String get name;
  String get description;
  List<String> get aliases => [];
  Future<int> execute(List<String> args);
}
