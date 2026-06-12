import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/cli/commands/report_command.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(AnalyzerContext(
      projectPath: '',
      fileSystem: FakeFileSystem(),
    ));
  });

  late MockTerminal terminal;
  late MockFileSystem fileSystem;
  late MockAnalyzerService analyzerService;
  late Logger logger;
  late ReportCommand command;

  setUp(() {
    terminal = MockTerminal();
    fileSystem = MockFileSystem();
    analyzerService = MockAnalyzerService();
    logger = Logger(terminal: terminal);

    when(() => terminal.writeLine(any())).thenReturn(null);
    when(() => terminal.writeError(any())).thenReturn(null);
    when(() => terminal.writeSuccess(any())).thenReturn(null);
    when(() => terminal.writeInfo(any())).thenReturn(null);

    command = ReportCommand(
      logger: logger,
      terminal: terminal,
      fileSystem: fileSystem,
      analyzerService: analyzerService,
    );
  });

  group('ReportCommand', () {
    test('returns exitInternalFailure when project path does not exist', () async {
      when(() => fileSystem.exists('/invalid')).thenReturn(false);

      final exitCode = await command.execute(['/invalid']);

      expect(exitCode, equals(AppConstants.exitInternalFailure));
      verify(() => terminal.writeError('Project path does not exist: /invalid'))
          .called(1);
    });

    test('returns exitInternalFailure when path is not a directory', () async {
      when(() => fileSystem.exists('/file')).thenReturn(true);
      when(() => fileSystem.isDirectory('/file')).thenReturn(false);

      final exitCode = await command.execute(['/file']);

      expect(exitCode, equals(AppConstants.exitInternalFailure));
    });

    test('prints report on stdout with no flags', () async {
      final fakeTerminal = FakeTerminal();
      final cmd = ReportCommand(
        logger: Logger(terminal: fakeTerminal),
        terminal: fakeTerminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await cmd.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      expect(fakeTerminal.buffer.toString(),
          contains('FireDoctor Diagnostic Report'));
    });

    test('prints JSON when --json flag provided', () async {
      final fakeTerminal = FakeTerminal();
      final cmd = ReportCommand(
        logger: Logger(terminal: fakeTerminal),
        terminal: fakeTerminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await cmd.execute(['--json', '/project']);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      expect(fakeTerminal.buffer.toString(), contains('{'));
    });

    test('saves report to file with --output flag', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);
      when(() => fileSystem.writeAsStringAsync(any(), any()))
          .thenAnswer((_) async {});

      final exitCode =
          await command.execute(['--output', '/tmp/report.json', '/project']);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      verify(() => terminal.writeSuccess('Report saved to /tmp/report.json'))
          .called(1);
      verify(() => fileSystem.writeAsStringAsync('/tmp/report.json', any()))
          .called(1);
    });

    test('saves JSON report with --json --output flags combined', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);
      when(() => fileSystem.writeAsStringAsync(any(), any()))
          .thenAnswer((_) async {});

      final exitCode = await command.execute([
        '--json',
        '--output',
        '/tmp/report.json',
        '/project',
      ]);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      verify(() => terminal.writeSuccess('Report saved to /tmp/report.json'))
          .called(1);
      verify(() => fileSystem.writeAsStringAsync('/tmp/report.json', any()))
          .called(1);
    });

    test('uses projectName from results in report', () async {
      final fakeTerminal = FakeTerminal();
      final cmd = ReportCommand(
        logger: Logger(terminal: fakeTerminal),
        terminal: fakeTerminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
              projectName: 'my_app',
            ),
          ]);

      final exitCode = await cmd.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      expect(fakeTerminal.buffer.toString(), contains('Project: my_app'));
    });

    test('falls back to unknown when no projectName in results', () async {
      final fakeTerminal = FakeTerminal();
      final cmd = ReportCommand(
        logger: Logger(terminal: fakeTerminal),
        terminal: fakeTerminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await cmd.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      expect(fakeTerminal.buffer.toString(), contains('Project: unknown'));
    });

    test('uses current directory when no path argument given', () async {
      when(() => fileSystem.currentDirectory).thenReturn('/cwd');
      when(() => fileSystem.exists('/cwd')).thenReturn(true);
      when(() => fileSystem.isDirectory('/cwd')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await command.execute([]);

      expect(exitCode, equals(AppConstants.exitNoIssues));
    });

    test('returns exitInternalFailure when --output is missing value', () async {
      final exitCode = await command.execute(['--output']);

      expect(exitCode, equals(AppConstants.exitInternalFailure));
      verify(() => terminal.writeError('Missing value for --output flag'))
          .called(1);
    });

    test('returns exitInternalFailure when analyzer service throws', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any()))
          .thenThrow(Exception('Report failed'));

      final exitCode = await command.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitInternalFailure));
      verify(() => terminal.writeError(
          'Report generation failed: Exception: Report failed')).called(1);
    });

    test('returns exitCriticalIssues when critical issues found', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.failed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.critical,
                  code: 'MISSING_PUBSPEC',
                  title: 'pubspec.yaml not found',
                  description: 'No pubspec.yaml found.',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await command.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitCriticalIssues));
    });

    test('handles path after flags correctly', () async {
      when(() => fileSystem.exists('/my_project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/my_project')).thenReturn(true);
      when(() => fileSystem.writeAsStringAsync(any(), any()))
          .thenAnswer((_) async {});
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await command
          .execute(['--json', '--output', '/tmp/r.json', '/my_project']);

      expect(exitCode, equals(AppConstants.exitNoIssues));
    });
  });
}
