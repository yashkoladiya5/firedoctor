final class PbxprojParser {
  const PbxprojParser();

  ({
    String? bundleIdentifier,
    String? runnerTargetName,
    bool hasPushCapability,
    bool hasBackgroundModes,
  }) parse(String content) {
    String? bundleIdentifier;
    String? runnerTargetName;
    var hasPushCapability = false;
    var hasBackgroundModes = false;

    final bundleIdMatch = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+)',
    ).firstMatch(content);
    if (bundleIdMatch != null) {
      bundleIdentifier =
          bundleIdMatch.group(1)?.trim().replaceAll('"', '');
    }

    if (RegExp(r'''name\s*=\s*"?Runner"?\s*;''').hasMatch(content)) {
      runnerTargetName = 'Runner';
    }

    final sysCapMatch = RegExp(r'SystemCapabilities\s*=\s*\{').firstMatch(content);
    if (sysCapMatch != null) {
      final start = sysCapMatch.end;
      var depth = 1;
      var end = start;
      while (end < content.length && depth > 0) {
        if (content[end] == '{') depth++;
        if (content[end] == '}') depth--;
        end++;
      }
      final block = content.substring(start, end - 1);
      hasPushCapability = RegExp(
        r'com\.apple\.Push\s*=\s*\{[^}]*enabled\s*=\s*1',
      ).hasMatch(block);
      hasBackgroundModes = RegExp(
        r'com\.apple\.BackgroundModes\s*=\s*\{[^}]*enabled\s*=\s*1',
      ).hasMatch(block);
    }

    return (
      bundleIdentifier: bundleIdentifier,
      runnerTargetName: runnerTargetName,
      hasPushCapability: hasPushCapability,
      hasBackgroundModes: hasBackgroundModes,
    );
  }
}
