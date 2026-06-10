final class Pubspec {
  final String name;
  final String? version;
  final String? description;
  final Map<String, String> dependencies;
  final Map<String, String> devDependencies;
  final String? flutterSdkConstraint;
  final String? dartSdkConstraint;
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

  bool hasDependency(String packageName) => dependencies.containsKey(packageName);

  bool hasDevDependency(String packageName) => devDependencies.containsKey(packageName);

  String? dependencyVersion(String packageName) => dependencies[packageName];
}
