# FireDoctor — Complete Project Documentation

> **Version:** 0.1.0  
> **Description:** Firebase diagnostics tool for Flutter projects  
> **SDK:** Dart `>=3.0.0 <4.0.0`  
> **License:** MIT  
> **Repository:** https://github.com/firedoctor-cli/firedoctor  

---

## 1. Project Summary

FireDoctor is a CLI tool that diagnoses Firebase configuration and setup issues in Flutter projects. It scans a Flutter project's structure, dependencies, platform configuration files (Android & iOS), Firebase Core initialization, Firebase Cloud Messaging (FCM) setup, and Crashlytics integration — reporting issues, computing a health score, and providing actionable recommendations. It is designed for CI/CD pipelines with deterministic exit codes, threshold flags, and machine-readable JSON output.

---

## 2. Project Overview

| Aspect | Details |
|--------|---------|
| **Package Name** | `firedoctor` |
| **Entry Point** | `bin/firedoctor.dart` → `lib/firedoctor.dart` → `runFireDoctor()` |
| **Architecture** | Plug-in Analyzer pattern with 7 analyzers, CLI command layer, services layer, and abstraction over filesystem/terminal |
| **Testing** | 692 unit tests, uses `test` + `mocktail` |
| **Linting** | `package:lints/recommended.yaml` with strict-casts, strict-inference, strict-raw-types |
| **Build Artifact** | `bin/firedoctor.dill` (compiled Dart kernel) |

### Dependencies

```yaml
dependencies:
  args: ^2.4.0
  meta: ^1.11.0
  path: ^1.9.0
  yaml: ^3.1.0
dev_dependencies:
  test: ^1.25.0
  mocktail: ^1.0.0
  lints: ^3.0.0
```

---

## 3. Project Features

### CLI Commands (5)

| Command | Description | Aliases | Exit Codes |
|---------|-------------|---------|------------|
| `help` | Shows help information for commands | `h`, `-h`, `--help` | 0, 4 |
| `version` | Prints the FireDoctor version | `v`, `-v`, `--version` | 0 |
| `diagnose` | Runs Firebase diagnostics (lightweight output) | — | 0, 1, 2, 3, 4 |
| `doctor` | Full FireDoctor check with health score | — | 0, 1, 2, 3, 4 |
| `report` | Generates detailed JSON/text report | — | 0, 1, 2, 3, 4 |

