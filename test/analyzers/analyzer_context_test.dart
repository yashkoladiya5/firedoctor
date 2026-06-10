import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class MockFileSystem extends Mock implements FileSystem {}

void main() {
  group('AnalyzerContext', () {
    test('constructor assigns required fields', () {
      final fs = MockFileSystem();
      final context = AnalyzerContext(
        projectPath: '/my/project',
        fileSystem: fs,
      );

      expect(context.projectPath, equals('/my/project'));
      expect(context.fileSystem, equals(fs));
    });

    test('uses empty configuration by default', () {
      final fs = MockFileSystem();
      final context = AnalyzerContext(
        projectPath: '/test',
        fileSystem: fs,
      );

      expect(context.configuration, isEmpty);
    });

    test('accepts custom configuration', () {
      final fs = MockFileSystem();
      final context = AnalyzerContext(
        projectPath: '/test',
        fileSystem: fs,
        configuration: {'key': 'value', 'verbose': 'true'},
      );

      expect(
          context.configuration, equals({'key': 'value', 'verbose': 'true'}));
    });
  });
}
