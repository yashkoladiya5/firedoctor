/// Core class.
final class PodfileParser {
  const PodfileParser();

  ({
    double? iosVersion,
    bool hasFirebasePods,
    List<String> pods,
    bool hasRunnerTarget,
  })?
  parse(String content) {
    if (content.trim().isEmpty) return null;

    final stripped = _stripComments(content);

    double? iosVersion;
    final versionMatch = RegExp(
      r'''platform\s+:\w+\s*,\s*['"]([\d.]+)['"]''',
    ).firstMatch(stripped);
    if (versionMatch != null) {
      final versionStr = versionMatch.group(1)!;
      final parts = versionStr.split('.');
      if (parts.length >= 2) {
        iosVersion = double.tryParse('${parts[0]}.${parts[1]}');
      } else {
        iosVersion = double.tryParse(versionStr);
      }
    }

    final hasRunnerTarget = RegExp(
      r'''target\s+['"]Runner['"]''',
    ).hasMatch(stripped);

    final pods = <String>[];
    for (final match in RegExp(
      r'''pod\s+['"]([^'"]*)['"]''',
    ).allMatches(stripped)) {
      pods.add(match.group(1)!);
    }

    final hasFirebasePods = pods.any(
      (p) => p == 'Firebase' || p.startsWith('Firebase/'),
    );

    if (versionMatch == null && !hasRunnerTarget && pods.isEmpty) {
      return null;
    }

    return (
      iosVersion: iosVersion,
      hasFirebasePods: hasFirebasePods,
      pods: pods,
      hasRunnerTarget: hasRunnerTarget,
    );
  }

  String _stripComments(String content) {
    final lines = content.split('\n');
    final result = <String>[];
    for (final line in lines) {
      final commentStart = line.indexOf('#');
      if (commentStart >= 0) {
        result.add(line.substring(0, commentStart));
      } else {
        result.add(line);
      }
    }
    return result.join('\n');
  }
}