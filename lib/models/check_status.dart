sealed class CheckStatus {
  const CheckStatus();
  String get name;
  String get label;
  bool get isPassed => this is _CheckStatusPassed;
  bool get isFailed => this is _CheckStatusFailed;
  bool get isWarning => this is _CheckStatusWarning;

  static const passed = _CheckStatusPassed();
  static const failed = _CheckStatusFailed();
  static const warning = _CheckStatusWarning();
  static const skipped = _CheckStatusSkipped();
  static const notApplicable = _CheckStatusNotApplicable();

  static CheckStatus fromName(String name) => switch (name) {
    'passed' => passed,
    'failed' => failed,
    'warning' => warning,
    'skipped' => skipped,
    'not_applicable' => notApplicable,
    _ => throw ArgumentError('Invalid check status name: $name'),
  };
}

final class _CheckStatusPassed extends CheckStatus {
  const _CheckStatusPassed();
  @override String get name => 'passed';
  @override String get label => 'Passed';
}

final class _CheckStatusFailed extends CheckStatus {
  const _CheckStatusFailed();
  @override String get name => 'failed';
  @override String get label => 'Failed';
}

final class _CheckStatusWarning extends CheckStatus {
  const _CheckStatusWarning();
  @override String get name => 'warning';
  @override String get label => 'Warning';
}

final class _CheckStatusSkipped extends CheckStatus {
  const _CheckStatusSkipped();
  @override String get name => 'skipped';
  @override String get label => 'Skipped';
}

final class _CheckStatusNotApplicable extends CheckStatus {
  const _CheckStatusNotApplicable();
  @override String get name => 'not_applicable';
  @override String get label => 'N/A';
}
