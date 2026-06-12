# FireDoctor Architecture

FireDoctor follows a **plugin-based analyzer architecture** with a layered design. The tool is organized into CLI commands, services, models, and abstraction layers that make it testable, extensible, and maintainable.

## High-Level Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      CLI Layer                               │
│  CommandRunner → Help | Version | Diagnose | Doctor | Report │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Services Layer                             │
│  ┌──────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │ Analyzer     │  │ Health Score     │  │ Report        │  │
│  │ Service      │  │ Engine           │  │ Service       │  │
│  └──────┬───────┘  └──────────────────┘  └───────┬───────┘  │
│         │                                         │          │
└─────────┼─────────────────────────────────────────┼──────────┘
          │                                         │
          ▼                                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Analyzer Plugin Layer                        │
│  ┌───────┐ ┌────┐ ┌────┐ ┌──────┐ ┌────┐ ┌────┐ ┌────────┐ │
│  │Project│ │Dep │ │Core│ │Android│ │iOS │ │FCM │ │Crashlyt│ │
│  └───────┘ └────┘ └────┘ └──────┘ └────┘ └────┘ └────────┘ │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     Models Layer                              │
│  DiagnosticReport | DiagnosticResult | DiagnosticIssue        │
│  HealthScore | CategoryScore | Recommendation | Severity      │
│  CheckStatus | ScoreWeights | Pubspec | PriorityGroup         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Abstraction Layer                             │
│  FileSystem (interface)  │  Terminal (interface)  │  Logger   │
│  LocalFileSystem         │  AnsiTerminal          │           │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

```
User Input (args)
    │
    ▼
CommandRunner.run(args)
    │
    ├──► HelpCommand          → prints usage
    ├──► VersionCommand       → prints version
    ├──► DiagnoseCommand      → runAll analyzers → print issues → exit(code)
    ├──► DoctorCommand        → runAll analyzers → generateReport → printReport
    │                            → check --min-score → check --fail-on → exit(code)
    └──► ReportCommand        → runAll analyzers → generateReport → toJson/saveReport
                                 → check --min-score → check --fail-on → exit(code)

AnalyzerService.runAll(context)
    │
    ├──► ProjectAnalyzer.analyze(context)
    ├──► DependencyAnalyzer.analyze(context)
    ├──► FirebaseCoreAnalyzer.analyze(context)
    ├──► AndroidAnalyzer.analyze(context)
    ├──► IOSAnalyzer.analyze(context)
    ├──► FCMAnalyzer.analyze(context)
    └──► CrashlyticsAnalyzer.analyze(context)
    │
    ▼
List<DiagnosticResult>
    │
    ▼
ReportService.generateReport(results) → DiagnosticReport
    │
    ▼
HealthScoreEngine.compute(report) → HealthScore
    │
    ├── _computeCategoryScores()
    ├── _buildPriorityGroups()
    ├── _generateRecommendations()
    └── _computeOverallScore()
```

## Analyzer Plugin Architecture

All analyzers extend the `Analyzer` abstract class:

```dart
abstract class Analyzer {
  String get name;
  String get description;
  String get category;
  Future<DiagnosticResult> analyze(AnalyzerContext context);
}
```

Each analyzer receives an `AnalyzerContext` with:

- `projectPath` — The root path of the project being analyzed
- `fileSystem` — The FileSystem abstraction for reading files
- `configuration` — Optional key-value configuration map

Analyzers are registered in `AnalyzerService`:

```dart
final analyzerService = AnalyzerService(logger: logger);
analyzerService.register(ProjectAnalyzer());
analyzerService.register(DependencyAnalyzer());
analyzerService.register(FirebaseCoreAnalyzer());
analyzerService.register(AndroidAnalyzer());
analyzerService.register(IOSAnalyzer());
analyzerService.register(FCMAnalyzer());
analyzerService.register(CrashlyticsAnalyzer());
```

### 7 Registered Analyzers

