import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/parsers/pubspec_parser.dart';

final class ProjectAnalyzer extends Analyzer {
  @override
  String get name => 'project';

  @override
  String get description => 'Analyzes Flutter project structure and metadata';

  @override
  String get category => 'project';

  @override
  Future<DiagnosticResult> analyze(AnalyzerContext context) async {
    final startTime = DateTime.now();
    final issues = <DiagnosticIssue>[];
    final fs = context.fileSystem;
    final projectPath = context.projectPath;

    final pubspecPath = fs.join(projectPath, 'pubspec.yaml');
    if (!fs.exists(pubspecPath)) {
      issues.add(DiagnosticIssue(
        severity: Severity.critical,
        code: 'MISSING_PUBSPEC',
        title: 'pubspec.yaml not found',
        description:
            'No pubspec.yaml found at $pubspecPath. This directory is not a Dart or Flutter project.',
        filePath: pubspecPath,
      ));
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.failed,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final pubspec = await PubspecParser.parseFromFile(pubspecPath, fs);
    if (pubspec == null) {
      issues.add(DiagnosticIssue(
        severity: Severity.critical,
        code: 'INVALID_PUBSPEC',
        title: 'pubspec.yaml is invalid',
        description:
            'The pubspec.yaml file could not be parsed. Check for YAML syntax errors.',
        filePath: pubspecPath,
      ));
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.failed,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    if (!pubspec.isFlutterProject) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'NOT_FLUTTER_PROJECT',
        title: 'Not a Flutter project',
        description:
            'This project does not declare a dependency on Flutter. Add flutter to dependencies.',
        filePath: pubspecPath,
      ));
    }

    final androidPath = fs.join(projectPath, 'android');
    if (!fs.exists(androidPath) || !fs.isDirectory(androidPath)) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'MISSING_ANDROID',
        title: 'Missing android/ directory',
        description:
            'No android/ directory found. Android platform support may not be configured.',
        filePath: projectPath,
      ));
    }

    final iosPath = fs.join(projectPath, 'ios');
    if (!fs.exists(iosPath) || !fs.isDirectory(iosPath)) {
      issues.add(DiagnosticIssue(
        severity: Severity.warning,
        code: 'MISSING_IOS',
        title: 'Missing ios/ directory',
        description:
            'No ios/ directory found. iOS platform support may not be configured.',
        filePath: projectPath,
      ));
    }

    final libPath = fs.join(projectPath, 'lib');
    if (!fs.exists(libPath) || !fs.isDirectory(libPath)) {
      issues.add(DiagnosticIssue(
        severity: Severity.error,
        code: 'MISSING_LIB',
        title: 'Missing lib/ directory',
        description:
            'No lib/ directory found. Every Dart project needs a lib/ directory.',
        filePath: projectPath,
      ));
    }

    final testPath = fs.join(projectPath, 'test');
    if (!fs.exists(testPath) || !fs.isDirectory(testPath)) {
      issues.add(DiagnosticIssue(
        severity: Severity.info,
        code: 'MISSING_TEST',
        title: 'Missing test/ directory',
        description:
            'No test/ directory found. Consider adding tests to your project.',
        filePath: projectPath,
      ));
    }

    if (pubspec.flutterSdkConstraint != null) {
      issues.add(DiagnosticIssue(
        severity: Severity.info,
        code: 'FLUTTER_SDK_CONSTRAINT',
        title: 'Flutter SDK constraint',
        description: 'Flutter SDK constraint: ${pubspec.flutterSdkConstraint}',
        recommendation:
            'Ensure your Flutter SDK version satisfies this constraint.',
        filePath: pubspecPath,
      ));
    }

    final hasCriticalOrError = issues.any(
      (i) => i.severity == Severity.critical || i.severity == Severity.error,
    );
    final hasWarning = issues.any((i) => i.severity == Severity.warning);

    CheckStatus status;
    if (hasCriticalOrError) {
      status = CheckStatus.failed;
    } else if (hasWarning) {
      status = CheckStatus.warning;
    } else {
      status = CheckStatus.passed;
    }

    return DiagnosticResult(
      analyzerName: name,
      status: status,
      issues: issues,
      duration: DateTime.now().difference(startTime),
      timestamp: DateTime.now(),
    );
  }
}
