import 'package:firedoctor/filesystem/filesystem.dart';
import 'package:firedoctor/shared/source_file_cache.dart';

final class AnalyzerContext {
  final String projectPath;
  final FileSystem fileSystem;
  final Map<String, String> configuration;
  final SourceFileCache? sourceFileCache;

  AnalyzerContext({
    required this.projectPath,
    required this.fileSystem,
    this.configuration = const {},
    this.sourceFileCache,
  });
}
