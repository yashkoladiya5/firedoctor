import 'package:firedoctor/filesystem/filesystem.dart';
import 'package:firedoctor/shared/source_file_cache.dart';

/// Core class.
final class AnalyzerContext {
  /// Public property or field.
  final String projectPath;
  /// Public property or field.
  final FileSystem fileSystem;
  /// Public property or field.
  final Map<String, String> configuration;
  /// Public property or field.
  final SourceFileCache? sourceFileCache;

  AnalyzerContext({
    required this.projectPath,
    required this.fileSystem,
    this.configuration = const {},
    this.sourceFileCache,
  });
}