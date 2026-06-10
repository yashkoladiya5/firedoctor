import 'package:test/test.dart';
import 'package:firedoctor/analyzers/ios/parsers/podfile_lock_parser.dart';

void main() {
  group('PodfileLockParser', () {
    late PodfileLockParser parser;

    setUp(() {
      parser = const PodfileLockParser();
    });

    group('parse', () {
      test('detects Firebase pods from PODS section', () {
        final result = parser.parse('''
PODS:
  - Firebase/Core (10.0.0)
  - Firebase/CoreOnly (10.0.0)
  - FirebaseCore (10.0.0)

DEPENDENCIES:
  - Firebase/Core (from `Pods`)

SPEC CHECKSUMS:
  Firebase: abc123
''');
        expect(result.hasFirebasePods, isTrue);
        expect(result.firebasePods, contains('Firebase/Core'));
        expect(result.firebasePods, contains('FirebaseCore'));
      });

      test('returns no pods when PODS section has no Firebase', () {
        final result = parser.parse('''
PODS:
  - Alamofire (5.0.0)

DEPENDENCIES:
  - Alamofire
''');
        expect(result.hasFirebasePods, isFalse);
        expect(result.firebasePods, isEmpty);
      });

      test('returns empty when PODS section is empty', () {
        final result = parser.parse('''
PODS:

DEPENDENCIES:
''');
        expect(result.hasFirebasePods, isFalse);
        expect(result.firebasePods, isEmpty);
      });

      test('returns empty when file has no PODS section', () {
        final result = parser.parse('DEPENDENCIES:');
        expect(result.hasFirebasePods, isFalse);
        expect(result.firebasePods, isEmpty);
      });

      test('handles empty content', () {
        final result = parser.parse('');
        expect(result.hasFirebasePods, isFalse);
        expect(result.firebasePods, isEmpty);
      });

      test('detects Firebase pods even with subspecs', () {
        final result = parser.parse('''
PODS:
  - Firebase/Messaging (10.0.0)
  - Firebase/Analytics (10.0.0)
  - GoogleUtilities (7.0.0)

DEPENDENCIES:
  - Firebase/Messaging
  - Firebase/Analytics
''');
        expect(result.hasFirebasePods, isTrue);
        expect(result.firebasePods, contains('Firebase/Messaging'));
        expect(result.firebasePods, contains('Firebase/Analytics'));
      });
    });
  });
}
