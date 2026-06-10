import 'package:test/test.dart';
import 'package:firedoctor/analyzers/ios/parsers/pbxproj_parser.dart';

void main() {
  group('PbxprojParser', () {
    late PbxprojParser parser;

    setUp(() {
      parser = const PbxprojParser();
    });

    group('parse', () {
      test('parses PRODUCT_BUNDLE_IDENTIFIER', () {
        final result = parser.parse('''
{
  buildSettings = {
    PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
  };
}
''');
        expect(result.bundleIdentifier, equals('com.example.testapp'));
      });

      test('parses bundle identifier with quotes', () {
        final result = parser.parse('''
{
  buildSettings = {
    PRODUCT_BUNDLE_IDENTIFIER = "com.example.testapp";
  };
}
''');
        expect(result.bundleIdentifier, equals('com.example.testapp'));
      });

      test('returns null bundle identifier when not found', () {
        final result = parser.parse('{buildSettings = {OTHER_KEY = value;};}');
        expect(result.bundleIdentifier, isNull);
      });

      test('detects Runner target by name', () {
        final result = parser.parse('''
{
  someObject = {
    name = Runner;
  };
}
''');
        expect(result.runnerTargetName, equals('Runner'));
      });

      test('does not detect Runner target when not present', () {
        final result = parser.parse('{someObject = {name = Other;};}');
        expect(result.runnerTargetName, isNull);
      });

      test('detects Push capability', () {
        final result = parser.parse('''
{
  SystemCapabilities = {
    com.apple.Push = {
      enabled = 1;
    };
  };
}
''');
        expect(result.hasPushCapability, isTrue);
      });

      test('detects BackgroundModes capability', () {
        final result = parser.parse('''
{
  SystemCapabilities = {
    com.apple.BackgroundModes = {
      enabled = 1;
    };
  };
}
''');
        expect(result.hasBackgroundModes, isTrue);
      });

      test('returns false for capabilities when SystemCapabilities missing', () {
        final result = parser.parse('{buildSettings = {};}');
        expect(result.hasPushCapability, isFalse);
        expect(result.hasBackgroundModes, isFalse);
      });

      test('parses complete pbxproj structure', () {
        final result = parser.parse('''
{
  objects = {
    target1 = {
      isa = PBXNativeTarget;
      name = Runner;
    };
    config1 = {
      isa = XCBuildConfiguration;
      buildSettings = {
        PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
        SystemCapabilities = {
          com.apple.Push = {
            enabled = 1;
          };
          com.apple.BackgroundModes = {
            enabled = 1;
          };
        };
      };
      name = Debug;
    };
  };
}
''');
        expect(result.bundleIdentifier, equals('com.example.testapp'));
        expect(result.runnerTargetName, equals('Runner'));
        expect(result.hasPushCapability, isTrue);
        expect(result.hasBackgroundModes, isTrue);
      });
    });
  });
}
