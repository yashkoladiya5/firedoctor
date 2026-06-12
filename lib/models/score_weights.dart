import 'package:firedoctor/models/severity.dart';

/// Core class.
final class ScoreWeights {
  /// Public property or field.
  final int critical;
  /// Public property or field.
  final int error;
  /// Public property or field.
  final int warning;
  /// Public property or field.
  final int info;

  const ScoreWeights({
    this.critical = 25,
    this.error = 15,
    this.warning = 5,
    this.info = 1,
  });

  /// Public method or function.
  int weightFor(Severity severity) {
    if (severity == Severity.critical) return critical;
    if (severity == Severity.error) return error;
    if (severity == Severity.warning) return warning;
    return info;
  }

  int get maxScorePerIssue => critical;

  /// Public method or function.
  ScoreWeights copyWith({int? critical, int? error, int? warning, int? info}) {
    return ScoreWeights(
      critical: critical ?? this.critical,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  static const defaultWeights = ScoreWeights();
}