### Flags (doctor & report commands)

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--fail-on <severity>` | `warning`, `error`, `critical` | `error` | Fail CI if issues at or above this severity |
| `--min-score <0-100>` | Double | — | Fail CI if health score is below this threshold |

### CLI flags (report command only)

| Flag | Type | Description |
|------|------|-------------|
| `--json` | Flag | Output report as JSON to stdout |
| `--output <path>` | String | Save report JSON to file |

### Exit Codes (Deterministic)

| Code | Constant | Meaning |
|------|----------|---------|
| 0 | `exitNoIssues` | No issues found — all checks passed |
| 1 | `exitWarningsOnly` | Only warning-level issues found |
| 2 | `exitErrorsOnly` | Error-level issues found (no critical) |
| 3 | `exitCriticalIssues` | Critical issues found |
| 4 | `exitInternalFailure` | Internal failure (invalid args, path not found, crash) |

### JSON Output Schema (report command)

```json
{
  "schemaVersion": "1.0.0",
  "firedoctorVersion": "0.1.0",
  "generatedAt": "2026-06-12T04:59:46.592467Z",
  "projectName": "my_project",
  "projectPath": "/path/to/project",
  "createdAt": "2026-06-12T10:29:46.590279",
  "score": 66.7,
  "passed": false,
  "exitCode": 1,
  "mostSevereRank": 2,
  "totalIssues": 4,
  "totalErrors": 0,
  "totalWarnings": 4,
  "environment": {},
  "analyzerResults": [ ... ],
  "healthScore": { ... },
  "categoryScores": [ ... ],
  "recommendations": [ ... ]
}
```

### Health Score Engine

- Computed by `HealthScoreEngine` using `ScoreWeights`
- Category-level scores per analyzer
- Priority groups: Critical, High, Medium, Low
- Weighted scoring (critical=25, error=15, warning=5, info=1)
- Recommendations sorted by weight descending

---

## 4. Project Errors — Complete Diagnostic Codes

All **56 diagnostic codes** across 7 analyzers:

### Project Analyzer (FD100 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD100 | warning | Missing pubspec.yaml | Project does not contain a pubspec.yaml file |
| FD101 | error | Invalid pubspec.yaml | pubspec.yaml is not valid YAML |
| FD102 | info | Missing pubspec name field | pubspec.yaml is missing a "name" field |
| FD103 | info | Flutter SDK constraint | Flutter SDK constraint is not specified in pubspec.yaml |
| NOT_FLUTTER_PROJECT | warning | Not a Flutter project | Project does not declare a dependency on Flutter |
| MISSING_ANDROID | warning | Missing android/ directory | No android/ directory found |
| MISSING_IOS | warning | Missing ios/ directory | No ios/ directory found |
| MISSING_LIB | warning | Missing lib/ directory | No lib/ directory found |
| MISSING_TEST | info | Missing test/ directory | No test/ directory found |

### Dependency Analyzer (FD200 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD200 | warning | Missing firebase_core dependency | firebase_core is not declared in dependencies but other Firebase packages are present |
| FD201 | warning | Firebase package in dev_dependencies | Firebase packages should be in dependencies, not dev_dependencies |
| FD202 | info | Loose Firebase version constraint | Firebase dependency uses a loose version constraint |

### Firebase Core Analyzer (FD300 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD300 | error | Missing firebase_core dependency | firebase_core is not added to pubspec.yaml |
| FD301 | warning | Missing firebase_options.dart | firebase_options.dart file not found |
| FD302 | info | Firebase not initialized | No Firebase.initializeApp() call found in Dart files |
| FD303 | info | DefaultFirebaseOptions not used | DefaultFirebaseOptions not found in Firebase initialization |
| FD304 | warning | Multiple Firebase.initializeApp() calls | Multiple Firebase.initializeApp() calls found |
| FD305 | warning | Unawaited Firebase.initializeApp() | Firebase.initializeApp() is not awaited |
| FD306 | warning | Firebase.initializeApp() after runApp() | Firebase.initializeApp() is called after runApp() |
| FD307 | warning | Missing WidgetsFlutterBinding.ensureInitialized() | WidgetsFlutterBinding.ensureInitialized() is missing |

### Android Analyzer (FD400 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD400 | critical | Missing google-services.json | android/app/google-services.json file is missing |
| FD401 | error | Invalid google-services.json | google-services.json contains invalid JSON |
| FD402 | error | Package name mismatch | Package names in google-services.json and build.gradle do not match |
| FD403 | warning | Missing google-services plugin | google-services Gradle plugin is not applied |
| FD404 | warning | Outdated build tools version | Android build tools version is outdated |
| FD405 | warning | Missing POST_NOTIFICATIONS permission | POST_NOTIFICATIONS permission is missing in AndroidManifest.xml |
| FD406 | info | Missing WAKE_LOCK permission | WAKE_LOCK permission is missing in AndroidManifest.xml |
| FD407 | info | Missing INTERNET permission | INTERNET permission is missing in AndroidManifest.xml |
| FD408 | info | Outdated minSdkVersion | Android minSdkVersion is below 21 |
| FD409 | info | Outdated targetSdkVersion | Android targetSdkVersion is below 34 |
| FD410 | info | Outdated compileSdkVersion | Android compileSdkVersion is below 34 |
| FD411 | info | Missing applicationId | Missing applicationId in build.gradle |
| FD412 | info | Missing AGP version | Android Gradle Plugin version not found in project |

### iOS Analyzer (FD500 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD500 | critical | Missing GoogleService-Info.plist | iOS GoogleService-Info.plist file is missing |
| FD501 | error | Invalid GoogleService-Info.plist | GoogleService-Info.plist is not valid or malformed |
| FD502 | error | Bundle ID mismatch | Bundle IDs in GoogleService-Info.plist and Xcode project do not match |
| FD503 | error | Missing Podfile | iOS/Podfile is missing |
| FD504 | warning | Firebase pod not found | No Firebase pods found in Podfile.lock |
| FD505 | warning | Push Notifications capability missing | Push Notifications capability is not enabled in Xcode project |
| FD506 | warning | Background Modes capability missing | Background Modes capability is not enabled in Xcode project |
| FD507 | info | Remote-notifications background mode missing | Remote-notifications background mode is not enabled |
| FD508 | info | iOS version < 12.0 | iOS deployment target is below 12.0 |
| FD509 | info | Firebase imports in main.dart | Firebase imports not found in main.dart |

### FCM Analyzer (FD600 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD601 | warning | Missing firebase_messaging dependency | firebase_messaging is not declared in pubspec.yaml |
| FD602 | info | FCM usage not found | No FirebaseMessaging usage found in Dart files |
| FD603 | info | No background message handler configured | No background message handler registered with onBackgroundMessage |
| FD604 | warning | FirebaseAppDelegateProxyEnabled set to false | FirebaseAppDelegateProxyEnabled is set to false in Info.plist |
| FD605 | info | No permission request found | Notification permission request not found in Dart files |
| FD606 | info | No token refresh handler | No token refresh handler registered with onTokenRefresh |

### Crashlytics Analyzer (FD700 series)

| Code | Severity | Title | Description |
|------|----------|-------|-------------|
| FD700 | warning | Missing firebase_crashlytics dependency | firebase_crashlytics is not declared in pubspec.yaml |
| FD701 | info | Crashlytics not initialized | FirebaseCrashlytics is not used in Dart files |
| FD702 | info | runZonedGuarded not detected | runZonedGuarded is not used for crash reporting |
| FD703 | info | FlutterError.onError not overridden | FlutterError.onError is not set for crash reporting |
| FD704 | info | PlatformDispatcher.onError not detected | PlatformDispatcher.onError is not set for crash reporting |
| FD705 | info | setCrashlyticsCollectionEnabled not found | setCrashlyticsCollectionEnabled is not used in Dart files |
| FD706 | info | Missing Crashlytics custom keys | No custom keys found in Crashlytics implementation |
| FD707 | info | Missing Crashlytics user identification | No user identification methods (setUserIdentifier) found |
| FD708 | error | Missing Crashlytics Gradle plugin | Crashlytics Gradle plugin not found in Android build.gradle |
| FD709 | info | Missing Crashlytics build configuration | Crashlytics build configuration not found in build.gradle |
| FD710 | error | Missing Crashlytics CocoaPods pod | Firebase/Crashlytics pod not found in Podfile |
| FD711 | info | Missing dSYM upload configuration | dSYM upload script not configured for Crashlytics |

---

## 5. Project Completed Functionalities

### Foundation

- [x] CLI framework with `CommandRunner`, `Command` abstract class, 5 commands
- [x] Filesystem abstraction (`FileSystem` interface + `LocalFileSystem`)
- [x] Terminal abstraction (`Terminal` interface + `AnsiTerminal`)
- [x] Logging framework (`Logger`)
- [x] Exception handling (`FireDoctorException`)
- [x] Pubspec parser (`PubspecParser`)
- [x] Barrel exports throughout (`models.dart`, `services.dart`, etc.)

### Analyzers (7)

- [x] **ProjectAnalyzer** — project structure checks (pubspec, directories, Flutter detection)
- [x] **DependencyAnalyzer** — Firebase package dependency checks
- [x] **FirebaseCoreAnalyzer** — Firebase initialization scans Dart source files
- [x] **AndroidAnalyzer** — google-services.json, build.gradle, AndroidManifest.xml
- [x] **IOSAnalyzer** — GoogleService-Info.plist, Podfile, Xcode capabilities (with parsers for plist, podfile, podfile.lock, pbxproj)
- [x] **FCMAnalyzer** — messaging dependency, background handler, iOS proxy settings
- [x] **CrashlyticsAnalyzer** — dependency, Dart usage, Gradle plugin, CocoaPods, dSYM upload

### Health Score Engine

- [x] Category-level scoring
- [x] Priority grouping (Critical/High/Medium/Low)
- [x] Recommendation generation
- [x] Configurable `ScoreWeights`
- [x] `computeHealthScore()` method on `DiagnosticReport`

### CI/CD Readiness

- [x] Deterministic exit codes (0-4)
- [x] `--fail-on <warning|error|critical>` flag (doctor + report)
- [x] `--min-score <0-100>` flag (doctor + report)
- [x] Enhanced JSON schema: `schemaVersion`, `firedoctorVersion`, `generatedAt`, `exitCode`, `mostSevereRank`, `analyzerResults`, `categoryScores`, `recommendations`

### Testing

- [x] **692 unit tests** across all modules
- [x] Mock-based tests using `mocktail`
- [x] Tests for all CLI commands (help, version, diagnose, doctor, report)
- [x] Tests for all 7 analyzers
- [x] Tests for iOS parsers (plist, podfile, podfile.lock, pbxproj)
- [x] Tests for models (report, result, severity, health score)
- [x] Tests for services (report service, analyzer service)
- [x] Tests for filesystem, terminal, logging abstractions
- [x] Integration test for bug regression

---

## 6. Project Core — Architecture & Design

### Directory Structure

```
firedoctor-flutter/
├── bin/
│   ├── firedoctor.dart          # CLI entry point
│   └── firedoctor.dill          # Compiled kernel
├── lib/
│   ├── firedoctor.dart          # Main export + runFireDoctor()
│   ├── analyzers/               # 7 Analyzer implementations
│   │   ├── analyzer.dart        # Abstract base class
│   │   ├── analyzer_context.dart
│   │   ├── analyzer_result.dart
│   │   ├── project/
│   │   ├── dependency/
│   │   ├── firebase_core/
│   │   ├── android/
│   │   ├── ios/
│   │   │   └── parsers/         # plist, podfile, pbxproj parsers
│   │   ├── fcm/
│   │   └── crashlytics/
│   ├── cli/
│   │   ├── command.dart          # Abstract Command base class
│   │   ├── command_runner.dart   # Runs CLI commands
│   │   └── commands/
│   │       ├── help_command.dart
│   │       ├── version_command.dart
│   │       ├── diagnose_command.dart
│   │       ├── doctor_command.dart
│   │       └── report_command.dart
│   ├── constants/
│   │   └── app_constants.dart    # Versions, exit codes
│   ├── exceptions/
│   │   └── fire_doctor_exception.dart
│   ├── filesystem/
│   │   ├── file_system_interface.dart
│   │   └── local_file_system.dart
│   ├── logging/
│   │   └── logger.dart
│   ├── models/
│   │   ├── severity.dart         # Sealed class (info/warning/error/critical)
│   │   ├── check_status.dart     # Sealed class (passed/failed/warning/skipped/na)
│   │   ├── diagnostic_issue.dart # Individual issue
│   │   ├── diagnostic_result.dart # Result from one analyzer
│   │   ├── diagnostic_report.dart # Aggregate report
│   │   ├── pubspec.dart          # Parsed pubspec model
│   │   ├── score_weights.dart    # Configurable scoring weights
│   │   └── health_score.dart     # Health score + categories + recommendations
│   ├── parsers/
│   │   └── pubspec_parser.dart   # YAML parsing of pubspec.yaml
│   ├── services/
│   │   ├── analyzer_service.dart   # Runs all registered analyzers
│   │   ├── health_score_engine.dart # Computes health score from report
│   │   └── report_service.dart    # Generates/prints/exports reports
│   ├── terminal/
│   │   ├── terminal_interface.dart
│   │   └── ansi_terminal.dart
│   └── utils/
│       └── utils.dart            # Empty placeholder
├── test/                         # 692 tests
│   ├── analyzers/                # Tests for all 7 analyzers + iOS parsers
│   ├── cli/commands/             # Tests for all CLI commands
│   ├── models/                   # Tests for models
│   ├── services/                 # Tests for services
│   ├── filesystem/               # Tests for filesystem
│   ├── terminal/                 # Tests for terminal
│   ├── logging/                  # Tests for logger
│   ├── parsers/                  # Tests for pubspec parser
│   ├── exceptions/               # Tests for exceptions
│   ├── shared/                   # Shared mocks
│   └── integration/              # Integration tests
├── pubspec.yaml
├── analysis_options.yaml
├── LICENSE
└── README.md
```

### Data Flow

```
User Input (args)
    │
    ▼
