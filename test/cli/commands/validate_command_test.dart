import 'dart:convert';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/cli/commands/validate_command.dart';
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

  late MockAnalyzerService analyzerService;
  late Logger logger;
  late ValidateCommand command;

  group('ValidateCommand', () {
    setUp(() {
      analyzerService = MockAnalyzerService();
    });

    test('executes successfully with valid projects directory', () async {
      final terminal = FakeTerminal();
      final fileSystem = FakeFileSystem();
      logger = Logger(terminal: terminal);

      const projectsDir = '/test_projects';
      fileSystem.addDirectory(projectsDir);
      fileSystem.addDirectory('$projectsDir/app1');
      fileSystem.addFile(
        '$projectsDir/app1/expected_findings.json',
        jsonEncode({
          'projectName': 'app1',
          'expectedFindings': [
            {
              'analyzerName': 'project',
              'code': 'FD101',
              'shouldBeFound': true,
            },
          ],
        }),
      );

      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'FD101',
                  title: 'Missing pubspec',
                  description: 'pubspec.yaml not found',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      command = ValidateCommand(
        logger: logger,
        terminal: terminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      final exitCode = await command.execute([projectsDir]);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      expect(terminal.buffer.toString(), contains('Validation complete'));
    });

    test('returns exitInternalFailure when projects dir does not exist',
        () async {
      final terminal = MockTerminal();
      final fileSystem = MockFileSystem();
      logger = Logger(terminal: terminal);

      when(() => terminal.writeError(any())).thenReturn(null);
      when(() => terminal.writeLine(any())).thenReturn(null);
      when(() => fileSystem.exists(any())).thenReturn(false);
      when(() => fileSystem.isDirectory(any())).thenReturn(false);
      when(() => fileSystem.currentDirectory).thenReturn('/cwd');
      when(() => fileSystem.join(any(), any(), any()))
          .thenReturn('/cwd/validation/projects');

      command = ValidateCommand(
        logger: logger,
        terminal: terminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      final exitCode = await command.execute(['/nonexistent']);

      expect(exitCode, equals(AppConstants.exitInternalFailure));
      verify(() => terminal.writeError(any())).called(1);
    });

    test('handles --output flag for saving report', () async {
      final terminal = FakeTerminal();
      final fileSystem = FakeFileSystem();
      logger = Logger(terminal: terminal);

      const projectsDir = '/test_projects';
      fileSystem.addDirectory(projectsDir);
      fileSystem.addDirectory('$projectsDir/app1');
      fileSystem.addFile(
        '$projectsDir/app1/expected_findings.json',
        jsonEncode({
          'projectName': 'app1',
          'expectedFindings': [
            {
              'analyzerName': 'project',
              'code': 'FD101',
              'shouldBeFound': true,
            },
          ],
        }),
      );

      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'FD101',
                  title: 'Missing pubspec',
                  description: 'pubspec.yaml not found',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      command = ValidateCommand(
        logger: logger,
        terminal: terminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      const outputPath = '/tmp/report.json';
      final exitCode =
          await command.execute(['--output', outputPath, projectsDir]);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      expect(terminal.buffer.toString(),
          contains('Report saved to: $outputPath'));
      expect(fileSystem.exists(outputPath), isTrue);
      final savedJson = jsonDecode(fileSystem.readAsString(outputPath));
      expect(savedJson, isA<Map<String, dynamic>>());
    });

    test('reports accuracy/precision metrics in output', () async {
      final terminal = FakeTerminal();
      final fileSystem = FakeFileSystem();
      logger = Logger(terminal: terminal);

      const projectsDir = '/test_projects';
      fileSystem.addDirectory(projectsDir);
      fileSystem.addDirectory('$projectsDir/app1');
      fileSystem.addFile(
        '$projectsDir/app1/expected_findings.json',
        jsonEncode({
          'projectName': 'app1',
          'expectedFindings': [
            {
              'analyzerName': 'project',
              'code': 'FD101',
              'shouldBeFound': true,
            },
          ],
        }),
      );

      when(() => analyzerService.runAll(any())).thenAnswer((_) async => [
            DiagnosticResult(
              analyzerName: 'project',
              status: CheckStatus.passed,
              issues: [
                const DiagnosticIssue(
                  severity: Severity.warning,
                  code: 'FD101',
                  title: 'Missing pubspec',
                  description: 'pubspec.yaml not found',
                ),
              ],
              duration: Duration.zero,
              timestamp: DateTime.now(),
            ),
          ]);

      command = ValidateCommand(
        logger: logger,
        terminal: terminal,
        fileSystem: fileSystem,
        analyzerService: analyzerService,
      );

      final exitCode = await command.execute([projectsDir]);

      expect(exitCode, equals(AppConstants.exitNoIssues));
      final output = terminal.buffer.toString();
      expect(output, contains('Accuracy'));
      expect(output, contains('Precision'));
      expect(output, contains('Recall'));
      expect(output, contains('Overall Metrics'));
      expect(output, contains('True Positives'));
      expect(output, contains('False Positives'));
      expect(output, contains('False Negatives'));
      expect(output, contains('Per-Analyzer Precision'));
      expect(output, contains('Per-Analyzer Recall'));
    });
  });
}
