import 'dart:convert';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/filesystem/filesystem.dart';
import 'package:firedoctor/logging/logging.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/analyzer_service.dart';

class ValidationService {
  final AnalyzerService analyzerService;
  final FileSystem fileSystem;
  final Logger? logger;

  ValidationService({
    required this.analyzerService,
    required this.fileSystem,
    this.logger,
  });

  /// Load expected findings from a project's expected_findings.json
  Future<List<ExpectedFinding>> loadExpectedFindings(String projectPath) async {
    final path = fileSystem.join(projectPath, 'expected_findings.json');
    if (!fileSystem.exists(path)) return [];
    final content = await fileSystem.readAsStringAsync(path);
    final json = jsonDecode(content) as Map<String, dynamic>;
    return (json['expectedFindings'] as List)
        .map((e) => ExpectedFinding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Run all analyzers on a single project and produce a ValidationEntry
  Future<ValidationEntry> validateProject(String projectPath) async {
    final expectedFindings = await loadExpectedFindings(projectPath);

    // Extract project name from expected_findings.json
    final content = await fileSystem.readAsStringAsync(
      fileSystem.join(projectPath, 'expected_findings.json'),
    );
    final json = jsonDecode(content) as Map<String, dynamic>;
    final projectName =
        json['projectName'] as String? ?? projectPath.split('/').last;

    // Run all analyzers
    final context = AnalyzerContext(
      projectPath: projectPath,
      fileSystem: fileSystem,
    );
    final results = await analyzerService.runAll(context);

    // Collect all actual findings
    final actualFindings = <DiagnosticIssue>[];
    for (final result in results) {
      for (final issue in result.issues) {
        actualFindings.add(issue);
      }
    }

    // Match expected vs actual
    final matchedExpected = <int>{};
    final truePositives = <ExpectedFinding>[];
    final falsePositives = <DiagnosticIssue>[];

    for (final actual in actualFindings) {
      var matched = false;
      for (var i = 0; i < expectedFindings.length; i++) {
        final expected = expectedFindings[i];
        if (expected.shouldBeFound &&
            expected.code == actual.code &&
            expected.analyzerName == _analyzerNameForCode(actual.code)) {
          matchedExpected.add(i);
          matched = true;
          break;
        }
      }
      if (matched) {
        truePositives.add(expectedFindings.elementAt(matchedExpected.last));
      } else {
        falsePositives.add(actual);
      }
    }

    // False negatives: expected to be found but weren't
    final falseNegatives = <ExpectedFinding>[];
    for (var i = 0; i < expectedFindings.length; i++) {
      if (expectedFindings[i].shouldBeFound && !matchedExpected.contains(i)) {
        falseNegatives.add(expectedFindings[i]);
      }
    }

    // Unmatched not-should-be-found = correct true negatives (not explicitly tracked)
    // Total checks = all expected findings
    final totalChecks = expectedFindings.length;
    // correct = truePositives + trueNegatives
    // trueNegatives = expected where shouldBeFound:false AND not in falsePositives
    final shouldBeFalseCount = expectedFindings
        .where((e) => !e.shouldBeFound)
        .length;
    final trueNegatives = (shouldBeFalseCount - falsePositives.length).clamp(
      0,
      shouldBeFalseCount,
    );
    final totalCorrect = truePositives.length + trueNegatives;
    final accuracy = totalChecks > 0 ? totalCorrect / totalChecks : 1.0;
    final precision = (truePositives.length + falsePositives.length) > 0
        ? truePositives.length / (truePositives.length + falsePositives.length)
        : 1.0;
    final recall = (truePositives.length + falseNegatives.length) > 0
        ? truePositives.length / (truePositives.length + falseNegatives.length)
        : 1.0;

    return ValidationEntry(
      projectName: projectName,
      projectPath: projectPath,
      totalChecks: totalChecks,
      truePositives: truePositives,
      falseNegatives: falseNegatives,
      falsePositives: falsePositives,
      accuracy: accuracy,
      precision: precision,
      recall: recall,
    );
  }

  /// Validate all projects in a directory
  Future<ValidationReport> validateAll(
    String projectsDir, {
    Logger? progressLogger,
  }) async {
    final log = progressLogger ?? logger;
    log?.info('Validating projects in: $projectsDir');

    final entries = <ValidationEntry>[];
    final dirs = fileSystem.listDirectory(projectsDir);

    // Sort for deterministic order
    dirs.sort();

    for (final dir in dirs) {
      if (fileSystem.isDirectory(dir)) {
        final hasExpected = fileSystem.exists(
          fileSystem.join(dir, 'expected_findings.json'),
        );
        if (!hasExpected) continue;

        final name = dir.split('/').last;
        log?.info('Validating: $name');
        try {
          final entry = await validateProject(dir);
          entries.add(entry);
          log?.success(
            '$name: accuracy=${(entry.accuracy * 100).toStringAsFixed(1)}% '
            'TP=${entry.truePositives.length} FP=${entry.falsePositives.length} '
            'FN=${entry.falseNegatives.length}',
          );
        } catch (e) {
          log?.error('$name failed: $e');
        }
      }
    }

    return ValidationReport(entries: entries, generatedAt: DateTime.now());
  }

  String _analyzerNameForCode(String code) {
    // Match first 3 chars of FD-prefixed codes (FD2, FD3, etc.)
    final prefix = code.length >= 3 ? code.substring(0, 3) : '';
    return switch (prefix) {
      'FD1' => 'project',
      'FD2' => 'dependency',
      'FD3' => 'firebase_core',
      'FD4' => 'android',
      'FD5' => 'ios',
      'FD6' => 'fcm',
      'FD7' => 'crashlytics',
      // Non-FD codes (MISSING_*, NOT_FLUTTER_PROJECT, INVALID_PUBSPEC, FLUTTER_*)
      // all come from the project analyzer
      _ => 'project',
    };
  }
}