CommandRunner.run(args)
    │
    ├──► HelpCommand      → prints usage
    ├──► VersionCommand   → prints version
    ├──► DiagnoseCommand  → runAll analyzers → print issues → exit(report.exitCode)
    ├──► DoctorCommand    → runAll analyzers → generateReport → printReport
    │                         → check --min-score → check --fail-on → exit(code)
    └──► ReportCommand    → runAll analyzers → generateReport → toJson/saveReport
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

### Severity Model

```dart
sealed class Severity implements Comparable<Severity> {
  severity value → rank (0-3)
  info    = 0  (ℹ️)
  warning = 1  (⚠️)
  error   = 2  (❌)
  critical = 3 (🚨)
}
```

### Check Status Model

```dart
sealed class CheckStatus {
  passed, failed, warning, skipped, not_applicable
}
```

### Exit Code Mapping

```dart
mostSevereRank:  0 (none)  1 (info)   2 (warning)  3 (error)   4 (critical)
                      ↓        ↓           ↓           ↓            ↓
exitCode:          0         0           1           2           3
```

---

## 7. Project Related In-depth Details

### 7.1 Analyzer Implementations

Each analyzer extends `Analyzer` and implements `Future<DiagnosticResult> analyze(AnalyzerContext context)`:

- **ProjectAnalyzer** — Reads `pubspec.yaml` via `PubspecParser`, checks directory existence, validates Flutter SDK constraint
- **DependencyAnalyzer** — Iterates known Firebase packages (`FirebasePackage.all`), checks for `firebase_core` presence, validates dependency placement
- **FirebaseCoreAnalyzer** — Scans `.dart` files with regex for `Firebase.initializeApp()`, `WidgetsFlutterBinding.ensureInitialized()`, `firebase_options.dart` existence
- **AndroidAnalyzer** — Parses `google-services.json` (JSON), `build.gradle` (regex), `AndroidManifest.xml` (regex for XML tags/permissions)
- **IOSAnalyzer** — Uses `PlistParser`, `PodfileParser`, `PodfileLockParser`, `PbxprojParser` to check iOS configuration
- **FCMAnalyzer** — Checks `firebase_messaging` dependency, scans Dart files for FCM usage patterns, checks `Info.plist` for proxy settings
- **CrashlyticsAnalyzer** — Checks dependency, scans Dart files for Crashlytics API usage, validates Gradle plugin and CocoaPods configuration