| Analyzer | `name` | Category | Code Range | Checks |
|----------|--------|----------|------------|--------|
| `ProjectAnalyzer` | `project` | Project | FD100 | pubspec.yaml, directory structure, Flutter detection |
| `DependencyAnalyzer` | `dependency` | Dependency | FD200 | Firebase package dependencies, version constraints |
| `FirebaseCoreAnalyzer` | `firebase_core` | Firebase Core | FD300 | Dart source scanning for initialization patterns |
| `AndroidAnalyzer` | `android` | Android | FD400 | google-services.json, build.gradle, AndroidManifest.xml |
| `IOSAnalyzer` | `ios` | iOS | FD500 | GoogleService-Info.plist, Podfile, Xcode capabilities |
| `FCMAnalyzer` | `fcm` | FCM | FD600 | messaging dependency, Dart usage, iOS proxy settings |
| `CrashlyticsAnalyzer` | `crashlytics` | Crashlytics | FD700 | dependency, Dart usage, Gradle plugin, CocoaPods, dSYM |

### iOS Parsers

The iOS analyzer delegates file parsing to specialized parsers:

| Parser | Input File | Key Outputs |
|--------|-----------|-------------|
| `PlistParser` | `GoogleService-Info.plist`, `Info.plist` | Bundle ID, background modes, Firebase proxy setting |
| `PodfileParser` | `Podfile` | iOS platform version, Firebase pods, Runner target |
| `PodfileLockParser` | `Podfile.lock` | Installed Firebase pod list |
| `PbxprojParser` | `project.pbxproj` | Bundle identifier, push capability, background modes |

## CLI Command Layer

### Command Base Class

```dart
abstract class Command {
  String get name;
  String get description;
  List<String> get aliases => [];
  Future<int> execute(List<String> args);
}
```

### CommandRunner

The `CommandRunner` parses the first argument as the command name and delegates to the matching `Command.execute()`. It supports command lookup by name or alias.

```
No args         → printUsage()
"help"          → HelpCommand
"version" / "v" → VersionCommand
"diagnose"      → DiagnoseCommand
"doctor"        → DoctorCommand
"report"        → ReportCommand
unknown         → printUsage() + exit(4)
```

### 5 Commands

| Command | Aliases | Purpose | Key Behavior |
|---------|---------|---------|-------------|
| `HelpCommand` | `h`, `-h`, `--help` | Show usage | Delegates to `CommandRunner.printUsage()` or shows command-specific help |
| `VersionCommand` | `v`, `-v`, `--version` | Show version | Prints `FireDoctor v{version}` |
| `DiagnoseCommand` | — | Lightweight diagnostics | Runs analyzers, prints issues per analyzer, computes exit code |
| `DoctorCommand` | — | Full health check | Runs analyzers, generates report, prints with health score, checks `--fail-on` and `--min-score` |
| `ReportCommand` | — | Detailed report | Runs analyzers, generates report, supports `--json` and `--output` flags |

### Flag Parsing

Flags are parsed manually (no `args` package `CommandRunner` subclass — raw `List<String>` iteration):

- `--fail-on <severity>` — `warning`/`warn`, `error`, `critical` (default: `error`)
- `--min-score <0-100>` — Double between 0 and 100
- `--json` — Toggle JSON output (report only)
- `--output <path>` — Save report to file (report only)
- Positional first arg — Project path (defaults to current directory)

## Services Layer

### AnalyzerService

Manages analyzer registration and execution.

```dart
class AnalyzerService {
  void register(Analyzer analyzer);
  void registerAll(List<Analyzer> analyzers);
  Future<List<DiagnosticResult>> runAll(AnalyzerContext context);
  Future<DiagnosticResult> runAnalyzer(Analyzer analyzer, AnalyzerContext context);
}
```

`runAll` iterates registered analyzers sequentially, captures timing, wraps exceptions, and returns a list of `DiagnosticResult`. If an analyzer throws an exception, a synthetic `DiagnosticResult` with status `failed` and an `ANALYZER_ERROR` issue is returned, ensuring the overall run continues.

### HealthScoreEngine

Computes the health score from a `DiagnosticReport`.

```dart
class HealthScoreEngine {
  HealthScore compute(DiagnosticReport report);
  HealthScore computeFromResults(List<DiagnosticResult> results);
}
```

Internal computation pipeline:

1. `_computeCategoryScores()` — Per-analyzer score based on weighted issues
2. `_buildPriorityGroups()` — Groups issues into Critical/High/Medium/Low
3. `_computeTotalWeight()` — Sum of all issue weights
4. `_computeMaxPossibleWeight()` — Maximum possible weight for normalization
5. `_computeOverallScore()` — Weighted average across categories
6. `_generateRecommendations()` — Top N issues sorted by weight

