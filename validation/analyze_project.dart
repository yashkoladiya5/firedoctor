/// Script to run all analyzers against a project and report findings.
/// Usage: dart run validation/analyze_project.dart <project-path>
import 'dart:io';
import 'package:firedoctor/firedoctor.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run validation/analyze_project.dart <project-path>');
    exit(1);
  }

  final projectPath = args[0];
  const fileSystem = LocalFileSystem();

  if (!fileSystem.exists(projectPath)) {
    stderr.writeln('Project not found: $projectPath');
    exit(1);
  }

  // Create analyzer service with all 7 analyzers
  final analyzerService = AnalyzerService(logger: Logger(terminal: AnsiTerminal()));
  analyzerService.register(ProjectAnalyzer());
  analyzerService.register(DependencyAnalyzer());
  analyzerService.register(FirebaseCoreAnalyzer());
  analyzerService.register(AndroidAnalyzer());
  analyzerService.register(IOSAnalyzer());
  analyzerService.register(FCMAnalyzer());
  analyzerService.register(CrashlyticsAnalyzer());

  final context = AnalyzerContext(
    projectPath: projectPath,
    fileSystem: fileSystem,
  );

  final stopwatch = Stopwatch()..start();
  final results = await analyzerService.runAll(context);
  stopwatch.stop();

  print('Results for: $projectPath');
  print('Execution time: ${stopwatch.elapsedMilliseconds}ms');
  print('');

  var totalIssues = 0;
  for (final result in results) {
    final issues = result.issues;
    totalIssues += issues.length;
    print('${result.analyzerName} (${result.status.label}): ${issues.length} issues in ${result.duration.inMilliseconds}ms');
    for (final issue in issues) {
      print('  [${issue.severity.name.toUpperCase().padRight(8)}] ${issue.code}: ${issue.title}');
    }
  }

  print('');
  print('Total issues: $totalIssues');
}