### 7.2 iOS Parsers

| Parser | Input | Output |
|--------|-------|--------|
| `PlistParser` | `GoogleService-Info.plist`, `Info.plist` | Parsed key-value pairs, background modes, Firebase proxy setting |
| `PodfileParser` | `Podfile` | iOS version, Firebase pods, Runner target |
| `PodfileLockParser` | `Podfile.lock` | List of Firebase pods found |
| `PbxprojParser` | `project.pbxproj` | Bundle identifier, target name, push/background capabilities |

### 7.3 Health Score Computation

```
ScoreWeights:
  critical = 25
  error    = 15
  warning  = 5
  info     = 1

Per-category score = max(0, 100 - total category weight / max possible weight * 100)
Overall score      = weighted average of category scores by maxPossibleWeight

Recommendations: sorted by weight descending, limited to maxRecommendations (5)
```

### 7.4 Command Argument Parsing

Flags are parsed manually (no `args` package `CommandRunner` usage — raw `List<String>` parsing):
- `--fail-on <severity>` accepts `warning`/`warn`, `error`, `critical` (default: `error`)
- `--min-score <0-100>` accepts a double between 0 and 100
- `--project-path` is positional (first non-flag arg)
- `--json` (report only) toggles JSON output
- `--output <path>` (report only) writes JSON to file

