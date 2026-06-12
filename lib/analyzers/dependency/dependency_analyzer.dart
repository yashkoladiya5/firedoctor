import 'package:firedoctor/analyzers/analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import 'package:firedoctor/parsers/pubspec_parser.dart';
import 'firebase_package.dart';

/// Core class.
final class DependencyAnalyzer extends Analyzer {
  @override
  String get name => 'dependency';

  @override
  String get description => 'Analyzes Firebase dependencies in pubspec.yaml';

  @override
  String get category => 'dependency';

  @override
  /// Public method or function.
  Future<DiagnosticResult> analyze(AnalyzerContext context) async {
    final startTime = DateTime.now();
    final issues = <DiagnosticIssue>[];
    final fs = context.fileSystem;
    final projectPath = context.projectPath;
    final pubspecPath = fs.join(projectPath, 'pubspec.yaml');

    if (!fs.exists(pubspecPath)) {
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.skipped,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final pubspec = await PubspecParser.parseFromFile(pubspecPath, fs);
    if (pubspec == null) {
      return DiagnosticResult(
        analyzerName: name,
        status: CheckStatus.skipped,
        issues: issues,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    }

    final installed = <FirebasePackage>{};
    final devDependencyPackages = <FirebasePackage>{};
    final versionIssues = <String, String>{};

    for (final pkg in FirebasePackage.all) {
      if (pubspec.hasDependency(pkg.packageName)) {
        installed.add(pkg);
        final version = pubspec.dependencyVersion(pkg.packageName)!;
        if (_hasVersionIssue(version)) {
          versionIssues[pkg.packageName] = version;
        }
      }

      if (pubspec.hasDevDependency(pkg.packageName)) {
        devDependencyPackages.add(pkg);
        final version = pubspec.devDependencies[pkg.packageName]!;
        if (_hasVersionIssue(version)) {
          versionIssues[pkg.packageName] = version;
        }
      }
    }

    final allFirebasePkgs = installed.union(devDependencyPackages);
    final hasNonCore = allFirebasePkgs.any((p) => p != FirebasePackage.core);
    final hasCore = allFirebasePkgs.contains(FirebasePackage.core);

    if (hasNonCore && !hasCore) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.critical,
          code: 'FD200',
          title: 'Missing firebase_core',
          description:
              'Firebase packages are installed without firebase_core. '
              'firebase_core is required by all Firebase services.',
          recommendation:
              'Add firebase_core to your dependencies:\n'
              '  firebase_core: ^3.0.0',
          filePath: pubspecPath,
        ),
      );
    }

    for (final pkg in devDependencyPackages) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.error,
          code: 'FD201',
          title: '${pkg.displayName} in dev_dependencies',
          description:
              '${pkg.packageName} is placed in dev_dependencies. '
              'Firebase packages should be in dependencies.',
          recommendation:
              'Move ${pkg.packageName} from dev_dependencies to dependencies.',
          filePath: pubspecPath,
        ),
      );
    }

    for (final entry in versionIssues.entries) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.warning,
          code: 'FD202',
          title: 'Loose version constraint for ${entry.key}',
          description:
              '${entry.key} has a loose version constraint: "${entry.value}". '
              'This may lead to unexpected breaking changes.',
          recommendation:
              'Use a caret constraint like ^2.0.0 instead of "${entry.value}".',
          filePath: pubspecPath,
        ),
      );
    }

    final allPackageNames = installed.map((p) => p.packageName).toSet()
      ..addAll(devDependencyPackages.map((p) => p.packageName));

    final usesFirebase = hasCore || hasNonCore;
    if (usesFirebase && !allPackageNames.contains('firebase_analytics')) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.info,
          code: 'FD203',
          title: 'firebase_analytics not installed',
          description:
              'firebase_analytics is recommended for understanding user engagement. Consider adding if you need analytics.',
          recommendation:
              'Add firebase_analytics to your dependencies:\n  firebase_analytics: ^11.0.0',
          filePath: pubspecPath,
        ),
      );
    }

    if (usesFirebase && !allPackageNames.contains('cloud_firestore')) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.info,
          code: 'FD204',
          title: 'cloud_firestore not installed',
          description:
              'cloud_firestore is recommended for persistent data storage. Consider adding if you need Firestore.',
          recommendation:
              'Add cloud_firestore to your dependencies:\n  cloud_firestore: ^5.0.0',
          filePath: pubspecPath,
        ),
      );
    }

    if (usesFirebase && !allPackageNames.contains('firebase_auth')) {
      issues.add(
        DiagnosticIssue(
          severity: Severity.info,
          code: 'FD205',
          title: 'firebase_auth not installed',
          description:
              'firebase_auth is recommended for user authentication. Consider adding if you need Auth.',
          recommendation:
              'Add firebase_auth to your dependencies:\n  firebase_auth: ^5.0.0',
          filePath: pubspecPath,
        ),
      );
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

  bool _hasVersionIssue(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed == 'any') return true;
    if (trimmed == '*') return true;
    return false;
  }
}