# FireDoctor — Complete Project Status

> **Generated:** 2026-06-10 | **Version:** 0.1.0 | **Phase 1 — Foundation**

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [File Inventory](#2-file-inventory)
3. [Architecture](#3-architecture)
4. [Features & Functionality](#4-features--functionality)
5. [Analyzers & Diagnostic Codes](#5-analyzers--diagnostic-codes)
6. [Bug Fixes](#6-bug-fixes)
7. [Test Coverage](#7-test-coverage)
8. [Lint & Analysis](#8-lint--analysis)
9. [Known Issues & Dead Code](#9-known-issues--dead-code)
10. [Dependencies](#10-dependencies)
11. [Future Roadmap](#11-future-roadmap)

---

## 1. Project Overview

| Attribute | Value |
|-----------|-------|
| **Name** | `firedoctor` |
| **Version** | `0.1.0` |
| **Description** | Firebase diagnostics CLI tool for Flutter projects |
| **Repository** | [https://github.com/firedoctor-cli/firedoctor](https://github.com/firedoctor-cli/firedoctor) |
| **License** | MIT |
| **SDK constraint** | `>=3.0.0 <4.0.0` |
| **Total Dart files** | **78** (48 lib + 30 test + 1 bin) |
| **Source LOC** | `lib/`: ~9,172 lines | `test/`: ~22,379 lines |
| **Test count** | **422 — all passing** |
| **Git commits** | 3 |

### What It Is

FireDoctor is a **Dart CLI tool** (not a Flutter app) that diagnoses Firebase configuration and setup issues in Flutter projects. It checks project structure, dependency configuration, Firebase Core initialization patterns, and Android Firebase setup.

### Quick Start

```bash
dart pub global activate --source path .
firedoctor diagnose /path/to/flutter/project
firedoctor doctor /path/to/flutter/project
firedoctor report /path/to/flutter/project
firedoctor report --json --output report.json /path/to/flutter/project
```

---

## 2. File Inventory

### 2.1 Root Files

| File | Description |
|------|-------------|
| `pubspec.yaml` | Project manifest (15 lines) |
| `pubspec.lock` | Lockfile (397 lines) |
| `analysis_options.yaml` | Lint config — strict mode + 6 custom rules |
| `README.md` | Project documentation |
| `LICENSE` | MIT License |
| `.gitignore` | Git ignores |
| `firedoctor` | Compiled native binary (5.4 MB, arm64) |
| `bin/firedoctor.dill` | Dart kernel snapshot (8.3 MB) |
| `bin/firedoctor.dart` | Entry point (12 lines) |

### 2.2 Source Files (`lib/` — 48 files)

```
lib/
├── firedoctor.dart                      # Main wiring — runFireDoctor()
├── analyzers/
│   ├── analyzer.dart                    # Abstract Analyzer interface
│   ├── analyzer_context.dart            # AnalyzerContext model
│   ├── analyzer_result.dart             # AnalyzerResultExtension
│   ├── analyzers.dart                   # Barrel export
│   ├── project/
│   │   ├── project.dart                 # Barrel
│   │   └── project_analyzer.dart        # ProjectAnalyzer (8 checks)
│   ├── dependency/
│   │   ├── dependency.dart              # Barrel
│   │   ├── dependency_analyzer.dart      # DependencyAnalyzer (3 checks)
│   │   └── firebase_package.dart        # 10 Firebase package definitions
│   ├── firebase_core/
│   │   ├── firebase_core.dart           # Barrel
│   │   └── firebase_core_analyzer.dart  # FirebaseCoreAnalyzer (8 checks)
│   └── android/
│       ├── android.dart                 # Barrel
│       └── android_analyzer.dart        # AndroidAnalyzer (10 checks)
├── cli/
│   ├── cli.dart                         # Barrel
│   ├── command.dart                     # Abstract Command interface
│   ├── command_runner.dart              # Command routing
│   └── commands/
│       ├── commands.dart                # Barrel
│       ├── diagnose_command.dart        # `firedoctor diagnose`
│       ├── doctor_command.dart          # `firedoctor doctor`
│       ├── report_command.dart          # `firedoctor report`
│       ├── help_command.dart            # `firedoctor help`
│       └── version_command.dart         # `firedoctor version`
├── constants/
│   ├── constants.dart                   # Barrel
│   └── app_constants.dart               # AppConstants
├── exceptions/
│   ├── exceptions.dart                  # Barrel
│   └── fire_doctor_exception.dart       # FireDoctorException
├── filesystem/
│   ├── filesystem.dart                  # Barrel
│   ├── file_system_interface.dart       # Abstract FileSystem (13 methods)
│   └── local_file_system.dart           # Real I/O implementation
├── logging/
│   ├── logging.dart                     # Barrel
│   └── logger.dart                      # Logger with optional name prefix
├── models/
│   ├── models.dart                      # Barrel
│   ├── severity.dart                    # Sealed class — 4 levels
│   ├── check_status.dart                # Sealed class — 5 variants
│   ├── diagnostic_issue.dart            # Issue model with copyWith
│   ├── diagnostic_result.dart           # Per-analyzer result
│   ├── diagnostic_report.dart           # Full report with score
│   └── pubspec.dart                     # Pubspec model
├── parsers/
│   ├── parsers.dart                     # Barrel
│   └── pubspec_parser.dart              # YAML pubspec parser
├── services/
│   ├── services.dart                    # Barrel
│   ├── analyzer_service.dart            # Register/run analyzers
│   └── report_service.dart              # Report generation + JSON
├── terminal/
│   ├── terminal.dart                    # Barrel
│   ├── terminal_interface.dart          # Abstract Terminal (9 methods)
│   └── ansi_terminal.dart               # ANSI color implementation
└── utils/
    └── utils.dart                       # Empty file
```

### 2.3 Test Files (`test/` — 30 files)

```
test/
├── firedoctor_test.dart                         # 1 test (placeholder)
├── shared/
│   └── mocks.dart                                # Mocks + Fakes
├── integration/
│   └── bug_regression_test.dart                  # 7 tests (bug regression)
├── analyzers/
│   ├── analyzer_test.dart                        # 2 tests
│   ├── analyzer_context_test.dart                # 3 tests
│   ├── project/project_analyzer_test.dart        # 18 tests
│   ├── dependency/
│   │   ├── dependency_analyzer_test.dart          # 27 tests
│   │   └── firebase_package_test.dart            # 64 tests (parameterized)
│   ├── firebase_core/
│   │   └── firebase_core_analyzer_test.dart      # 39 tests
│   └── android/
│       └── android_analyzer_test.dart            # 36 tests
├── cli/
│   ├── command_runner_test.dart                  # 8 tests
│   └── commands/
│       ├── diagnose_command_test.dart            # 10 tests
│       ├── doctor_command_test.dart              # 11 tests
│       ├── report_command_test.dart              # 13 tests
│       ├── help_command_test.dart                # 4 tests
│       └── version_command_test.dart             # 1 test
├── models/
│   ├── severity_test.dart                        # 27 tests
│   ├── check_status_test.dart                    # 24 tests
│   ├── diagnostic_issue_test.dart                # 7 tests
│   ├── diagnostic_result_test.dart               # 12 tests
│   ├── diagnostic_report_test.dart               # 11 tests
│   └── pubspec_test.dart                         # 7 tests
├── parsers/
│   └── pubspec_parser_test.dart                  # 19 tests
├── services/
│   ├── analyzer_service_test.dart                # 6 tests
│   └── report_service_test.dart                  # 9 tests
├── filesystem/
│   ├── file_system_interface_test.dart           # 19 tests
│   └── local_file_system_test.dart               # 15 tests
├── logging/
│   └── logger_test.dart                          # 10 tests
├── exceptions/
│   └── fire_doctor_exception_test.dart           # 5 tests
└── terminal/
    └── terminal_test.dart                        # 9 tests
```

---

## 3. Architecture

### 3.1 Abstract Interfaces

| Interface | File | Methods | Implementations |
|-----------|------|---------|-----------------|
| `Analyzer` | `analyzer.dart` | `name`, `description`, `category`, `analyze()` | `ProjectAnalyzer`, `DependencyAnalyzer`, `FirebaseCoreAnalyzer`, `AndroidAnalyzer` |
| `Command` | `command.dart` | `name`, `description`, `aliases`, `execute()` | `HelpCommand`, `VersionCommand`, `DiagnoseCommand`, `DoctorCommand`, `ReportCommand` |
| `Terminal` | `terminal_interface.dart` | 9 methods | `AnsiTerminal` |
| `FileSystem` | `file_system_interface.dart` | 13 methods | `LocalFileSystem` |

### 3.2 Sealed Classes

```
Severity (sealed)
├── Severity.info      (value=0, emoji=ℹ️)
├── Severity.warning   (value=1, emoji=⚠️)
├── Severity.error     (value=2, emoji=❌)
└── Severity.critical  (value=3, emoji=🚨)

CheckStatus (sealed)
├── CheckStatus.passed         (label='Passed')
├── CheckStatus.failed         (label='Failed')
├── CheckStatus.warning        (label='Warning')
├── CheckStatus.skipped        (label='Skipped')
└── CheckStatus.notApplicable  (label='N/A')
```

### 3.3 Model Classes

| Class | Fields | Computed Getters |
|-------|--------|-----------------|
| `DiagnosticIssue` | severity, code, title, description, recommendation?, filePath?, lineNumber?, metadata? | — |
| `DiagnosticResult` | analyzerName, status, issues, duration, timestamp, projectName? | issueCount, errorCount, warningCount, passed |
| `DiagnosticReport` | projectName, projectPath, createdAt, results, firebaseVersion?, environment | totalIssues, totalErrors, totalWarnings, score, passed |
| `Pubspec` | name, version?, description?, dependencies, devDependencies, flutterSdkConstraint?, dartSdkConstraint?, isFlutterProject | hasDependency(), hasDevDependency(), dependencyVersion() |

### 3.4 Wiring (`runFireDoctor()`)

```
main()
  └─ runFireDoctor(args)
       ├─ AnsiTerminal
       ├─ LocalFileSystem
       ├─ Logger
       ├─ AnalyzerService
       │    ├─ ProjectAnalyzer
       │    ├─ DependencyAnalyzer
       │    ├─ FirebaseCoreAnalyzer
       │    └─ AndroidAnalyzer
       ├─ CommandRunner
       │    ├─ HelpCommand
       │    ├─ VersionCommand
       │    ├─ DiagnoseCommand
       │    ├─ DoctorCommand
       │    └─ ReportCommand
       └─ runner.run(args) → exit(code)
```

---

## 4. Features & Functionality

### 4.1 CLI Commands (5 total)

| Command | Aliases | Description |
|---------|---------|-------------|
| `help` | `h`, `-h`, `--help` | Shows help information for commands |
| `version` | `v`, `-v`, `--version` | Shows FireDoctor version |
| `diagnose` | — | Runs all analyzers, prints per-analyzer issues with summary |
| `doctor` | — | Runs all analyzers, generates a diagnostic report |
| `report` | — | Generates a diagnostic report with `--json` and `--output` flags |

### 4.2 Report Output Formats

- **Terminal report** (default for `doctor` and `report`): Formatted ASCII report with score, status, and issues
- **JSON** (`report --json`): Machine-readable JSON output
- **File save** (`report --output <path>`): Saves report to file
- **Combined** (`report --json --output <path>`): Saves JSON to file

### 4.3 Abstracted Services

- **FileSystem**: Abstract I/O with sync and async variants. `LocalFileSystem` wraps `dart:io`. Test double: `FakeFileSystem`
- **Terminal**: Abstract output with colored log levels. `AnsiTerminal` supports ANSI codes, `NO_COLOR` env var, stderr for errors. Test double: `FakeTerminal`
- **AnalyzerService**: Registers analyzers, runs them sequentially, wraps with timing and error handling
- **ReportService**: Generates `DiagnosticReport`, prints formatted output, serializes to JSON, saves to file
- **Logger**: Wraps `Terminal` with optional `[name]` prefix

### 4.4 Lint Configuration

```yaml
include: package:lints/recommended.yaml
strict-casts: true
strict-inference: true
strict-raw-types: true
Extra rules: always_declare_return_types, prefer_const_constructors,
             prefer_const_declarations, prefer_final_locals,
             unawaited_futures, use_super_parameters
```

---

## 5. Analyzers & Diagnostic Codes

### 5.1 ProjectAnalyzer — 8 checks

Analyzes Flutter project structure and metadata.

| Code | Severity | Condition |
|------|----------|-----------|
| `MISSING_PUBSPEC` | CRITICAL | pubspec.yaml does not exist |
| `INVALID_PUBSPEC` | CRITICAL | pubspec.yaml has invalid YAML content |
| `NOT_FLUTTER_PROJECT` | WARNING | No `flutter` dependency declared |
| `MISSING_ANDROID` | WARNING | `android/` directory does not exist |
| `MISSING_IOS` | WARNING | `ios/` directory does not exist |
| `MISSING_LIB` | ERROR | `lib/` directory does not exist |
| `MISSING_TEST` | INFO | `test/` directory does not exist |
| `FLUTTER_SDK_CONSTRAINT` | INFO | Flutter SDK constraint is present (always emitted) |

**Tests:** 18 | **Status:** Complete

### 5.2 DependencyAnalyzer — 3 checks

Validates Firebase dependencies in `pubspec.yaml`.

| Code | Severity | Condition |
|------|----------|-----------|
| `FD200` | CRITICAL | Non-core Firebase package exists without `firebase_core` |
| `FD201` | ERROR | Firebase package declared in `dev_dependencies` |
| `FD202` | WARNING | Loose version constraint (`""`, `"any"`, `"*"`) |

**Known Firebase packages:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`, `firebase_remote_config`, `firebase_database`, `firebase_app_check`

**Tests:** 27 (DependencyAnalyzer) + 64 (FirebasePackage) | **Status:** Complete

### 5.3 FirebaseCoreAnalyzer — 8 checks

Analyzes Firebase Core initialization patterns by scanning Dart source files.

| Code | Severity | Condition |
|------|----------|-----------|
| `FD300` | CRITICAL | `firebase_core` in deps but no `Firebase.initializeApp()` found |
| `FD301` | WARNING | `lib/firebase_options.dart` does not exist |
| `FD302` | ERROR | `WidgetsFlutterBinding.ensureInitialized()` missing or after init (same file) |
| `FD303` | INFO | `DefaultFirebaseOptions.currentPlatform` not referenced |
| `FD304` | WARNING | Multiple `Firebase.initializeApp()` calls (1+ real init detected) |
| `FD305` | WARNING | `Firebase.initializeApp()` called without `await` |
| `FD306` | ERROR | `Firebase.initializeApp()` appears after `runApp()` (same file) |
| `FD307` | ERROR | `Firebase.initializeApp()` called but `firebase_core` not in deps |

**Scanning:** Recursively finds `.dart` files in `lib/`, strips comments and string literals, then scans for patterns. Detects multi-line calls via balanced-paren matching.

**Tests:** 39 | **Status:** Complete (bugs 2-4 fixed — see §6)

### 5.4 AndroidAnalyzer — 10 checks

Analyzes Android Firebase configuration files.

| Code | Severity | Condition |
|------|----------|-----------|
| `FD400` | CRITICAL | `android/app/google-services.json` does not exist |
| `FD401` | ERROR | `google-services.json` contains invalid JSON |
| `FD402` | ERROR | Package name in `google-services.json` doesn't match `build.gradle` |
| `FD403` | ERROR | `com.google.gms.google-services` plugin missing from `build.gradle` |
| `FD404` | ERROR | `INTERNET` permission missing from `AndroidManifest.xml` |
| `FD405` | WARNING | `POST_NOTIFICATIONS` permission missing (Android 13+) |
| `FD406` | INFO | `WAKE_LOCK` permission missing |
| `FD407` | WARNING | `compileSdk` < 34 (recommended minimum) |
| `FD408` | INFO | `minSdk` < 21 (firebase_core minimum) |
| `FD409` | WARNING | `targetSdk` < 34 |

**Parsers (no naive string matching):**
- `google-services.json`: Parsed via `dart:convert` — validates structure, extracts package name, project number, project ID
- `AndroidManifest.xml`: Regex-based extraction of `package` attribute and `<uses-permission>` entries
- `build.gradle` / `build.gradle.kts`: Regex-based extraction supporting both **Groovy** (`compileSdk 34`) and **Kotlin DSL** (`compileSdk = 34`) syntax, plus `plugins { id '...' }` and `apply plugin:` styles

**Tests:** 36 | **Status:** Complete

### Complete Issue Code Summary

| Code | Analyzer | Severity | Count |
|------|----------|----------|-------|
| `MISSING_PUBSPEC` | Project | CRITICAL | 1 |
| `INVALID_PUBSPEC` | Project | CRITICAL | 1 |
| `NOT_FLUTTER_PROJECT` | Project | WARNING | 1 |
| `MISSING_ANDROID` | Project | WARNING | 1 |
| `MISSING_IOS` | Project | WARNING | 1 |
| `MISSING_LIB` | Project | ERROR | 1 |
| `MISSING_TEST` | Project | INFO | 1 |
| `FLUTTER_SDK_CONSTRAINT` | Project | INFO | 1 |
| `FD200` | Dependency | CRITICAL | 1 |
| `FD201` | Dependency | ERROR | 1 |
| `FD202` | Dependency | WARNING | 1 |
| `FD300` | FirebaseCore | CRITICAL | 1 |
| `FD301` | FirebaseCore | WARNING | 1 |
| `FD302` | FirebaseCore | ERROR | 1 |
| `FD303` | FirebaseCore | INFO | 1 |
| `FD304` | FirebaseCore | WARNING | 1 |
| `FD305` | FirebaseCore | WARNING | 1 |
| `FD306` | FirebaseCore | ERROR | 1 |
| `FD307` | FirebaseCore | ERROR | 1 |
| `FD400` | Android | CRITICAL | 1 |
| `FD401` | Android | ERROR | 1 |
| `FD402` | Android | ERROR | 1 |
| `FD403` | Android | ERROR | 1 |
| `FD404` | Android | ERROR | 1 |
| `FD405` | Android | WARNING | 1 |
| `FD406` | Android | INFO | 1 |
| `FD407` | Android | WARNING | 1 |
| `FD408` | Android | INFO | 1 |
| `FD409` | Android | WARNING | 1 |

**Total: 29 distinct diagnostic codes across 4 analyzers.**

---

## 6. Bug Fixes

Four production-impacting defects were identified and fixed:

### Bug 1: Project Name Always Shows "unknown"

**Problem:** `DoctorCommand._extractProjectName()` always returned `'unknown'`. The project name parsed by `ProjectAnalyzer` from `pubspec.name` was discarded and never made available to downstream consumers.

**Root cause:** No mechanism existed to carry the project name from the analyzer to the commands.

**Fix:**
1. Added `String? projectName` optional field to `DiagnosticResult` model
2. `ProjectAnalyzer` now sets `projectName: pubspec.name` when pubspec parses successfully
3. `DoctorCommand._extractProjectName()` iterates results looking for a non-null projectName
4. `ReportCommand` extracts projectName from results before generating report
5. `AnalyzerService.runAnalyzer()` copies `projectName` through when creating timed results

**Files changed:** `diagnostic_result.dart`, `project_analyzer.dart`, `doctor_command.dart`, `report_command.dart`, `analyzer_service.dart`

### Bug 2: Multi-line `Firebase.initializeApp()` Detection Fails

**Problem:** The scanner used `line.contains('Firebase.initializeApp(')` which could not detect calls spanning multiple lines:
```dart
Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**Fix:** Replaced line-level `contains()` with `_findInitCalls()` — a new method that uses balanced-parenthesis matching across lines. After stripping comments/strings, it scans for the opening `Firebase.initializeApp(` and tracks paren depth across subsequent lines until the call is fully closed.

### Bug 3: Comment/String Literal False Positives

**Problem:** Commented-out code and string literals containing `Firebase.initializeApp()` triggered false positives (e.g., FD304 for multiple calls, FD305 for missing await).

**Fix:** Added `_stripCommentsAndStrings()` — strips `//` single-line comments, `/* */` block comments, and `'...'`/`"..."`/`'''...'''`/`"""..."""` string literals, replacing content with spaces to preserve line/column positions. All pattern matching runs on cleaned lines.

### Bug 4: Cross-file `ensureInitialized` Ordering False Positives

**Problem:** FD302 fired whenever `WidgetsFlutterBinding.ensureInitialized()` was in a different file than `Firebase.initializeApp()`, even if the runtime order was correct.

**Fix:** Changed FD302 logic: only fires when `ensureInitialized` is in the **same file** and after init (or missing entirely). Cross-file `ensureInitialized` is conservatively assumed to be correctly ordered at runtime.

### Regression Tests

A dedicated integration test file (`test/integration/bug_regression_test.dart`) with 7 tests verifies all 4 bugs stay fixed.

---

## 7. Test Coverage

### 7.1 Test Summary

| Category | Test File | Tests | Coverage |
|----------|-----------|-------|----------|
| **Models** | 6 files | 88 | All variants, properties, methods tested |
| **Analyzers** | 6 files | 187 | All issue codes, edge cases, scenarios |
| **CLI** | 6 files | 47 | All commands, flag combinations, error paths |
| **Services** | 2 files | 15 | Generate, print, JSON, save, register, run |
| **Parsers** | 1 file | 19 | Valid/invalid YAML, all dep types, file I/O |
| **Filesystem** | 2 files | 34 | Both fake and real I/O implementations |
| **Logger** | 1 file | 10 | All methods with/without name prefix |
| **Exceptions** | 1 file | 5 | Constructor variants, toString |
| **Terminal** | 1 file | 9 | FakeTerminal operations |
| **Integration** | 1 file | 7 | Bug regression tests |
| **Top-level** | 1 file | 1 | Placeholder |
| **Total** | **30 files** | **422** | **100% passing** |

### 7.2 Test Gap Analysis

| Component | Status | Notes |
|-----------|--------|-------|
| Models (Severity, CheckStatus, DiagnosticIssue, etc.) | **TESTED** | All getters, methods, constructors |
| PubspecParser | **TESTED** | All parse paths, error handling |
| ProjectAnalyzer | **TESTED** | All 8 checks, edge cases, status |
| DependencyAnalyzer | **TESTED** | All 3 issue codes, combinations |
| FirebasePackage | **TESTED** | All 10 packages, lookup |
| FirebaseCoreAnalyzer | **TESTED** | All 8 issue codes, multi-line, comments, cross-file |
| AndroidAnalyzer | **TESTED** | All 10 checks, Groovy/Kotlin DSL, permissions, SDK versions |
| CLI Commands (all 5) | **TESTED** | All argument permutations, exit codes |
| CommandRunner | **TESTED** | Registration, lookup, routing |
| AnalyzerService | **TESTED** | Register, runAll, runAnalyzer, error handling |
| ReportService | **TESTED** | Generate, print, JSON, save |
| Logger | **TESTED** | All methods with/without name prefix |
| Exceptions | **TESTED** | Constructor variants, toString |
| FileSystem (Fake + Local) | **TESTED** | Both interface and real implementation |
| Bug Regression | **TESTED** | 7 tests covering all 4 fixed bugs |
| **AnsiTerminal** | **NOT TESTED** | Real terminal with ANSI escapes, NO_COLOR |
| **AnalyzerResultExtension** | **NOT TESTED** | Extension methods never imported |
| **runFireDoctor() integration** | **PLACEHOLDER** | Deferred to Phase 2 |
| **DoctorCommand._extractProjectName()** | **NOT TESTED directly** | Tested indirectly via integration |
| **AppConstants** values | **NOT TESTED directly** | Only used in exit code assertions |

---

## 8. Lint & Analysis

### Current Status

| Check | Result |
|-------|--------|
| `dart analyze lib/` | **0 issues** — clean |
| `dart analyze test/` | **8 infos** (prefer_const_declarations in pubspec_parser_test.dart) |
| `dart format --set-exit-if-changed` | **Exit 0** — clean |

The 8 remaining info-level issues are all `prefer_const_declarations` suggestions in `pubspec_parser_test.dart` — the test defines multi-line YAML strings in `final` variables that could be `const`. These are style preferences, not errors.

---

## 9. Known Issues & Dead Code

### 9.1 Design Concerns

| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | `_hasVersionIssue` only flags `""`, `"any"`, `"*"` — misses unbounded ranges (`>=1.0.0`), git deps, path deps | `dependency_analyzer.dart:135-141` | Low |
| 2 | No web/macos/windows/linux platform detection | `project_analyzer.dart` | Low |
| 3 | No `pubspec.lock` analysis or Firebase config file checks | Project-wide | Low |
| 4 | `DiagnoseCommand` has no `--json` flag (unlike `report`) | `diagnose_command.dart` | Low |
| 5 | Unknown CLI flags silently treated as positional path arg | `report_command.dart:35-49` | Low |
| 6 | Hardcoded version `^3.0.0` for firebase_core recommendations | `dependency_analyzer.dart:80`, `firebase_core_analyzer.dart:235` | Low |
| 7 | Synchronous `readAsString` in async context (blocks event loop) | `firebase_core_analyzer.dart:65` | Low |
| 8 | Recursive `_findDartFiles` with no depth limit (stack overflow risk) | `firebase_core_analyzer.dart:263-275` | Low |
| 9 | No try-catch on per-file reads (single unreadable file crashes) | `firebase_core_analyzer.dart:65` | Low |
| 10 | Unusual `copyWith` using `String? Function()?` instead of plain `String?` | `diagnostic_issue.dart:29-32` | Info |

### 9.2 Dead Code Inventory

| # | Location | What | Status |
|---|----------|------|--------|
| 1 | `lib/utils/utils.dart` | Empty file exported from main library | Can remove |
| 2 | `FileSystem` interface | `createDirectory()`, `delete()`, `copy()` — defined but never called | Can remove |
| 3 | `lib/exceptions/fire_doctor_exception.dart` | Entire class — defined but never thrown | Can remove |
| 4 | `lib/analyzers/analyzer_result.dart` | `AnalyzerResultExtension` — 4 extension methods never imported | Can remove |
| 5 | `Logger.header()` and `Logger.blank()` | 2 methods never called | Can remove |
| 6 | `CommandRunner.logger` and `.fileSystem` | Fields never used within class | Can remove |
| 7 | 5 command `logger` fields | `DiagnoseCommand`, `DoctorCommand`, `ReportCommand`, `HelpCommand`, `VersionCommand` — stored but never used | Can remove from constructors |
| 8 | Duration calculations in 3 analyzers | `DateTime.now().difference(startTime)` — overwritten by `AnalyzerService.runAnalyzer()` | Can simplify |
| 9 | `AppConstants.githubUrl`, `AppConstants.maxLineWidth` | Unused constants | Can remove |
| 10 | `AnalyzerContext.configuration` | Default `{}` always, never populated | Can simplify |

### 9.3 Untested Components

| Component | File | Gap |
|-----------|------|-----|
| `AnsiTerminal` | `lib/terminal/ansi_terminal.dart` | Zero tests for ANSI escapes, NO_COLOR, stderr |
| `AnalyzerResultExtension` | `lib/analyzers/analyzer_result.dart` | 4 extension methods untested |
| `runFireDoctor()` | `lib/firedoctor.dart` | Only a "is a Function" placeholder test |

---

## 10. Dependencies

### Direct Dependencies (4)

| Package | Version | Used? | Notes |
|---------|---------|-------|-------|
| `args` | `^2.4.0` | **UNUSED** | Project has its own custom `CommandRunner` |
| `meta` | `^1.11.0` | **UNUSED** | No `@immutable`, `@protected`, etc. used |
| `path` | `^1.9.0` | Used in `local_file_system.dart` | |
| `yaml` | `^3.1.0` | Used in `pubspec_parser.dart` | |

### Dev Dependencies (3)

| Package | Version | Notes |
|---------|---------|-------|
| `test` | `^1.25.0` | Testing framework |
| `mocktail` | `^1.0.0` | Mocking library |
| `lints` | `^3.0.0` | **Outdated** — latest is `6.1.0` |

### Recommendations

- Remove `args` and `meta` from dependencies (unused)
- Update `lints` to latest major version

---

## 11. Future Roadmap

### Phase 1 — Foundation (Current) ✅

- [x] CLI framework with 5 commands
- [x] Project structure analysis
- [x] Firebase dependency validation
- [x] Firebase Core initialization pattern analysis
- [x] Android Firebase configuration analysis
- [x] JSON reporting with file output
- [x] Abstract filesystem and terminal interfaces
- [x] 422 tests passing

### Phase 2 — Planned

- [ ] iOS Firebase configuration analysis
- [ ] FCM (Firebase Cloud Messaging) configuration analysis
- [ ] Crashlytics configuration analysis
- [ ] Web platform support detection
- [ ] `pubspec.lock` analysis for version conflicts
- [ ] Firebase configuration file analysis (`google-services.json`, `GoogleService-Info.plist`)
- [ ] Integration/e2e tests for `runFireDoctor()`
- [ ] CI/CD pipeline setup
- [ ] `AnsiTerminal` unit tests
- [ ] `AnalyzerResultExtension` tests
- [ ] Doc comments on public API
- [ ] Parallel analyzer execution (performance)
- [ ] Async file system operations in analyzers

---

*This document was generated from the live codebase. For the most up-to-date information, run `dart test` and `dart analyze lib/`.*