### ReportService

Generates, prints, and exports diagnostic reports.

```dart
class ReportService {
  DiagnosticReport generateReport({results, projectName, projectPath, ...});
  void printReport(DiagnosticReport report);
  String toJson(DiagnosticReport report);
  Future<void> saveReport(DiagnosticReport report, FileSystem fs, String path);
}
```

## Models Layer

### Core Models

| Model | Fields | Purpose |
|-------|--------|---------|
| `DiagnosticReport` | `projectName`, `projectPath`, `createdAt`, `results`, `firebaseVersion`, `environment`, `healthScore` | Aggregate report with computed properties (`score`, `passed`, `exitCode`, `mostSevereRank`) |
| `DiagnosticResult` | `analyzerName`, `status`, `issues`, `duration`, `timestamp`, `projectName` | Output from a single analyzer |
| `DiagnosticIssue` | `severity`, `code`, `title`, `description`, `recommendation`, `filePath`, `lineNumber`, `metadata` | A single identified issue |
| `HealthScore` | `overallScore`, `categoryScores`, `priorityGroups`, `recommendations`, `totalWeight`, `maxPossibleWeight`, `weights` | Computed health score with breakdown |
| `CategoryScore` | `category`, `displayName`, `score`, `totalIssues`, `totalWeight` | Per-analyzer score |
| `Recommendation` | `code`, `title`, `severity`, `weight` | Actionable recommendation |
| `ScoreWeights` | `critical`, `error`, `warning`, `info` (defaults: 25, 15, 5, 1) | Configurable severity weights |

### Severity Model (Sealed Class)

```dart
sealed class Severity implements Comparable<Severity> {
  static const info = _SeverityInfo();      // value = 0
  static const warning = _SeverityWarning(); // value = 1
  static const error = _SeverityError();     // value = 2
  static const critical = _SeverityCritical(); // value = 3
}
```

### CheckStatus Model (Sealed Class)

```dart
sealed class CheckStatus {
  static const passed = _CheckStatusPassed();
  static const failed = _CheckStatusFailed();
  static const warning = _CheckStatusWarning();
  static const skipped = _CheckStatusSkipped();
  static const notApplicable = _CheckStatusNotApplicable();
}
```

### Priority Groups

```dart
enum PriorityGroup {
  critical('Critical Fixes'),    // from severity critical
  high('High Priority'),         // from severity error
  medium('Medium Priority'),     // from severity warning
  low('Low Priority'),           // from severity info
}
```

## Abstraction Layers

### FileSystem Interface

Abstracts file system operations for testability:

```dart
abstract class FileSystem {
  bool exists(String path);
  String readAsString(String path);
  Future<String> readAsStringAsync(String path);
  void writeAsString(String path, String content);
  List<String> listDirectory(String path);
  bool isDirectory(String path);
  bool isFile(String path);
  String get currentDirectory;
  String join(String part1, [String? part2, String? part3]);
  // ...
}
```

- `LocalFileSystem` — Real implementation using `dart:io`
- In tests, mocked with `mocktail`

### Terminal Interface

Abstracts console output for testability:

```dart
abstract class Terminal {
  void write(String message);
  void writeLine(String message);
  void writeSuccess(String message);
  void writeWarning(String message);
  void writeError(String message);
  void writeInfo(String message);
  String? readLine();
  void clear();
}
```

- `AnsiTerminal` — Real implementation using `stdout`/`stderr`
- In tests, mocked with `mocktail`

### Logger

Thin logging wrapper over Terminal:

```dart
class Logger {
  void info(String message);
  void success(String message);
  void warning(String message);
  void error(String message);
  void header(String title);
  void blank();
}
```

## Error Handling Strategy

FireDoctor uses a `FireDoctorException` class for fatal errors:

```dart
class FireDoctorException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;
}
```

The error handling strategy follows three levels:

1. **CLI argument errors** (invalid flags, missing paths) — Caught in command `execute()`, printed to stderr, exit code 4
2. **Analyzer runtime errors** — Caught by `AnalyzerService.runAnalyzer()`, wrapped into a synthetic `DiagnosticResult` with status `failed`, allowing other analyzers to continue
3. **Catastrophic failures** — Uncaught exceptions propagate to `runFireDoctor()` → `exit(4)`

