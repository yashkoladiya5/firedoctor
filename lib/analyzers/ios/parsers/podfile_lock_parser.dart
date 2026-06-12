/// Core class.
final class PodfileLockParser {
  const PodfileLockParser();

  ({List<String> firebasePods, bool hasFirebasePods}) parse(String content) {
    final firebasePods = <String>[];
    final inPodsSection = _findPodsSection(content);

    for (final line in inPodsSection) {
      final trimmed = line.trim();
      if (trimmed.contains('Firebase') && trimmed.startsWith('-')) {
        final podMatch = RegExp(r'- ([^\s(]+)').firstMatch(trimmed);
        if (podMatch != null) {
          firebasePods.add(podMatch.group(1)!);
        }
      }
    }

    return (
      firebasePods: firebasePods,
      hasFirebasePods: firebasePods.isNotEmpty,
    );
  }

  List<String> _findPodsSection(String content) {
    final lines = content.split('\n');
    var inPods = false;
    const podDepth = 0;
    final result = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();

      if (!inPods) {
        if (trimmed == 'PODS:') {
          inPods = true;
        }
        continue;
      }

      if (podDepth == 0 && trimmed.startsWith('- ')) {
        result.add(line);
        continue;
      }

      if (trimmed.startsWith('- ') || trimmed == '') {
        continue;
      }

      if (trimmed.endsWith(':')) {
        break;
      }
    }

    return result;
  }
}