import 'dart:convert';
import 'package:firedoctor/models/diagnostic_issue.dart';

/// Core class.
final class ExpectedFinding {
  /// Public property or field.
  final String analyzerName;
  /// Public property or field.
  final String code;
  /// Public property or field.
  final bool shouldBeFound;

  const ExpectedFinding({
    required this.analyzerName,
    required this.code,
    required this.shouldBeFound,
  });

  /// Public method or function.
  Map<String, dynamic> toJson() => {
    'analyzerName': analyzerName,
    'code': code,
    'shouldBeFound': shouldBeFound,
  };

  factory ExpectedFinding.fromJson(Map<String, dynamic> json) =>
      ExpectedFinding(
        analyzerName: json['analyzerName'] as String,
        code: json['code'] as String,
        shouldBeFound: json['shouldBeFound'] as bool,
      );
}

/// Core class.
final class ValidationEntry {
  /// Public property or field.
  final String projectName;
  /// Public property or field.
  final String projectPath;
  /// Public property or field.
  final int totalChecks;
  /// Public property or field.
  final List<ExpectedFinding> truePositives;
  /// Public property or field.
  final List<ExpectedFinding> falseNegatives;
  /// Public property or field.
  final List<DiagnosticIssue> falsePositives;
  /// Public property or field.
  final double accuracy;
  /// Public property or field.
  final double precision;
  /// Public property or field.
  final double recall;

  const ValidationEntry({
    required this.projectName,
    required this.projectPath,
    required this.totalChecks,
    required this.truePositives,
    required this.falseNegatives,
    required this.falsePositives,
    required this.accuracy,
    required this.precision,
    required this.recall,
  });

  int get totalExpected => truePositives.length + falseNegatives.length;
  int get totalActual => truePositives.length + falsePositives.length;

  /// Public method or function.
  Map<String, dynamic> toJson() => {
    'projectName': projectName,
    'projectPath': projectPath,
    'totalChecks': totalChecks,
    'totalExpected': totalExpected,
    'totalActual': totalActual,
    'truePositives': truePositives.map((e) => e.toJson()).toList(),
    'falseNegatives': falseNegatives.map((e) => e.toJson()).toList(),
    'falsePositives': falsePositives
        .map(
          (i) => {
            'code': i.code,
            'title': i.title,
            'severity': i.severity.name,
            'analyzerName': i.code.substring(0, 2),
          },
        )
        .toList(),
    'accuracy': accuracy,
    'precision': precision,
    'recall': recall,
  };
}

/// Core class.
final class ValidationReport {
  /// Public property or field.
  final List<ValidationEntry> entries;
  /// Public property or field.
  final DateTime generatedAt;

  const ValidationReport({required this.entries, required this.generatedAt});

  int get totalTruePositives =>
      entries.fold(0, (sum, e) => sum + e.truePositives.length);
  int get totalFalsePositives =>
      entries.fold(0, (sum, e) => sum + e.falsePositives.length);
  int get totalFalseNegatives =>
      entries.fold(0, (sum, e) => sum + e.falseNegatives.length);

  double get overallAccuracy {
    if (entries.isEmpty) return 0.0;
    final totalTP = entries.fold(0, (sum, e) => sum + e.truePositives.length);
    final totalFP = entries.fold(0, (sum, e) => sum + e.falsePositives.length);
    final totalChecks = entries.fold(0, (sum, e) => sum + e.totalChecks);
    final totalCorrect = totalTP + (totalChecks - totalTP - totalFP);
    return totalChecks > 0 ? totalCorrect / totalChecks : 0.0;
  }

  double get overallPrecision => _safeAvg(entries.map((e) => e.precision));
  double get overallRecall => _safeAvg(entries.map((e) => e.recall));

  Map<String, double> get analyzerPrecision {
    final map = <String, List<double>>{};
    for (final entry in entries) {
      for (final tp in entry.truePositives) {
        map.putIfAbsent(tp.analyzerName, () => []).add(1.0);
      }
      for (final fp in entry.falsePositives) {
        final an = _analyzerNameFromCode(fp.code);
        map.putIfAbsent(an, () => []).add(0.0);
      }
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  Map<String, double> get analyzerRecall {
    final trueMap = <String, int>{};
    final falseNegMap = <String, int>{};
    for (final entry in entries) {
      for (final tp in entry.truePositives) {
        trueMap[tp.analyzerName] = (trueMap[tp.analyzerName] ?? 0) + 1;
      }
      for (final fn in entry.falseNegatives) {
        falseNegMap[fn.analyzerName] = (falseNegMap[fn.analyzerName] ?? 0) + 1;
      }
    }
    final result = <String, double>{};
    for (final key in {...trueMap.keys, ...falseNegMap.keys}) {
      final tp = trueMap[key] ?? 0;
      final fn = falseNegMap[key] ?? 0;
      result[key] = tp + fn > 0 ? tp / (tp + fn) : 1.0;
    }
    return result;
  }

  /// Public method or function.
  String toJsonString() {
    final map = <String, dynamic>{
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'overallAccuracy': overallAccuracy,
      'overallPrecision': overallPrecision,
      'overallRecall': overallRecall,
      'totalTruePositives': totalTruePositives,
      'totalFalsePositives': totalFalsePositives,
      'totalFalseNegatives': totalFalseNegatives,
      'analyzerPrecision': analyzerPrecision.map(
        (k, v) => MapEntry(k, v.toStringAsFixed(4)),
      ),
      'analyzerRecall': analyzerRecall.map(
        (k, v) => MapEntry(k, v.toStringAsFixed(4)),
      ),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static String _analyzerNameFromCode(String code) {
    final prefix = code.length >= 3 ? code.substring(0, 3) : '';
    return switch (prefix) {
      'FD1' => 'project',
      'FD2' => 'dependency',
      'FD3' => 'firebase_core',
      'FD4' => 'android',
      'FD5' => 'ios',
      'FD6' => 'fcm',
      'FD7' => 'crashlytics',
      _ => 'project',
    };
  }

  static double _safeAvg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}