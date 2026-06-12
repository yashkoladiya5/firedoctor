import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/services/validation_service.dart';

final class ValidationRunner {
  final AnalyzerService analyzerService;
  final FileSystem fileSystem;
  final Logger? logger;

  ValidationRunner({
    required this.analyzerService,
    required this.fileSystem,
    this.logger,
  });

  Future<ValidationReport> runAll({String? projectsDir}) async {
    final dir =
        projectsDir ??
        fileSystem.join(fileSystem.currentDirectory, 'validation', 'projects');

    final service = ValidationService(
      analyzerService: analyzerService,
      fileSystem: fileSystem,
      logger: logger,
    );

    return service.validateAll(dir, progressLogger: logger);
  }

  Future<void> saveReport(ValidationReport report, String outputPath) async {
    final json = report.toJsonString();
    await fileSystem.writeAsStringAsync(outputPath, json);
  }

  Map<String, double> getConfidenceScores() {
    return AnalyzerConfidence.defaults.map(
      (key, value) => MapEntry(key, value.confidence),
    );
  }

  /// Returns average confidence grouped by analyzer category
  Map<String, double> getConfidenceByCategory() {
    final byCategory = <String, List<double>>{};
    for (final entry in AnalyzerConfidence.defaults.entries) {
      final category = _categoryForCode(entry.key);
      byCategory.putIfAbsent(category, () => []).add(entry.value.confidence);
    }
    return byCategory.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
  }

  String _categoryForCode(String code) {
    final prefix = code.length >= 3 ? code.substring(0, 3) : '';
    return switch (prefix) {
      'FD1' => 'project',
      'FD2' => 'dependency',
      'FD3' => 'firebase_core',
      'FD4' => 'android',
      'FD5' => 'ios',
      'FD6' => 'fcm',
      'FD7' => 'crashlytics',
      _ => 'unknown',
    };
  }
}
