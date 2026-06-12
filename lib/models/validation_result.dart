import 'dart:convert';
import 'package:firedoctor/models/diagnostic_issue.dart';

final class ExpectedFinding {
  final String analyzerName;
  final String code;
  final bool shouldBeFound;

  const ExpectedFinding({
    required this.analyzerName,
    required this.code,
    required this.shouldBeFound,
  });

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

final class ValidationEntry {
  final String projectName;
  final String projectPath;
  final int totalChecks;
  final List<ExpectedFinding> truePositives;
  final List<ExpectedFinding> falseNegatives;
  final List<DiagnosticIssue> falsePositives;
  final double accuracy;
  final double precision;
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

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'projectPath': projectPath,
        'totalChecks': totalChecks,
        'totalExpected': totalExpected,
        'totalActual': totalActual,
        'truePositives': truePositives.map((e) => e.toJson()).toList(),
        'falseNegatives': falseNegatives.map((e) => e.toJson()).toList(),
        'falsePositives': falsePositives
            .map((i) => {
                  'code': i.code,
                  'title': i.title,
                  'severity': i.severity.name,
                  'analyzerName': i.code.substring(0, 2),
                })
            .toList(),
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
      };
}

final class ValidationReport {
  final List<ValidationEntry> entries;
  final DateTime generatedAt;

  const ValidationReport({
    required this.entries,
    required this.generatedAt,
  });

  int get totalTruePositives =>
      entries.fold(0, (sum, e) => sum + e.truePositives.length);
  int get totalFalsePositives =>
      entries.fold(0, (sum, e) => sum + e.falsePositives.length);
  int get totalFalseNegatives =>
      entries.fold(0, (sum, e) => sum + e.falseNegatives.length);

  double get overallAccuracy => _safeAvg(entries.map((e) => e.accuracy));
  double get overallPrecision => _safeAvg(entries.map((e) => e.precision));
  double get overallRecall => _safeAvg(entries.map((e) => e.recall));

  Map<String, double> get analyzerPrecision {
    final map = <String, List<double>>{};
    for (final entry in entries) {
      for (final tp in entry.truePositives) {
        map.putIfAbsent(tp.analyzerName, () => []).add(1.0);
      }
      for (final fp in entry.falsePositives) {
        final an = fp.code.length >= 4 ? '${fp.code[0]}${fp.code[1]}${fp.code[2]}' : 'unknown';
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
        falseNegMap[fn.analyzerName] =
            (falseNegMap[fn.analyzerName] ?? 0) + 1;
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

  String toJsonString() {
    final map = <String, dynamic>{
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'overallAccuracy': overallAccuracy,
      'overallPrecision': overallPrecision,
      'overallRecall': overallRecall,
      'totalTruePositives': totalTruePositives,
      'totalFalsePositives': totalFalsePositives,
      'totalFalseNegatives': totalFalseNegatives,
      'analyzerPrecision':
          analyzerPrecision.map((k, v) => MapEntry(k, v.toStringAsFixed(4))),
      'analyzerRecall':
          analyzerRecall.map((k, v) => MapEntry(k, v.toStringAsFixed(4))),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static double _safeAvg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