### 7.5 Test Coverage Summary

| Area | Tests |
|------|-------|
| Analyzers — Project | ✓ |
| Analyzers — Dependency | ✓ |
| Analyzers — Firebase Core | ✓ |
| Analyzers — Android | ✓ |
| Analyzers — iOS | ✓ |
| Analyzers — iOS Parsers (plist, podfile, podfile.lock, pbxproj) | ✓ |
| Analyzers — FCM | ✓ |
| Analyzers — Crashlytics | ✓ |
| CLI — HelpCommand | ✓ |
| CLI — VersionCommand | ✓ |
| CLI — DiagnoseCommand | ✓ |
| CLI — DoctorCommand | ✓ |
| CLI — ReportCommand | ✓ |
| Models — DiagnosticReport | ✓ |
| Models — DiagnosticResult | ✓ |
| Models — Severity | ✓ |
| Models — HealthScore | ✓ |
| Models — ScoreWeights | ✓ |
| Services — ReportService | ✓ |
| Services — AnalyzerService | ✓ |
| Filesystem | ✓ |
| Terminal | ✓ |
| Logging | ✓ |
| Parsers — PubspecParser | ✓ |
| Exceptions | ✓ |
| Integration — Bug regression | ✓ |
| **Total** | **692 tests** |

### 7.6 Error Severity Breakdown by Analyzer

