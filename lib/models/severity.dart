sealed class Severity implements Comparable<Severity> {
  const Severity();
  String get name;
  int get value;
  String get label;
  String get emoji;

  @override
  int compareTo(Severity other) => value.compareTo(other.value);

  static const info = _SeverityInfo();
  static const warning = _SeverityWarning();
  static const error = _SeverityError();
  static const critical = _SeverityCritical();

  static Severity fromValue(int value) => switch (value) {
    0 => info,
    1 => warning,
    2 => error,
    3 => critical,
    _ => throw ArgumentError('Invalid severity value: $value'),
  };
}

final class _SeverityInfo extends Severity {
  const _SeverityInfo();
  @override String get name => 'info';
  @override int get value => 0;
  @override String get label => 'Info';
  @override String get emoji => 'ℹ️';
}

final class _SeverityWarning extends Severity {
  const _SeverityWarning();
  @override String get name => 'warning';
  @override int get value => 1;
  @override String get label => 'Warning';
  @override String get emoji => '⚠️';
}

final class _SeverityError extends Severity {
  const _SeverityError();
  @override String get name => 'error';
  @override int get value => 2;
  @override String get label => 'Error';
  @override String get emoji => '❌';
}

final class _SeverityCritical extends Severity {
  const _SeverityCritical();
  @override String get name => 'critical';
  @override int get value => 3;
  @override String get label => 'Critical';
  @override String get emoji => '🚨';
}
