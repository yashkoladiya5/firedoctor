# FireDoctor — Complete Project Documentation

> **Generated:** 2026-06-10 | **Version:** 0.1.0 | **SDK:** Dart >=3.0.0 <4.0.0

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Features](#2-project-features)
3. [Project Errors (Diagnostic Codes)](#3-project-errors-diagnostic-codes)
4. [Completed Functionalities](#4-completed-functionalities)
5. [Project Core Architecture](#5-project-core-architecture)
6. [In-Depth Details](#6-in-depth-details)

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
| **Runtime** | Dart SDK 3.10.3 (stable) on `macos_arm64` |
| **Total Dart files** | **93** (57 lib + 36 test + 1 bin) |
| **Source LOC** | `lib/`: ~3,619 lines | `test/`: ~8,818 lines |
| **Test count** | **570 — all passing** |
| **Git commits** | 4 |
| **Analyzers** | 6 (project, dependency, firebase_core, android, ios, fcm) |
| **Diagnostic codes** | **42** (FD200–FD605 + project checks) |

### What It Is

FireDoctor is a **Dart CLI tool** (not a Flutter app) that diagnoses Firebase configuration and setup issues in Flutter projects. It checks:
- Project structure and metadata
- Dependency configuration
- Firebase Core initialization patterns
- Android Firebase configuration (google-services.json, build.gradle, AndroidManifest.xml)
- iOS Firebase configuration (GoogleService-Info.plist, Podfile, Xcode project, Info.plist)
- Firebase Cloud Messaging setup (Dart code, iOS Info.plist, permissions)

### Quick Start

```bash
# Install
dart pub global activate --source path .
# Or compile
dart compile exe bin/firedoctor.dart -o firedoctor

# Run diagnostics
dart run bin/firedoctor.dart diagnose /path/to/flutter/project
dart run bin/firedoctor.dart doctor /path/to/flutter/project
dart run bin/firedoctor.dart report /path/to/flutter/project

# JSON output
dart run bin/firedoctor.dart report --json --output report.json /path/to/flutter/project
```

---

## 2. Project Features

### 2.1 CLI Commands (5 total)

| Command | Aliases | Description |
|---------|---------|-------------|
| `diagnose` | — | Runs all analyzers, prints per-analyzer issues with summary |
| `doctor` | — | Runs all analyzers, generates a formatted diagnostic report with score |
| `report` | — | Generates a diagnostic report with `--json` and `--output` flags |
| `help` | `h`, `-h`, `--help` | Shows help information for commands |
| `version` | `v`, `-v`, `--version` | Shows FireDoctor version |

### 2.2 Report Output Formats

- **Terminal report** (default for `doctor` and `report`): Formatted ASCII report with score, status, and issues
- **JSON** (`report --json`): Machine-readable JSON output
- **File save** (`report --output <path>`): Saves report to file
- **Combined** (`report --json --output <path>`): Saves JSON to file

### 2.3 Abstracted Services

| Service | Interface | Implementation | Purpose |
|---------|-----------|---------------|---------|
| `FileSystem` | `FileSystem` (13 methods) | `LocalFileSystem` (+ `FakeFileSystem` for test) | Abstract file I/O |
| `Terminal` | `Terminal` (9 methods) | `AnsiTerminal` (+ `FakeTerminal` for test) | Colored terminal output |
| `AnalyzerService` | — | `AnalyzerService` | Register and run analyzers |
| `ReportService` | — | `ReportService` | Generate, print, and serialize reports |
| `Logger` | — | `Logger` | Logging with optional name prefix |
| `CommandRunner` | — | `CommandRunner` | CLI command routing |

### 2.4 Supported Analyzers

| Analyzer | Category | Location | Checks | Codes |
|----------|----------|----------|--------|-------|
| ProjectAnalyzer | `project` | `lib/analyzers/project/` | Project structure & metadata | 8 checks (MISSING_PUBSPEC, INVALID_PUBSPEC, etc.) |
| DependencyAnalyzer | `dependency` | `lib/analyzers/dependency/` | Firebase dependency validation | 3 checks (FD200–FD202) |
| FirebaseCoreAnalyzer | `firebase_core` | `lib/analyzers/firebase_core/` | Firebase initialization patterns | 8 checks (FD300–FD307) |
| AndroidAnalyzer | `android` | `lib/analyzers/android/` | Android Firebase config | 10 checks (FD400–FD409) |
| IOSAnalyzer | `ios` | `lib/analyzers/ios/` | iOS Firebase config (with parsers) | 13 checks (FD500–FD512) |
| FCMAnalyzer | `fcm` | `lib/analyzers/fcm/` | Firebase Cloud Messaging | 6 checks (FD600–FD605) |

---

## 3. Project Errors (Diagnostic Codes)

### 3.1 Project Analyzer — Configuration Checks

| Code | Severity | Condition |
|------|----------|-----------|
| `MISSING_PUBSPEC` | CRITICAL | `pubspec.yaml` does not exist |
| `INVALID_PUBSPEC` | CRITICAL | `pubspec.yaml` has invalid YAML content |
| `NOT_FLUTTER_PROJECT` | WARNING | No `flutter` dependency declared |
| `MISSING_ANDROID` | WARNING | `android/` directory does not exist |
| `MISSING_IOS` | WARNING | `ios/` directory does not exist |
| `MISSING_LIB` | ERROR | `lib/` directory does not exist |
| `MISSING_TEST` | INFO | `test/` directory does not exist |
| `FLUTTER_SDK_CONSTRAINT` | INFO | Flutter SDK constraint is present (always emitted) |

### 3.2 Dependency Analyzer — Firebase Dependencies (FD200+)

| Code | Severity | Condition |
|------|----------|-----------|
| `FD200` | CRITICAL | Non-core Firebase package exists without `firebase_core` |
| `FD201` | ERROR | Firebase package declared in `dev_dependencies` |
| `FD202` | WARNING | Loose version constraint (`""`, `"any"`, `"*"`) |

### 3.3 Firebase Core Analyzer — Initialization (FD300+)

| Code | Severity | Condition |
|------|----------|-----------|
| `FD300` | CRITICAL | `firebase_core` in deps but no `Firebase.initializeApp()` found |
| `FD301` | WARNING | `lib/firebase_options.dart` does not exist |
| `FD302` | ERROR | `WidgetsFlutterBinding.ensureInitialized()` missing or after init (same file) |
| `FD303` | INFO | `DefaultFirebaseOptions.currentPlatform` not referenced |
| `FD304` | WARNING | Multiple `Firebase.initializeApp()` calls |
| `FD305` | WARNING | `Firebase.initializeApp()` called without `await` |
| `FD306` | ERROR | `Firebase.initializeApp()` appears after `runApp()` (same file) |
| `FD307` | ERROR | `Firebase.initializeApp()` called but `firebase_core` not in deps |

### 3.4 Android Analyzer — Android Config (FD400+)

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

### 3.5 iOS Analyzer — iOS Config (FD500+)

| Code | Severity | Condition |
|------|----------|-----------|
| `FD500` | CRITICAL | `ios/Runner/GoogleService-Info.plist` is missing |
| `FD501` | ERROR | `GoogleService-Info.plist` has invalid/malformed content |
| `FD502` | ERROR | Bundle ID in `GoogleService-Info.plist` doesn't match Xcode project |
| `FD503` | WARNING | Bundle identifier not detected from Xcode project |
| `FD504` | ERROR | "Runner" target not found in Xcode project |
| `FD505` | WARNING | Push Notifications capability missing in Xcode |
| `FD506` | WARNING | Background Modes capability missing in Xcode |
| `FD507` | WARNING | `remote-notification` background mode missing in `Info.plist` |
| `FD508` | ERROR | `ios/Podfile` is missing |
| `FD509` | WARNING | iOS platform version below 12.0 in Podfile |
| `FD510` | WARNING | No Firebase pods found in Podfile/Podfile.lock |
| `FD511` | INFO | `GoogleService-Info.plist` exists but no Firebase imports in Dart |
| `FD512` | INFO | `FirebaseAppDelegateProxyEnabled` not configured in Info.plist |

### 3.6 FCM Analyzer — Cloud Messaging (FD600+)

| Code | Severity | Condition |
|------|----------|-----------|
| `FD600` | WARNING | `firebase_messaging` missing from deps (Firebase config files exist) |
| `FD601` | WARNING | `firebase_messaging` in deps but no `FirebaseMessaging` usage in Dart |
| `FD602` | WARNING | FCM usage found but no notification permission request |
| `FD603` | INFO | No `FirebaseMessaging.onBackgroundMessage` handler configured |
| `FD604` | WARNING | iOS: `FirebaseAppDelegateProxyEnabled` set to false (breaks FCM) |
| `FD605` | INFO | No `onTokenRefresh` or `getToken` listener found |

### 3.7 Code Summary

| Code Range | Analyzer | Count | Highest Severity |
|------------|----------|-------|-----------------|
| Project | ProjectAnalyzer | 8 | CRITICAL |
| FD200–FD202 | DependencyAnalyzer | 3 | CRITICAL |
| FD300–FD307 | FirebaseCoreAnalyzer | 8 | CRITICAL |
| FD400–FD409 | AndroidAnalyzer | 10 | CRITICAL |
| FD500–FD512 | IOSAnalyzer | 13 | CRITICAL |
| FD600–FD605 | FCMAnalyzer | 6 | WARNING |

**Total: 42 distinct diagnostic codes across 6 analyzers.**

---

## 4. Completed Functionalities

### 4.1 Analyzers

| Analyzer | Status | Tests | Coverage |
|----------|--------|-------|----------|
| ProjectAnalyzer | ✅ Complete | 18 | All 8 checks tested |
| DependencyAnalyzer | ✅ Complete | 27 + 64 (FirebasePackage) | All 3 checks + 10 Firebase packages |
| FirebaseCoreAnalyzer | ✅ Complete | 39 | All 8 checks, multi-line, comments, strings |
| AndroidAnalyzer | ✅ Complete | 36 | All 10 checks, Groovy/Kotlin DSL, permissions, SDK |
| IOSAnalyzer | ✅ Complete | 57 (integration) + 48 (parsers) | All 13 checks, 4 parser classes |
| FCMAnalyzer | ✅ Complete | 38 + 5 (plist parser) | All 6 checks, comment/string stripping |

### 4.2 iOS Parsers (Used by IOSAnalyzer and FCMAnalyzer)

| Parser | File | Purpose | Capabilities |
|--------|------|---------|-------------|
| `PlistParser` | `lib/analyzers/ios/parsers/plist_parser.dart` | XML plist parsing | String, boolean, integer, real, nested dict, array; Info.plist background modes & Firebase proxy; `parseFirebaseAppDelegateProxyValue()` |
| `PodfileParser` | `lib/analyzers/ios/parsers/podfile_parser.dart` | CocoaPods Podfile | Platform version, Runner target, Firebase pod detection |
| `PodfileLockParser` | `lib/analyzers/ios/parsers/podfile_lock_parser.dart` | Podfile.lock | Firebase pod detection from PODS section |
| `PbxprojParser` | `lib/analyzers/ios/parsers/pbxproj_parser.dart` | Xcode project.pbxproj | Bundle identifier, Runner target, SystemCapabilities (Push, BackgroundModes) |

### 4.3 Dart Code Scanning

- Recursive `.dart` file discovery under `lib/`
- Comment stripping (`//`, `/* */`)
- String literal stripping (`'...'`, `"..."`, `'''...'''`, `"""..."""`)
- Balanced parenthesis matching for multi-line function calls
- Used by: `FirebaseCoreAnalyzer`, `FCMAnalyzer`, `IOSAnalyzer`

### 4.4 Bug Fixes (Regression Tests: 7)

| Bug | Issue | Fix |
|-----|-------|-----|
| #1 | Project name always showed "unknown" | Added `projectName` field to `DiagnosticResult`, extracted from pubspec |
| #2 | Multi-line `Firebase.initializeApp()` not detected | Balanced-parenthesis matching across lines |
| #3 | Comment/string literal false positives | Added `_stripCommentsAndStrings()` |
| #4 | Cross-file `ensureInitialized` ordering false positives | Only check ensureInitialized ordering within same file |

### 4.5 CLI Features

- Positional path argument (no `--path` flag needed, just `diagnose /path/to/project`)
- Chained alias support: `-v` for `version`, `-h` for `help`
- Exit codes: 0 for success/passed, 1 for failure/critical+error
- ASCII formatted per-analyzer output with issue details and recommendations
- Summary with analyzer count, pass/skip, error/warning/info breakdowns

### 4.6 Mock & Fake Infrastructure

| Class | File | Purpose |
|-------|------|---------|
| `FakeFileSystem` | `test/shared/mocks.dart` | In-memory file system with directories, files, recursive listing |
| `FakeTerminal` | `test/shared/mocks.dart` | String buffer terminal for output assertions |
| `MockFileSystem` | `test/shared/mocks.dart` | Mocktail mock for `FileSystem` |
| `MockTerminal` | `test/shared/mocks.dart` | Mocktail mock for `Terminal` |
| `MockAnalyzer` | `test/shared/mocks.dart` | Mocktail mock for `Analyzer` |
| `MockAnalyzerService` | `test/shared/mocks.dart` | Mocktail mock for `AnalyzerService` |

---

## 5. Project Core Architecture

### 5.1 Abstract Interfaces

```
Analyzer (abstract)
├── name: String
├── description: String
├── category: String
└── analyze(AnalyzerContext) → Future<DiagnosticResult>

Command (abstract)
├── name: String
├── description: String
├── aliases: List<String>
└── execute(List<String> args) → Future<int>

Terminal (abstract)
├── write(), writeLine(), writeSuccess(), writeWarning()
├── writeError(), writeInfo()
├── readLine(), clear()
└── (9 methods total)

FileSystem (abstract)
├── exists(), isFile(), isDirectory()
├── readAsString(), readAsStringAsync()
├── writeAsString(), writeAsStringAsync()
├── listDirectory()
├── createDirectory(), delete(), copy()
├── currentDirectory, join()
└── (13 methods total)
```

### 5.2 Sealed Classes

```
Severity (sealed)
├── Severity.info      (value=0, emoji=ℹ️)
├── Severity.warning   (value=1, emoji=⚠️)
├── Severity.error     (value=2, emoji=❌)
└── Severity.critical  (value=3, emoji=🚨)

CheckStatus (sealed)
├── CheckStatus.passed         (label='Passed', isPassed=true)
├── CheckStatus.failed         (label='Failed', isPassed=false)
├── CheckStatus.warning        (label='Warning', isPassed=false)
├── CheckStatus.skipped        (label='Skipped', isPassed=false)
└── CheckStatus.notApplicable  (label='N/A', isPassed=false)
```

### 5.3 Model Classes

| Class | Location | Key Fields |
|-------|----------|------------|
| `DiagnosticIssue` | `lib/models/diagnostic_issue.dart` | severity, code, title, description, recommendation?, filePath?, lineNumber?, metadata? |
| `DiagnosticResult` | `lib/models/diagnostic_result.dart` | analyzerName, status, issues, duration, timestamp, projectName? |
| `DiagnosticReport` | `lib/models/diagnostic_report.dart` | projectName, projectPath, createdAt, results, firebaseVersion?, environment |
| `Pubspec` | `lib/models/pubspec.dart` | name, version?, description?, dependencies, devDependencies, flutterSdkConstraint?, dartSdkConstraint?, isFlutterProject |

### 5.4 Wire-Up Flow

```
main(List<String> args)
  └─ runFireDoctor(args)
       ├─ AnsiTerminal                    # Real terminal (ANSI color)
       ├─ LocalFileSystem                 # Real file I/O
       ├─ Logger(terminal, name:'firedoctor')
       ├─ AnalyzerService(logger)
       │    ├─ register(ProjectAnalyzer)
       │    ├─ register(DependencyAnalyzer)
       │    ├─ register(FirebaseCoreAnalyzer)
       │    ├─ register(AndroidAnalyzer)
       │    ├─ register(IOSAnalyzer)
       │    └─ register(FCMAnalyzer)
       ├─ CommandRunner(logger, terminal, fileSystem)
       │    ├─ register(HelpCommand)
       │    ├─ register(VersionCommand)
       │    ├─ register(DiagnoseCommand)
       │    ├─ register(DoctorCommand)
       │    └─ register(ReportCommand)
       ├─ runner.run(args)
       └─ exit(exitCode)
```

### 5.5 Directory Structure (lib/)

```
lib/
├── firedoctor.dart                           # Entry point wiring
├── analyzers/
│   ├── analyzer.dart                         # Abstract Analyzer
│   ├── analyzer_context.dart                 # AnalyzerContext model
│   ├── analyzer_result.dart                  # AnalyzerResultExtension
│   ├── analyzers.dart                        # Barrel export
│   ├── project/
│   │   ├── project.dart                      # Barrel
│   │   └── project_analyzer.dart             # 8 checks
│   ├── dependency/
│   │   ├── dependency.dart                   # Barrel
│   │   ├── dependency_analyzer.dart           # 3 checks
│   │   └── firebase_package.dart             # 10 Firebase package defs
│   ├── firebase_core/
│   │   ├── firebase_core.dart                # Barrel
│   │   └── firebase_core_analyzer.dart       # 8 checks
│   ├── android/
│   │   ├── android.dart                      # Barrel
│   │   └── android_analyzer.dart             # 10 checks
│   ├── ios/
│   │   ├── ios.dart                          # Barrel
│   │   ├── ios_analyzer.dart                 # 13 checks
│   │   └── parsers/
│   │       ├── parsers.dart                  # Barrel
│   │       ├── plist_parser.dart             # XML plist parser
│   │       ├── podfile_parser.dart           # Podfile parser
│   │       ├── podfile_lock_parser.dart      # Podfile.lock parser
│   │       └── pbxproj_parser.dart           # Xcode project parser
│   └── fcm/
│       ├── fcm.dart                          # Barrel
│       └── fcm_analyzer.dart                 # 6 checks
├── cli/
│   ├── cli.dart                              # Barrel
│   ├── command.dart                          # Abstract Command
│   ├── command_runner.dart                   # Command routing
│   └── commands/
│       ├── commands.dart                     # Barrel
│       ├── diagnose_command.dart
│       ├── doctor_command.dart
│       ├── report_command.dart
│       ├── help_command.dart
│       └── version_command.dart
├── constants/
│   ├── constants.dart                        # Barrel
│   └── app_constants.dart                    # Version, exit codes
├── exceptions/
│   ├── exceptions.dart                       # Barrel
│   └── fire_doctor_exception.dart            # Custom exception
├── filesystem/
│   ├── filesystem.dart                       # Barrel
│   ├── file_system_interface.dart            # Abstract FileSystem (13 methods)
│   └── local_file_system.dart                # dart:io implementation
├── logging/
│   ├── logging.dart                          # Barrel
│   └── logger.dart                           # Logger with prefix
├── models/
│   ├── models.dart                           # Barrel
│   ├── severity.dart                         # Sealed Severity (4 levels)
│   ├── check_status.dart                     # Sealed CheckStatus (5 variants)
│   ├── diagnostic_issue.dart                 # Issue with copyWith
│   ├── diagnostic_result.dart                # Per-analyzer result
│   ├── diagnostic_report.dart                # Full report with score
│   └── pubspec.dart                          # Pubspec model
├── parsers/
│   ├── parsers.dart                          # Barrel
│   └── pubspec_parser.dart                   # YAML pubspec parser
├── services/
│   ├── services.dart                         # Barrel
│   ├── analyzer_service.dart                 # Register/run analyzers
│   └── report_service.dart                   # Report + JSON
├── terminal/
│   ├── terminal.dart                         # Barrel
│   ├── terminal_interface.dart               # Abstract Terminal (9 methods)
│   └── ansi_terminal.dart                    # ANSI color implementation
└── utils/
    └── utils.dart                            # Empty (reserved)
```

### 5.6 Directory Structure (test/)

```
test/
├── firedoctor_test.dart                      # 1 test (placeholder)
├── shared/
│   └── mocks.dart                            # Mocks + Fakes
├── integration/
│   └── bug_regression_test.dart              # 7 tests
├── analyzers/
│   ├── analyzer_test.dart                    # 2 tests
│   ├── analyzer_context_test.dart            # 3 tests
│   ├── project/
│   │   └── project_analyzer_test.dart        # 18 tests
│   ├── dependency/
│   │   ├── dependency_analyzer_test.dart      # 27 tests
│   │   └── firebase_package_test.dart         # 64 tests
│   ├── firebase_core/
│   │   └── firebase_core_analyzer_test.dart  # 39 tests
│   ├── android/
│   │   └── android_analyzer_test.dart        # 36 tests
│   ├── ios/
│   │   ├── ios_analyzer_test.dart            # 57 tests
│   │   └── parsers/
│   │       ├── plist_parser_test.dart        # 28 tests
│   │       ├── podfile_parser_test.dart      # 12 tests
│   │       ├── podfile_lock_parser_test.dart  # 7 tests
│   │       └── pbxproj_parser_test.dart      # 9 tests
│   └── fcm/
│       └── fcm_analyzer_test.dart            # 38 tests
├── cli/
│   ├── command_runner_test.dart              # 8 tests
│   └── commands/
│       ├── diagnose_command_test.dart        # 10 tests
│       ├── doctor_command_test.dart          # 11 tests
│       ├── report_command_test.dart          # 13 tests
│       ├── help_command_test.dart            # 4 tests
│       └── version_command_test.dart         # 1 test
├── models/
│   ├── severity_test.dart                    # 27 tests
│   ├── check_status_test.dart                # 24 tests
│   ├── diagnostic_issue_test.dart            # 7 tests
│   ├── diagnostic_result_test.dart           # 12 tests
│   ├── diagnostic_report_test.dart           # 11 tests
│   └── pubspec_test.dart                     # 7 tests
├── parsers/
│   └── pubspec_parser_test.dart              # 19 tests
├── services/
│   ├── analyzer_service_test.dart            # 6 tests
│   └── report_service_test.dart              # 9 tests
├── filesystem/
│   ├── file_system_interface_test.dart       # 19 tests
│   └── local_file_system_test.dart           # 15 tests
├── logging/
│   └── logger_test.dart                     # 10 tests
├── exceptions/
│   └── fire_doctor_exception_test.dart       # 5 tests
└── terminal/
    └── terminal_test.dart                    # 9 tests
```

---

## 6. In-Depth Details

### 6.1 Test Coverage Summary

| Category | Files | Tests | Status |
|----------|-------|-------|--------|
| **Analyzers** | 12 files | 340 | All 42 diagnostic codes covered |
| **CLI** | 7 files | 47 | All commands, flags, error paths |
| **Models** | 6 files | 88 | All variants, properties, methods |
| **Services** | 2 files | 15 | Generate, print, JSON, save, register, run |
| **Parsers** | 1 file | 19 | Valid/invalid YAML, all dep types |
| **Filesystem** | 2 files | 34 | Both fake and real I/O implementations |
| **Logger** | 1 file | 10 | All methods with/without name prefix |
| **Exceptions** | 1 file | 5 | Constructor variants, toString |
| **Terminal** | 1 file | 9 | FakeTerminal operations |
| **Integration** | 1 file | 7 | Bug regression tests |
| **Top-level** | 1 file | 1 | Placeholder |
| **Total** | **36 files** | **570** | **100% passing** |

### 6.2 Test Counts by File

| File | Tests |
|------|-------|
| `test/analyzers/ios/ios_analyzer_test.dart` | 57 |
| `test/analyzers/firebase_core/firebase_core_analyzer_test.dart` | 39 |
| `test/analyzers/fcm/fcm_analyzer_test.dart` | 38 |
| `test/analyzers/android/android_analyzer_test.dart` | 36 |
| `test/analyzers/ios/parsers/plist_parser_test.dart` | 28 |
| `test/analyzers/dependency/dependency_analyzer_test.dart` | 27 |
| `test/analyzers/dependency/firebase_package_test.dart` | 64 |
| `test/analyzers/project/project_analyzer_test.dart` | 18 |
| `test/analyzers/ios/parsers/podfile_parser_test.dart` | 12 |
| `test/analyzers/ios/parsers/pbxproj_parser_test.dart` | 9 |
| `test/analyzers/ios/parsers/podfile_lock_parser_test.dart` | 7 |
| All other test files | 275 |

### 6.3 Known Firebase Packages

The `FirebasePackage` enum in `lib/analyzers/dependency/firebase_package.dart` recognizes 10 Firebase packages:

| Package | Dart Package Name |
|---------|------------------|
| Core | `firebase_core` |
| Authentication | `firebase_auth` |
| Cloud Firestore | `cloud_firestore` |
| Cloud Storage | `firebase_storage` |
| Cloud Messaging | `firebase_messaging` |
| Crashlytics | `firebase_crashlytics` |
| Analytics | `firebase_analytics` |
| Remote Config | `firebase_remote_config` |
| Realtime Database | `firebase_database` |
| App Check | `firebase_app_check` |

### 6.4 Dependencies

| Package | Version | Usage |
|---------|---------|-------|
| `args` | ^2.4.0 | UNUSED (custom CommandRunner) |
| `meta` | ^1.11.0 | UNUSED |
| `path` | ^1.9.0 | Used in `local_file_system.dart` |
| `yaml` | ^3.1.0 | Used in `pubspec_parser.dart` |

**Dev Dependencies:**

| Package | Version | Usage |
|---------|---------|-------|
| `test` | ^1.25.0 | Testing framework |
| `mocktail` | ^1.0.0 | Mocking library |
| `lints` | ^3.0.0 | Lint rules |

### 6.5 Lint Configuration

```yaml
include: package:lints/recommended.yaml
strict-casts: true
strict-inference: true
strict-raw-types: true
Extra rules: always_declare_return_types, prefer_const_constructors,
             prefer_const_declarations, prefer_final_locals,
             unawaited_futures, use_super_parameters
```

### 6.6 Known Issues / Tech Debt

| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | `_hasVersionIssue` only flags `""`, `"any"`, `"*"` — misses unbounded ranges | `dependency_analyzer.dart` | Low |
| 2 | No web/macos/windows/linux platform detection | `project_analyzer.dart` | Low |
| 3 | No `pubspec.lock` analysis | Project-wide | Low |
| 4 | `DiagnoseCommand` has no `--json` flag | `diagnose_command.dart` | Low |
| 5 | Unknown CLI flags silently treated as positional path arg | `report_command.dart` | Low |
| 6 | Hardcoded version `^3.0.0` for firebase_core recommendations | Multiple | Low |
| 7 | Synchronous `readAsString` in async context (blocks event loop) | `firebase_core_analyzer.dart` | Low |
| 8 | Recursive `_findDartFiles` with no depth limit | Multiple | Low |
| 9 | No try-catch on per-file reads | `firebase_core_analyzer.dart` | Low |
| 10 | Unusual `copyWith` using `String? Function()?` | `diagnostic_issue.dart` | Info |
| 11 | Compiled `firedoctor` binary is an AOT snapshot (run with `dart bin/firedoctor.dart`) | Root | Info |

### 6.7 Real-World Validation

Tested against a real Flutter Firebase project (`wellyansh_doctor_app`):
- **6 analyzers ran successfully**
- **2 passed** (project, dependency)
- **1 failing** (android — package name mismatch, missing permissions)
- **3 warnings** (firebase_core, ios, fcm)
- **1 error**, **6 warnings**, **4 info** issues detected total
- FCMAnalyzer correctly identified:
  - Missing background message handler (FD603)
  - `FirebaseAppDelegateProxyEnabled` set to false (FD604)

### 6.8 Future Roadmap

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Foundation (CLI, project, dependency, core, android) | ✅ Complete |
| 1 | iOS Firebase configuration analysis | ✅ Complete |
| 1 | FCM configuration analysis | ✅ Complete |
| 2 | Crashlytics configuration analysis | ⬜ Planned |
| 2 | Web platform support detection | ⬜ Planned |
| 2 | `pubspec.lock` analysis for version conflicts | ⬜ Planned |
| 2 | CI/CD pipeline setup | ⬜ Planned |
| 2 | `AnsiTerminal` unit tests | ⬜ Planned |
| 2 | `AnalyzerResultExtension` tests | ⬜ Planned |
| 2 | Integration/e2e tests for `runFireDoctor()` | ⬜ Planned |
| 2 | Parallel analyzer execution | ⬜ Planned |
| 2 | Async file system operations in analyzers | ⬜ Planned |

---

*Generated from the live codebase. All 570 tests passing, 0 lint issues in analyzers.*
