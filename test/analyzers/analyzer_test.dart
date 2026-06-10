import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/models/models.dart';

class MockAnalyzer extends Mock implements Analyzer {}

class TestAnalyzer extends Analyzer {
  @override
  String get name => 'TestAnalyzer';

  @override
  String get description => 'A test analyzer';

  @override
  String get category => 'test';

  final DiagnosticResult result;

  TestAnalyzer(this.result);

  @override
  Future<DiagnosticResult> analyze(AnalyzerContext context) async => result;
}

void main() {
  group('Analyzer', () {
    test('interface can be implemented', () {
      final result = DiagnosticResult(
        analyzerName: 'TestAnalyzer',
        status: CheckStatus.passed,
        issues: [],
        duration: Duration.zero,
        timestamp: DateTime(2024, 1, 1),
      );

      final analyzer = TestAnalyzer(result);
      expect(analyzer.name, equals('TestAnalyzer'));
      expect(analyzer.description, equals('A test analyzer'));
      expect(analyzer.category, equals('test'));
    });

    test('returns expected result', () async {
      const issue = DiagnosticIssue(
        severity: Severity.error,
        code: 'ERR_001',
        title: 'Test error',
        description: 'A test error',
      );

      final result = DiagnosticResult(
        analyzerName: 'TestAnalyzer',
        status: CheckStatus.failed,
        issues: [issue],
        duration: const Duration(seconds: 1),
        timestamp: DateTime(2024, 6, 15),
      );

      final context = AnalyzerContext(
        projectPath: '/test',
        fileSystem: MockFileSystem(),
      );

      final analyzer = TestAnalyzer(result);
      final output = await analyzer.analyze(context);

      expect(output.analyzerName, equals('TestAnalyzer'));
      expect(output.status, equals(CheckStatus.failed));
      expect(output.issues.length, equals(1));
      expect(output.issues.first.code, equals('ERR_001'));
    });
  });
}

class MockFileSystem extends Mock implements FileSystem {}