| Analyzer | Critical | Error | Warning | Info | Total Codes |
|----------|----------|-------|---------|------|-------------|
| Project | 0 | 1 | 5 | 3 | 9 |
| Dependency | 0 | 0 | 2 | 1 | 3 |
| Firebase Core | 0 | 1 | 5 | 2 | 8 |
| Android | 1 | 2 | 3 | 7 | 13 |
| iOS | 1 | 3 | 3 | 3 | 10 |
| FCM | 0 | 0 | 2 | 4 | 6 |
| Crashlytics | 0 | 2 | 1 | 8 | 11 |
| **Total** | **2** | **9** | **21** | **28** | **56** |

### 7.7 Git History (7 Commits)

```
b902dfe feat: Implement Health Score Model and Engine
f57c3cf Add tests for CrashlyticsAnalyzer
97ab10b Add unit tests for iOS parsers
035855f feat: Enhance Firebase initialization analyzer tests
23d3c38 Refactor tests for CLI commands and error handling
e2e23b8 Add comprehensive tests for DependencyAnalyzer, FirebasePackage, and FirebaseCoreAnalyzer
f06f1fa Add unit tests for diagnostic report, result, pubspec, severity, and services
```

### 7.8 Known Gaps / Future Work

- **CI/CD workflows not yet created** — No `.github/workflows/ci.yml`, no `docs/ci-cd.md`
- **AnalyticsAnalyzer, RemoteConfigAnalyzer, AuthAnalyzer, FirestoreAnalyzer** — Not implemented
- **`--fail-on invalid` exits 0** — Should return `exitInternalFailure` (4) for invalid severity values
- **`docs/` directory** — Does not exist yet (only README.md and this document)
- **CHANGELOG.md** — Not yet created

### 7.9 Building & Running

```bash
# Run directly
dart run bin/firedoctor.dart doctor

# Compile executable
dart compile exe bin/firedoctor.dart -o firedoctor
./firedoctor doctor

# Run all tests
dart test

# Analyze
dart analyze

# Run with coverage
dart run build_runner test -- --coverage=coverage/
```
