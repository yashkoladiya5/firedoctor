import 'package:firedoctor/models/severity.dart';

final class ScoreWeights {
  final int critical;
  final int error;
  final int warning;
  final int info;

  const ScoreWeights({
    this.critical = 25,
    this.error = 15,
    this.warning = 5,
    this.info = 1,
  });

  int weightFor(Severity severity) {
    if (severity == Severity.critical) return critical;
    if (severity == Severity.error) return error;
    if (severity == Severity.warning) return warning;
    return info;
  }

  int get maxScorePerIssue => critical;

  ScoreWeights copyWith({
    int? critical,
    int? error,
    int? warning,
    int? info,
  }) {
    return ScoreWeights(
      critical: critical ?? this.critical,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  static const defaultWeights = ScoreWeights();
}
