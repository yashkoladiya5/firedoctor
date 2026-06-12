import 'package:firedoctor/analyzers/analyzers.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/logging/logging.dart';
import 'package:firedoctor/shared/source_file_cache.dart';

class AnalyzerService {
  final List<Analyzer> _analyzers = [];
  final Logger logger;

  AnalyzerService({required this.logger});

  void register(Analyzer analyzer) {
    _analyzers.add(analyzer);
  }

  void registerAll(List<Analyzer> analyzers) {
    _analyzers.addAll(analyzers);
  }

  List<Analyzer> get registeredAnalyzers => List.unmodifiable(_analyzers);

  Future<List<DiagnosticResult>> runAll(
    AnalyzerContext context, {
    Logger? progressLogger,
  }) async {
    final cache = SourceFileCache(context.fileSystem);
    cache.scanProject(context.projectPath);
    final contextWithCache = AnalyzerContext(
      projectPath: context.projectPath,
      fileSystem: context.fileSystem,
      configuration: context.configuration,
      sourceFileCache: cache,
    );

    final results = <DiagnosticResult>[];
    for (final analyzer in _analyzers) {
      final result = await runAnalyzer(analyzer, contextWithCache,
          progressLogger: progressLogger);
      results.add(result);
    }
    return results;
  }

  Future<DiagnosticResult> runAnalyzer(
    Analyzer analyzer,
    AnalyzerContext context, {
    Logger? progressLogger,
  }) async {
    final log = progressLogger ?? logger;
    log.info('Running analyzer: ${analyzer.name}');
    final stopwatch = Stopwatch()..start();
    try {
      final result = await analyzer.analyze(context);
      stopwatch.stop();
      final timedResult = DiagnosticResult(
        analyzerName: result.analyzerName,
        status: result.status,
        issues: result.issues,
        duration: stopwatch.elapsed,
        timestamp: result.timestamp,
        projectName: result.projectName,
      );
      log.success(
          '${analyzer.name}: ${timedResult.status.label} (${timedResult.issueCount} issues)');
      return timedResult;
    } catch (e) {
      stopwatch.stop();
      log.error('${analyzer.name} failed: $e');
      return DiagnosticResult(
        analyzerName: analyzer.name,
        status: CheckStatus.failed,
        issues: [
          DiagnosticIssue(
            severity: Severity.error,
            code: 'ANALYZER_ERROR',
            title: 'Analyzer execution failed',
            description: e.toString(),
          ),
        ],
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
      );
    }
  }
}