## JSON Schema

The `report --json` command outputs a JSON object with this schema:

### Top-level Fields

| Field | Type | Always Present | Description |
|-------|------|----------------|-------------|
| `schemaVersion` | String | Yes | Schema version (`1.0.0`) |
| `firedoctorVersion` | String | Yes | Tool version (`0.1.0`) |
| `generatedAt` | String (ISO 8601) | Yes | UTC timestamp of report generation |
| `projectName` | String | Yes | Name from pubspec.yaml |
| `projectPath` | String | Yes | Absolute path to the analyzed project |
| `createdAt` | String (ISO 8601) | Yes | Timestamp from project analysis |
| `score` | Double | Yes | Simple score (0.0–100.0) |
| `passed` | Boolean | Yes | Whether all checks passed |
| `exitCode` | Integer | Yes | Deterministic exit code (0–4) |
| `mostSevereRank` | Integer | Yes | Highest severity rank detected (0–4) |
| `totalIssues` | Integer | Yes | Total number of issues |
| `totalErrors` | Integer | Yes | Count of error + critical issues |
| `totalWarnings` | Integer | Yes | Count of warning issues |
| `environment` | Object | Yes | Environment metadata |
| `firebaseVersion` | String | No | Firebase version if detected |
| `analyzerResults` | Array | Yes | Per-analyzer results |
| `healthScore` | Object | No | Health score when computed |
| `categoryScores` | Array | No | Per-category health scores |
| `recommendations` | Array | No | Top recommendations |

### Per-Analyzer Result

| Field | Type | Description |
|-------|------|-------------|
| `analyzerName` | String | Name of the analyzer |
| `status` | String | Status: `passed`, `failed`, `warning`, `skipped`, `not_applicable` |
| `duration` | Integer | Execution time in milliseconds |
| `timestamp` | String (ISO 8601) | When the analyzer ran |
| `issueCount` | Integer | Total issues found |
| `errorCount` | Integer | Error + critical issues |
| `warningCount` | Integer | Warning issues |
| `mostSevereRank` | Integer | Highest severity rank (0–4) |
| `issues` | Array | List of issues |

### Issue Object

| Field | Type | Always Present | Description |
|-------|------|----------------|-------------|
| `severity` | String | Yes | `info`, `warning`, `error`, `critical` |
| `code` | String | Yes | Diagnostic code (e.g. `FD400`) |
| `title` | String | Yes | Short title |
| `description` | String | Yes | Detailed description |
| `recommendation` | String | No | Suggested fix |
| `filePath` | String | No | Affected file path |
| `lineNumber` | Integer | No | Affected line number |

### Health Score Object

| Field | Type | Description |
|-------|------|-------------|
| `overallScore` | Double | Overall score (0.0–100.0) |
| `totalIssues` | Integer | Total issues counted |
| `totalWeight` | Integer | Sum of all issue weights |
| `maxPossibleWeight` | Integer | Maximum possible weight |
| `categoryScores` | Array | Per-category score objects |
| `priorityGroups` | Object | Issues grouped by priority |
| `recommendations` | Array | Top recommendations |

## Testing Strategy

FireDoctor has **692 unit tests** using `test` + `mocktail`.

### Test Structure

```
test/
├── analyzers/          # Tests for all 7 analyzers + iOS parsers
├── cli/commands/       # Tests for all 5 CLI commands
├── models/             # Tests for all model classes
├── services/           # Tests for service classes
├── filesystem/         # Tests for file system abstraction
├── terminal/           # Tests for terminal abstraction
├── logging/            # Tests for logger
├── parsers/            # Tests for pubspec parser
├── exceptions/         # Tests for FireDoctorException
├── shared/             # Shared mock definitions
└── integration/        # Integration tests
```

### Testing Principles

- **Analyzers** — Test with mocked `FileSystem` and known input files
- **CLI Commands** — Test argument parsing, flag handling, exit codes
- **Models** — Test serialization, computed properties, edge cases
- **Services** — Test report generation, health score computation, JSON output
- **Abstractions** — Test that mock implementations satisfy interface contracts
- **iOS Parsers** — Test with real plist, podfile, pbxproj fixtures

