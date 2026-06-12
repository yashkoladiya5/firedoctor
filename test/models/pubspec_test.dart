import 'package:test/test.dart';
import 'package:firedoctor/models/pubspec.dart';

void main() {
  group('Pubspec', () {
    test('constructor assigns all required fields', () {
      const pubspec = Pubspec(
        name: 'my_app',
        version: '1.0.0',
        description: 'My Flutter app',
        dependencies: {'flutter': 'sdk', 'firebase_core': '^2.0.0'},
        devDependencies: {'flutter_test': 'sdk'},
        flutterSdkConstraint: '>=3.0.0',
        dartSdkConstraint: '>=3.0.0',
        isFlutterProject: true,
      );

      expect(pubspec.name, equals('my_app'));
      expect(pubspec.version, equals('1.0.0'));
      expect(pubspec.description, equals('My Flutter app'));
      expect(
        pubspec.dependencies,
        equals({'flutter': 'sdk', 'firebase_core': '^2.0.0'}),
      );
      expect(pubspec.devDependencies, equals({'flutter_test': 'sdk'}));
      expect(pubspec.flutterSdkConstraint, equals('>=3.0.0'));
      expect(pubspec.dartSdkConstraint, equals('>=3.0.0'));
      expect(pubspec.isFlutterProject, isTrue);
    });

    test('constructor allows only required fields', () {
      const pubspec = Pubspec(
        name: 'minimal',
        dependencies: {},
        devDependencies: {},
        isFlutterProject: false,
      );

      expect(pubspec.name, equals('minimal'));
      expect(pubspec.version, isNull);
      expect(pubspec.description, isNull);
      expect(pubspec.flutterSdkConstraint, isNull);
      expect(pubspec.dartSdkConstraint, isNull);
    });

    test('hasDependency returns true for existing dependency', () {
      const pubspec = Pubspec(
        name: 'test',
        dependencies: {'flutter': 'sdk'},
        devDependencies: {},
        isFlutterProject: true,
      );

      expect(pubspec.hasDependency('flutter'), isTrue);
      expect(pubspec.hasDependency('nonexistent'), isFalse);
    });

    test('hasDevDependency returns true for existing dev dependency', () {
      const pubspec = Pubspec(
        name: 'test',
        dependencies: {},
        devDependencies: {'flutter_test': 'sdk'},
        isFlutterProject: true,
      );

      expect(pubspec.hasDevDependency('flutter_test'), isTrue);
      expect(pubspec.hasDevDependency('nonexistent'), isFalse);
    });

    test(
      'dependencyVersion returns correct version for existing dependency',
      () {
        const pubspec = Pubspec(
          name: 'test',
          dependencies: {'firebase_core': '^2.0.0'},
          devDependencies: {},
          isFlutterProject: false,
        );

        expect(pubspec.dependencyVersion('firebase_core'), equals('^2.0.0'));
        expect(pubspec.dependencyVersion('nonexistent'), isNull);
      },
    );

    test('isFlutterProject is false for non-Flutter project', () {
      const pubspec = Pubspec(
        name: 'dart_app',
        dependencies: {'http': '^1.0.0'},
        devDependencies: {},
        isFlutterProject: false,
      );

      expect(pubspec.isFlutterProject, isFalse);
      expect(pubspec.hasDependency('flutter'), isFalse);
    });

    test('isFlutterProject is true when flutter dependency exists', () {
      const pubspec = Pubspec(
        name: 'flutter_app',
        dependencies: {'flutter': 'sdk'},
        devDependencies: {},
        isFlutterProject: true,
      );

      expect(pubspec.isFlutterProject, isTrue);
      expect(pubspec.hasDependency('flutter'), isTrue);
    });
  });
}
