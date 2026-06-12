import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/services/analyzer_service.dart';
import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/filesystem/file_system_interface.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

class MockAnalyzer extends Mock implements Analyzer {}

class MockTerminal extends Mock implements Terminal {}

class MockFileSystem extends Mock implements FileSystem {}

void main() {
  late MockTerminal terminal;
  late Logger logger;
  late AnalyzerService service;

  setUpAll(() {
    registerFallbackValue(
      AnalyzerContext(projectPath: '', fileSystem: MockFileSystem()),
    );
  });

  setUp(() {
    terminal = MockTerminal();
    logger = Logger(terminal: terminal);
    service = AnalyzerService(logger: logger);
  });

  group('AnalyzerService', () {
    group('register', () {
      test('adds an analyzer', () {
        final analyzer = MockAnalyzer();
        when(() => analyzer.name).thenReturn('test');
        service.register(analyzer);
        expect(service.registeredAnalyzers.length, equals(1));
        expect(service.registeredAnalyzers.first.name, equals('test'));
      });
    });

    group('registerAll', () {
      test('adds multiple analyzers', () {
        final a1 = MockAnalyzer();
        final a2 = MockAnalyzer();
        when(() => a1.name).thenReturn('a1');
        when(() => a2.name).thenReturn('a2');
        service.registerAll([a1, a2]);
        expect(service.registeredAnalyzers.length, equals(2));
      });
    });

    group('registeredAnalyzers', () {
      test('returns unmodifiable list', () {
        final analyzer = MockAnalyzer();
        when(() => analyzer.name).thenReturn('test');
        service.register(analyzer);
        expect(
          () => service.registeredAnalyzers.add(analyzer),
          throwsA(isA<Error>()),
        );
      });
    });

    group('runAnalyzer', () {
      test('returns DiagnosticResult on success', () async {
        final analyzer = MockAnalyzer();
        when(() => analyzer.name).thenReturn('TestAnalyzer');
        when(() => analyzer.description).thenReturn('Test');
        when(() => analyzer.category).thenReturn('test');

        final context = AnalyzerContext(
          projectPath: '/test',
          fileSystem: MockFileSystem(),
        );

        final result = DiagnosticResult(
          analyzerName: 'TestAnalyzer',
          status: CheckStatus.passed,
          issues: [],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );

        when(() => analyzer.analyze(any())).thenAnswer((_) async => result);
        when(() => terminal.writeInfo(any())).thenReturn(null);
        when(() => terminal.writeSuccess(any())).thenReturn(null);

        final output = await service.runAnalyzer(analyzer, context);
        expect(output.analyzerName, equals('TestAnalyzer'));
        expect(output.status, equals(CheckStatus.passed));
      });

      test('handles exceptions and returns error result', () async {
        final analyzer = MockAnalyzer();
        when(() => analyzer.name).thenReturn('FailingAnalyzer');
        when(() => analyzer.description).thenReturn('Failing');
        when(() => analyzer.category).thenReturn('test');

        final context = AnalyzerContext(
          projectPath: '/test',
          fileSystem: MockFileSystem(),
        );

        when(
          () => analyzer.analyze(any()),
        ).thenThrow(Exception('Something broke'));
        when(() => terminal.writeInfo(any())).thenReturn(null);
        when(() => terminal.writeError(any())).thenReturn(null);

        final output = await service.runAnalyzer(analyzer, context);
        expect(output.analyzerName, equals('FailingAnalyzer'));
        expect(output.status, equals(CheckStatus.failed));
        expect(output.issues.length, equals(1));
        expect(output.issues.first.code, equals('ANALYZER_ERROR'));
      });
    });

    group('runAll', () {
      test('runs all registered analyzers', () async {
        final a1 = MockAnalyzer();
        final a2 = MockAnalyzer();

        when(() => a1.name).thenReturn('Analyzer1');
        when(() => a1.description).thenReturn('First');
        when(() => a1.category).thenReturn('test');

        when(() => a2.name).thenReturn('Analyzer2');
        when(() => a2.description).thenReturn('Second');
        when(() => a2.category).thenReturn('test');

        final fs = MockFileSystem();
        when(() => fs.join(any(), any())).thenReturn('/test/lib');
        when(() => fs.exists(any())).thenReturn(false);
        when(() => fs.isDirectory(any())).thenReturn(false);

        final context = AnalyzerContext(projectPath: '/test', fileSystem: fs);

        final result1 = DiagnosticResult(
          analyzerName: 'Analyzer1',
          status: CheckStatus.passed,
          issues: [],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );

        final result2 = DiagnosticResult(
          analyzerName: 'Analyzer2',
          status: CheckStatus.passed,
          issues: [],
          duration: Duration.zero,
          timestamp: DateTime(2024, 1, 1),
        );

        when(() => a1.analyze(any())).thenAnswer((_) async => result1);
        when(() => a2.analyze(any())).thenAnswer((_) async => result2);
        when(() => terminal.writeInfo(any())).thenReturn(null);
        when(() => terminal.writeSuccess(any())).thenReturn(null);

        service.registerAll([a1, a2]);
        final results = await service.runAll(context);

        expect(results.length, equals(2));
        verify(() => a1.analyze(any())).called(1);
        verify(() => a2.analyze(any())).called(1);
      });
    });
  });
}
