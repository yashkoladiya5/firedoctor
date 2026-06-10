import 'package:yaml/yaml.dart';
import 'package:firedoctor/models/pubspec.dart';
import 'package:firedoctor/filesystem/filesystem.dart';

final class PubspecParser {
  static Pubspec parse(String content) {
    final parsed = loadYaml(content);
    final yaml = parsed is Map ? parsed : null;
    if (yaml == null) {
      throw const FormatException('pubspec.yaml is empty or not a map');
    }

    final name = (yaml['name'] as String?) ?? '';
    final version = yaml['version'] as String?;
    final description = yaml['description'] as String?;

    final deps = <String, String>{};
    final rawDeps = yaml['dependencies'] as Map? ?? {};
    for (final entry in rawDeps.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is String) {
        deps[key] = value;
      } else if (value is YamlMap) {
        deps[key] = 'any';
      } else {
        deps[key] = value.toString();
      }
    }

    final devDeps = <String, String>{};
    final rawDevDeps = yaml['dev_dependencies'] as Map? ?? {};
    for (final entry in rawDevDeps.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is String) {
        devDeps[key] = value;
      } else if (value is YamlMap) {
        devDeps[key] = 'any';
      } else {
        devDeps[key] = value.toString();
      }
    }

    final environment = yaml['environment'] as Map?;
    final flutterSdk = environment?['flutter'] as String?;
    final dartSdk = environment?['sdk'] as String?;

    final isFlutter = deps.containsKey('flutter') || devDeps.containsKey('flutter');

    return Pubspec(
      name: name,
      version: version,
      description: description,
      dependencies: deps,
      devDependencies: devDeps,
      flutterSdkConstraint: flutterSdk,
      dartSdkConstraint: dartSdk,
      isFlutterProject: isFlutter,
    );
  }

  static Future<Pubspec?> parseFromFile(String path, FileSystem fs) async {
    if (!fs.exists(path)) return null;
    try {
      final content = await fs.readAsStringAsync(path);
      return parse(content);
    } catch (_) {
      return null;
    }
  }

  static Pubspec? tryParse(String content) {
    try {
      return parse(content);
    } catch (_) {
      return null;
    }
  }
}
