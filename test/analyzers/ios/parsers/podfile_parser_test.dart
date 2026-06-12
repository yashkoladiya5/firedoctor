import 'package:test/test.dart';
import 'package:firedoctor/analyzers/ios/parsers/podfile_parser.dart';

void main() {
  group('PodfileParser', () {
    late PodfileParser parser;

    setUp(() {
      parser = const PodfileParser();
    });

    group('parse', () {
      test('returns null for empty content', () {
        final result = parser.parse('');
        expect(result, isNull);
      });

      test('returns null for whitespace-only content', () {
        final result = parser.parse('   \n  ');
        expect(result, isNull);
      });

      test('parses platform version correctly', () {
        final result = parser.parse("platform :ios, '12.0'");
        expect(result, isNotNull);
        expect(result!.iosVersion, equals(12.0));
      });

      test('parses platform version with patch number', () {
        final result = parser.parse("platform :ios, '12.1.4'");
        expect(result, isNotNull);
        expect(result!.iosVersion, equals(12.1));
      });

      test('parses single-digit platform version', () {
        final result = parser.parse("platform :ios, '9'");
        expect(result, isNotNull);
        expect(result!.iosVersion, closeTo(9.0, 0.001));
      });

      test('detects Runner target', () {
        final result = parser.parse("""
platform :ios, '12.0'
target 'Runner' do
  use_frameworks!
end
""");
        expect(result, isNotNull);
        expect(result!.hasRunnerTarget, isTrue);
      });

      test('detects Firebase pods', () {
        final result = parser.parse("""
platform :ios, '12.0'
target 'Runner' do
  pod 'Firebase/Core'
end
""");
        expect(result, isNotNull);
        expect(result!.hasFirebasePods, isTrue);
        expect(result.pods, contains('Firebase/Core'));
      });

      test('returns isFirebasePods false when no Firebase pods', () {
        final result = parser.parse("""
platform :ios, '12.0'
target 'Runner' do
  pod 'Alamofire'
end
""");
        expect(result, isNotNull);
        expect(result!.hasFirebasePods, isFalse);
        expect(result.pods, contains('Alamofire'));
      });

      test('strips comments', () {
        final result = parser.parse("""
# This is a comment
platform :ios, '12.0' # inline comment
target 'Runner' do
  use_frameworks!
  pod 'Firebase/Core' # firebase pod
end
""");
        expect(result, isNotNull);
        expect(result!.iosVersion, equals(12.0));
        expect(result.hasFirebasePods, isTrue);
        expect(result.hasRunnerTarget, isTrue);
      });

      test('detects multiple pods', () {
        final result = parser.parse("""
platform :ios, '15.0'
target 'Runner' do
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'Alamofire'
end
""");
        expect(result, isNotNull);
        expect(result!.hasFirebasePods, isTrue);
        expect(result.pods.length, equals(4));
      });
    });
  });
}