## Project Directory Tree

```
firedoctor-flutter/
├── bin/
│   ├── firedoctor.dart          # CLI entry point
│   └── firedoctor.dill          # Compiled Dart kernel
├── lib/
│   ├── firedoctor.dart          # Main export + runFireDoctor()
│   ├── analyzers/
│   │   ├── analyzer.dart        # Abstract Analyzer base class
│   │   ├── analyzer_context.dart # Context passed to analyzers
│   │   ├── analyzer_result.dart  # Result model (deprecated?)
│   │   ├── analyzers.dart        # Barrel export
│   │   ├── project/
│   │   │   └── project_analyzer.dart
│   │   ├── dependency/
│   │   │   ├── dependency_analyzer.dart
│   │   │   └── firebase_package.dart
│   │   ├── firebase_core/
│   │   │   └── firebase_core_analyzer.dart
│   │   ├── android/
│   │   │   └── android_analyzer.dart
│   │   ├── ios/
│   │   │   ├── ios_analyzer.dart
│   │   │   └── parsers/
│   │   │       ├── plist_parser.dart
│   │   │       ├── podfile_parser.dart
│   │   │       ├── podfile_lock_parser.dart
│   │   │       └── pbxproj_parser.dart
│   │   ├── fcm/
│   │   │   └── fcm_analyzer.dart
│   │   └── crashlytics/
│   │       └── crashlytics_analyzer.dart
│   ├── cli/
│   │   ├── command.dart         # Abstract Command base class
│   │   ├── command_runner.dart   # CLI command dispatcher
│   │   ├── cli.dart             # Barrel export
│   │   └── commands/
│   │       ├── help_command.dart
│   │       ├── version_command.dart
│   │       ├── diagnose_command.dart
│   │       ├── doctor_command.dart
│   │       └── report_command.dart
│   ├── constants/
│   │   ├── app_constants.dart   # Versions, exit codes, exitCodeForSeverityRank()
│   │   └── constants.dart       # Barrel export
│   ├── exceptions/
│   │   ├── fire_doctor_exception.dart
│   │   └── exceptions.dart      # Barrel export
│   ├── filesystem/
│   │   ├── file_system_interface.dart
│   │   ├── local_file_system.dart
│   │   └── filesystem.dart      # Barrel export
│   ├── logging/
│   │   ├── logger.dart
│   │   └── logging.dart         # Barrel export
│   ├── models/
│   │   ├── severity.dart        # Sealed class (info/warning/error/critical)
│   │   ├── check_status.dart    # Sealed class (passed/failed/warning/skipped/na)
│   │   ├── diagnostic_issue.dart
│   │   ├── diagnostic_result.dart
│   │   ├── diagnostic_report.dart
│   │   ├── pubspec.dart         # Parsed pubspec model
│   │   ├── score_weights.dart   # Configurable scoring weights
│   │   ├── health_score.dart    # HealthScore + CategoryScore + Recommendation + PriorityGroup
│   │   └── models.dart          # Barrel export
│   ├── parsers/
│   │   ├── pubspec_parser.dart  # YAML parsing of pubspec.yaml
│   │   └── parsers.dart         # Barrel export
│   ├── services/
│   │   ├── analyzer_service.dart
│   │   ├── health_score_engine.dart
│   │   ├── report_service.dart
│   │   └── services.dart        # Barrel export
│   ├── terminal/
│   │   ├── terminal_interface.dart
│   │   ├── ansi_terminal.dart
│   │   └── terminal.dart        # Barrel export
│   └── utils/
│       ├── utils.dart           # Empty placeholder
│       └── utils.dart           # Barrel export
├── test/
│   ├── analyzers/
│   │   ├── project/
│   │   ├── dependency/
│   │   ├── firebase_core/
│   │   ├── android/
│   │   ├── ios/
│   │   │   └── parsers/
│   │   ├── fcm/
│   │   └── crashlytics/
│   ├── cli/commands/
│   ├── models/
│   ├── services/
│   ├── filesystem/
│   ├── terminal/
│   ├── logging/
│   ├── parsers/
│   ├── exceptions/
│   ├── shared/
│   └── integration/
├── pubspec.yaml
├── analysis_options.yaml
├── LICENSE
└── README.md
```
