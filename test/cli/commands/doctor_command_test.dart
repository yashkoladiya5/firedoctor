import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/cli/commands/doctor_command.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/constants/app_constants.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/services/analyzer_service.dart';
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
  late DoctorCommand command;

  setUp(() {
    terminal = MockTerminal();
    fileSystem = MockFileSystem();
    analyzerService = MockAnalyzerService();
    logger = Logger(terminal: terminal);

    when(() => terminal.writeLine(any())).thenReturn(null);
    when(() => terminal.writeError(any())).thenReturn(null);
    when(() => terminal.writeSuccess(any())).thenReturn(null);
    when(() => terminal.writeInfo(any())).thenReturn(null);

    command = DoctorCommand(
      logger: logger,
      terminal: terminal,
      fileSystem: fileSystem,
      analyzerService: analyzerService,
    );
  });

  group('DoctorCommand', () {
    test('returns exitFailure when project path does not exist', () async {
      when(() => fileSystem.exists('/invalid')).thenReturn(false);

      final exitCode = await command.execute(['/invalid']);

      expect(exitCode, equals(AppConstants.exitFailure));
      verify(() => terminal.writeError(any())).called(1);
    });

    test('returns exitFailure when path is not a directory', () async {
      when(() => fileSystem.exists('/file')).thenReturn(true);
      when(() => fileSystem.isDirectory('/file')).thenReturn(false);

      final exitCode = await command.execute(['/file']);

      expect(exitCode, equals(AppConstants.exitFailure));
    });

    test('returns exitSuccess when no issues found', () async {
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
            DiagnosticResult(
              analyzerName: 'dependency',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
            DiagnosticResult(
              analyzerName: 'firebase_core',
              status: CheckStatus.passed,
              issues: [],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await command.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitSuccess));
    });

    test('returns exitSuccess when only warning issues present', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.warning,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'MISSING_TEST',
                  title: 'Missing test directory',
                  description: 'No test/ directory found.',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await command.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitSuccess));
    });

    test('returns exitFailure when critical issues present', () async {
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

      expect(exitCode, equals(AppConstants.exitFailure));
    });

    test('returns exitFailure when error issues present', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'dependency',
              status: CheckStatus.failed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.error,
                  code: 'FD200',
                  title: 'Missing dependency',
                  description: 'firebase_core not found.',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await command.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitFailure));
    });

    test('returns exitFailure when analyzer service throws', () async {
      when(() => fileSystem.exists('/project')).thenReturn(true);
      when(() => fileSystem.isDirectory('/project')).thenReturn(true);
      when(() => analyzerService.runAll(any()))
          .thenThrow(Exception('Unexpected error'));

      final exitCode = await command.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitFailure));
      verify(() => terminal.writeError(
          'Analysis failed: Exception: Unexpected error')).called(1);
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

      expect(exitCode, equals(AppConstants.exitSuccess));
      verify(() => fileSystem.exists('/cwd')).called(1);
    });

    test('prints formatted report', () async {
      final fakeTerminal = FakeTerminal();
      final cmd = DoctorCommand(
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
              status: CheckStatus.warning,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'MISSING_TEST',
                  title: 'Missing test directory',
                  description: 'No test/ directory found.',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      final exitCode = await cmd.execute(['/project']);

      expect(exitCode, equals(AppConstants.exitSuccess));
      expect(fakeTerminal.buffer.toString(),
          contains('FireDoctor Diagnostic Report'));
    });
  });
}
