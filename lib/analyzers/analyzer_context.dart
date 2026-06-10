import 'package:firedoctor/filesystem/filesystem.dart';

final class AnalyzerContext {
  final String projectPath;
  final FileSystem fileSystem;
  final Map<String, String> configuration;

  const AnalyzerContext({
    required this.projectPath,
    required this.fileSystem,
    this.configuration = const {},
  });
}
