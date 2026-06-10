import 'package:test/test.dart';
import 'package:firedoctor/firedoctor.dart';

void main() {
  group('runFireDoctor', () {
    // Full integration tests will be added in Phase 2 when the architecture
    // supports testing with mock dependencies (runFireDoctor calls exit()).
    test('is a top-level function', () {
      expect(runFireDoctor, isA<Function>());
    });
  });
}
