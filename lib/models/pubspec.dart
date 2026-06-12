/// Core class.
final class Pubspec {
  /// Public property or field.
  final String name;
  /// Public property or field.
  final String? version;
  /// Public property or field.
  final String? description;
  /// Public property or field.
  final Map<String, String> dependencies;
  /// Public property or field.
  final Map<String, String> devDependencies;
  /// Public property or field.
  final String? flutterSdkConstraint;
  /// Public property or field.
  final String? dartSdkConstraint;
  /// Public property or field.
  final bool isFlutterProject;

  const Pubspec({
    required this.name,
    this.version,
    this.description,
    required this.dependencies,
    required this.devDependencies,
    this.flutterSdkConstraint,
    this.dartSdkConstraint,
    required this.isFlutterProject,
  });

  /// Public method or function.
  bool hasDependency(String packageName) =>
      dependencies.containsKey(packageName);

  /// Public method or function.
  bool hasDevDependency(String packageName) =>
      devDependencies.containsKey(packageName);

  String? dependencyVersion(String packageName) => dependencies[packageName];
}