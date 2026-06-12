/// Core class.
final class PlistParser {
  const PlistParser();

  /// Public method or function.
  Map<String, String>? parseGoogleServiceInfoPlist(String content) {
    if (content.trim().isEmpty) return null;
    if (!content.contains('<dict>') || !content.contains('<plist')) {
      return null;
    }

    final dict = _parseDict(
      content,
      content.indexOf('<dict>') + '<dict>'.length,
    );
    if (dict == null || dict.isEmpty) return null;

    return dict.map((key, value) => MapEntry(key, value.toString()));
  }

  ({List<String> backgroundModes, bool hasFirebaseAppDelegateProxy})
  parseInfoPlist(String content) {
    final backgroundModes = <String>[];
    var hasFirebaseAppDelegateProxy = false;

    final bgModesRegex = RegExp(
      r'<key>UIBackgroundModes</key>\s*<array>\s*([\s\S]*?)\s*</array>',
    );
    final bgModesMatch = bgModesRegex.firstMatch(content);
    if (bgModesMatch != null) {
      final arrayContent = bgModesMatch.group(1)!;
      for (final match in RegExp(
        r'<string>([^<]+)</string>',
      ).allMatches(arrayContent)) {
        backgroundModes.add(match.group(1)!);
      }
    }

    hasFirebaseAppDelegateProxy = RegExp(
      r'<key>FirebaseAppDelegateProxyEnabled</key>',
    ).hasMatch(content);

    return (
      backgroundModes: backgroundModes,
      hasFirebaseAppDelegateProxy: hasFirebaseAppDelegateProxy,
    );
  }

  Map<String, dynamic>? _parseDict(String content, int startIndex) {
    final result = <String, dynamic>{};
    var i = startIndex;
    var depth = 1;

    while (i < content.length && depth > 0) {
      if (content[i] == '<') {
        if (content.substring(i).startsWith('</dict>')) {
          depth--;
          if (depth == 0) break;
          i += '</dict>'.length;
          continue;
        }
        if (content.substring(i).startsWith('<dict>')) {
          i += '<dict>'.length;
          depth++;
          continue;
        }
        if (content.substring(i).startsWith('</plist>')) {
          break;
        }

        final keyMatch = RegExp(
          r'<key>([^<]+)</key>',
        ).matchAsPrefix(content, i);
        if (keyMatch != null) {
          final key = keyMatch.group(1)!;
          i = keyMatch.end;

          while (i < content.length && content[i] != '<') {
            i++;
          }

          if (i < content.length) {
            final stringMatch = RegExp(
              r'<string>([^<]*)</string>',
            ).matchAsPrefix(content, i);
            if (stringMatch != null) {
              result[key] = stringMatch.group(1)!;
              i = stringMatch.end;
              continue;
            }

            final trueMatch = RegExp(r'<true\s*/>').matchAsPrefix(content, i);
            if (trueMatch != null) {
              result[key] = true;
              i = trueMatch.end;
              continue;
            }

            final falseMatch = RegExp(r'<false\s*/>').matchAsPrefix(content, i);
            if (falseMatch != null) {
              result[key] = false;
              i = falseMatch.end;
              continue;
            }

            final integerMatch = RegExp(
              r'<integer>([^<]+)</integer>',
            ).matchAsPrefix(content, i);
            if (integerMatch != null) {
              result[key] = int.tryParse(integerMatch.group(1)!);
              i = integerMatch.end;
              continue;
            }

            final realMatch = RegExp(
              r'<real>([^<]+)</real>',
            ).matchAsPrefix(content, i);
            if (realMatch != null) {
              result[key] = double.tryParse(realMatch.group(1)!);
              i = realMatch.end;
              continue;
            }

            final nestedDictMatch = RegExp(r'<dict>').matchAsPrefix(content, i);
            if (nestedDictMatch != null) {
              final nested = _parseDict(content, i + '<dict>'.length);
              if (nested != null) {
                result[key] = nested;
              }
              final closeDictMatch = RegExp(
                r'</dict>',
              ).firstMatch(content.substring(i));
              if (closeDictMatch != null) {
                i += closeDictMatch.end;
              } else {
                i++;
              }
              continue;
            }

            final arrayMatch = RegExp(r'<array>').matchAsPrefix(content, i);
            if (arrayMatch != null) {
              result[key] = _parseArray(content, i + '<array>'.length);
              final closeArrayMatch = RegExp(
                r'</array>',
              ).firstMatch(content.substring(i));
              if (closeArrayMatch != null) {
                i += closeArrayMatch.end;
              } else {
                i++;
              }
              continue;
            }

            i++;
          }
          continue;
        }

        i++;
      } else {
        i++;
      }
    }

    return result.isEmpty ? null : result;
  }

  List<dynamic> _parseArray(String content, int startIndex) {
    final result = <dynamic>[];
    var i = startIndex;

    while (i < content.length) {
      if (content[i] == '<') {
        if (content.substring(i).startsWith('</array>')) {
          break;
        }

        final stringMatch = RegExp(
          r'<string>([^<]*)</string>',
        ).matchAsPrefix(content, i);
        if (stringMatch != null) {
          result.add(stringMatch.group(1)!);
          i = stringMatch.end;
          continue;
        }

        i++;
      } else {
        i++;
      }
    }

    return result;
  }

  /// Returns `null` if the key is absent, `true` if set to `<true/>`,
  /// `false` if set to `<false/>`.
  bool? parseFirebaseAppDelegateProxyValue(String content) {
    final regex = RegExp(
      r'<key>FirebaseAppDelegateProxyEnabled</key>\s*<(true|false)\s*/>',
    );
    final match = regex.firstMatch(content);
    if (match == null) return null;
    return match.group(1) == 'true';
  }
}