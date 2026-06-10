import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/parsers/pubspec_parser.dart';
import 'package:firedoctor/models/pubspec.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';

class _MockFileSystem extends Mock implements FileSystem {}

void main() {
  group('PubspecParser', () {
    group('parse', () {
      test('parses a valid Flutter pubspec.yaml with all fields', () {
        final yaml = '''
name: my_app
version: 1.0.0
description: A Flutter project
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
''';
        final pubspec = PubspecParser.parse(yaml);

        expect(pubspec.name, equals('my_app'));
        expect(pubspec.version, equals('1.0.0'));
        expect(pubspec.description, equals('A Flutter project'));
        expect(pubspec.dartSdkConstraint, equals('>=3.0.0 <4.0.0'));
        expect(pubspec.flutterSdkConstraint, equals('>=3.0.0'));
        expect(pubspec.isFlutterProject, isTrue);
        expect(pubspec.hasDependency('flutter'), isTrue);
        expect(pubspec.hasDependency('firebase_core'), isTrue);
        expect(pubspec.hasDevDependency('flutter_test'), isTrue);
      });

      test('parses a non-Flutter Dart project', () {
        final yaml = '''
name: dart_app
dependencies:
  http: ^1.0.0
dev_dependencies: {}
''';
        final pubspec = PubspecParser.parse(yaml);

        expect(pubspec.name, equals('dart_app'));
        expect(pubspec.isFlutterProject, isFalse);
        expect(pubspec.hasDependency('http'), isTrue);
        expect(pubspec.hasDependency('flutter'), isFalse);
      });

      test('parses project with no dependencies', () {
        final yaml = 'name: empty_project\ndependencies: {}\ndev_dependencies: {}';
        final pubspec = PubspecParser.parse(yaml);

        expect(pubspec.name, equals('empty_project'));
        expect(pubspec.dependencies, isEmpty);
        expect(pubspec.devDependencies, isEmpty);
        expect(pubspec.version, isNull);
        expect(pubspec.dartSdkConstraint, isNull);
        expect(pubspec.flutterSdkConstraint, isNull);
      });

      test('parses project with git dependency', () {
        final yaml = '''
name: git_dep_app
dependencies:
  my_package:
    git:
      url: https://github.com/user/my_package.git
dev_dependencies: {}
''';
        final pubspec = PubspecParser.parse(yaml);

        expect(pubspec.hasDependency('my_package'), isTrue);
        expect(pubspec.dependencyVersion('my_package'), equals('any'));
      });

      test('parses project with path dependency', () {
        final yaml = '''
name: path_dep_app
dependencies:
  local_pkg:
    path: ../local_pkg
dev_dependencies: {}
''';
        final pubspec = PubspecParser.parse(yaml);

        expect(pubspec.hasDependency('local_pkg'), isTrue);
        expect(pubspec.dependencyVersion('local_pkg'), equals('any'));
      });

      test('parses project with flutter dev dependency only', () {
        final yaml = '''
name: dev_only
dependencies:
  http: ^1.0.0
dev_dependencies:
  flutter:
    sdk: flutter
''';
        final pubspec = PubspecParser.parse(yaml);

        expect(pubspec.isFlutterProject, isTrue);
        expect(pubspec.hasDependency('http'), isTrue);
        expect(pubspec.hasDevDependency('flutter'), isTrue);
      });

      test('throws FormatException for empty content', () {
        expect(() => PubspecParser.parse(''), throwsA(isA<FormatException>()));
      });

      test('throws FormatException for non-map content', () {
        expect(
            () => PubspecParser.parse('just a string'),
            throwsA(isA<FormatException>()));
      });

      test('throws TypeError for null content', () {
        expect(
            () => PubspecParser.parse('null'),
            throwsA(isA<FormatException>()));
      });
    });

    group('tryParse', () {
      test('returns Pubspec for valid YAML', () {
        final result =
            PubspecParser.tryParse('name: test\ndependencies: {}\ndev_dependencies: {}');

        expect(result, isA<Pubspec>());
        expect(result!.name, equals('test'));
      });

      test('returns Pubspec for valid Flutter YAML', () {
        final yaml = '''
name: flutter_app
dependencies:
  flutter:
    sdk: flutter
dev_dependencies: {}
''';
        final result = PubspecParser.tryParse(yaml);

        expect(result, isA<Pubspec>());
        expect(result!.isFlutterProject, isTrue);
      });

      test('returns null for empty content', () {
        expect(PubspecParser.tryParse(''), isNull);
      });

      test('returns null for invalid YAML', () {
        expect(PubspecParser.tryParse('{{{'), isNull);
      });

      test('returns null for random string', () {
        expect(PubspecParser.tryParse('not yaml at all'), isNull);
      });
    });

    group('parseFromFile', () {
      test('returns null when file does not exist', () async {
        final fs = _MockFileSystem();
        when(() => fs.exists('/path/pubspec.yaml')).thenReturn(false);

        final result =
            await PubspecParser.parseFromFile('/path/pubspec.yaml', fs);

        expect(result, isNull);
        verify(() => fs.exists('/path/pubspec.yaml')).called(1);
        verifyNever(() => fs.readAsStringAsync(any()));
      });

      test('returns Pubspec when file exists and is valid', () async {
        final fs = _MockFileSystem();
        when(() => fs.exists('/project/pubspec.yaml')).thenReturn(true);
        when(() => fs.readAsStringAsync('/project/pubspec.yaml'))
            .thenAnswer((_) async => 'name: test_app\ndependencies: {}\ndev_dependencies: {}');

        final result =
            await PubspecParser.parseFromFile('/project/pubspec.yaml', fs);

        expect(result, isA<Pubspec>());
        expect(result!.name, equals('test_app'));
        verify(() => fs.exists('/project/pubspec.yaml')).called(1);
        verify(() => fs.readAsStringAsync('/project/pubspec.yaml')).called(1);
      });

      test('returns null when file read throws', () async {
        final fs = _MockFileSystem();
        when(() => fs.exists('/project/pubspec.yaml')).thenReturn(true);
        when(() => fs.readAsStringAsync('/project/pubspec.yaml'))
            .thenThrow(Exception('Read error'));

        final result =
            await PubspecParser.parseFromFile('/project/pubspec.yaml', fs);

        expect(result, isNull);
      });

      test('returns null when file content is invalid YAML', () async {
        final fs = _MockFileSystem();
        when(() => fs.exists('/project/pubspec.yaml')).thenReturn(true);
        when(() => fs.readAsStringAsync('/project/pubspec.yaml'))
            .thenAnswer((_) async => '{{{');

        final result =
            await PubspecParser.parseFromFile('/project/pubspec.yaml', fs);

        expect(result, isNull);
      });

      test('returns Pubspec for Flutter project from file', () async {
        final yaml = '''
name: flutter_app
dependencies:
  flutter:
    sdk: flutter
dev_dependencies: {}
''';
        final fs = _MockFileSystem();
        when(() => fs.exists('/project/pubspec.yaml')).thenReturn(true);
        when(() => fs.readAsStringAsync('/project/pubspec.yaml'))
            .thenAnswer((_) async => yaml);

        final result =
            await PubspecParser.parseFromFile('/project/pubspec.yaml', fs);

        expect(result, isA<Pubspec>());
        expect(result!.isFlutterProject, isTrue);
        expect(result.name, equals('flutter_app'));
      });
    });
  });
}
