# FireDoctor - Complete Project Documentation

> **Version:** 0.1.0  
> **Repository:** https://github.com/firedoctor-cli/firedoctor  
> **License:** MIT  
> **Last Updated:** 2026-06-12

---

## Table of Contents

1. [Project Summary](#1-project-summary)
2. [Project Overview](#2-project-overview)
3. [Project Features](#3-project-features)
4. [Project Errors & Diagnostic Codes](#4-project-errors--diagnostic-codes)
5. [Project Completed Functionalities](#5-project-completed-functionalities)
6. [Project Core - Architecture & In-Depth Details](#6-project-core---architecture--in-depth-details)

---

## 1. Project Summary

FireDoctor is a **production-grade CLI tool** written in Dart that diagnoses Firebase configuration and setup issues in Flutter projects. It runs 7 specialized analyzers covering the entire Firebase integration surface — from project structure and dependencies to Android, iOS, FCM, and Crashlytics configurations. Each analyzer produces detailed diagnostic results with severity-graded issues, actionable recommendations, and file-level locations.

The tool features a **Health Score Engine v2** that computes weighted category scores, priority-grouped issue breakdowns, and ranked recommendations. It outputs both human-readable terminal reports and machine-readable JSON with a comprehensive `healthScore` block.

**Key Metrics:**
- 7 analyzers, 56 diagnostic codes
- 39 test files, 656 individual test cases
- 100% test pass rate
- Real-world validated against production Flutter Firebase projects

---

## 2. Project Overview

### 2.1 Purpose

FireDoctor helps Flutter developers identify, prioritize, and fix Firebase misconfigurations before they cause production issues. It checks for:

- Missing or misconfigured Firebase configuration files
- Incorrect dependency versions and placements
- Platform-specific issues (Android Gradle, iOS Xcode/Podfile)
- Missing Firebase Cloud Messaging setup
- Missing or incomplete Crashlytics integration
- Firebase Core initialization problems

### 2.2 Target Audience

- Flutter developers using Firebase services
- CI/CD pipelines needing automated Firebase configuration validation
- Teams migrating or onboarding Firebase into existing Flutter projects

### 2.3 Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | Dart (SDK >=3.0.0, <4.0.0) |
| CLI Framework | Custom `Command`/`CommandRunner` |
| YAML Parsing | `yaml` package |
| Argument Parsing | `args` package |
| Testing | `test` + `mocktail` |
| Linting | `lints` recommended rules |
| Strict Mode | `strict-casts`, `strict-inference`, `strict-raw-types` |

### 2.4 Project Structure

```
firedoctor-flutter/
├── bin/
│   └── firedoctor.dart          # Entry point
├── lib/
│   ├── firedoctor.dart          # Main library, exports, runFireDoctor()
│   ├── analyzers/
│   │   ├── analyzer.dart        # Abstract Analyzer base class
│   │   ├── analyzer_context.dart # Analysis context (path, FS, config)
│   │   ├── analyzer_result.dart  # Extension helpers on DiagnosticResult
│   │   ├── project/             # ProjectAnalyzer (8 checks)
│   │   ├── dependency/          # DependencyAnalyzer (3 checks)
│   │   ├── firebase_core/       # FirebaseCoreAnalyzer (8 checks)
│   │   ├── android/             # AndroidAnalyzer (10 checks)
│   │   ├── ios/                 # IOSAnalyzer (13 checks)
│   │   │   └── parsers/         # PlistParser, PodfileParser, PodfileLockParser, PbxprojParser
│   │   ├── fcm/                 # FCMAnalyzer (6 checks)
│   │   └── crashlytics/         # CrashlyticsAnalyzer (14 checks)
│   ├── cli/
│   │   ├── command.dart         # Abstract Command base class
│   │   ├── command_runner.dart   # CLI command routing
│   │   └── commands/            # diagnose, doctor, report, help, version
│   ├── constants/
│   │   └── app_constants.dart   # Version, exit codes, URLs
│   ├── exceptions/
│   │   └── fire_doctor_exception.dart
│   ├── filesystem/
│   │   ├── file_system_interface.dart  # Abstract FileSystem
│   │   └── local_file_system.dart      # Real file system implementation
│   ├── logging/
│   │   └── logger.dart          # Logger with terminal output
│   ├── models/
│   │   ├── severity.dart        # Severity sealed class (info/warning/error/critical)
│   │   ├── check_status.dart    # CheckStatus sealed class (passed/failed/warning/skipped/na)
│   │   ├── diagnostic_issue.dart # Single issue with severity, code, location
│   │   ├── diagnostic_result.dart # Per-analyzer results
│   │   ├── diagnostic_report.dart # Aggregated report with health score
│   │   ├── pubspec.dart         # Parsed pubspec model
│   │   ├── score_weights.dart   # Configurable severity weights
│   │   └── health_score.dart    # HealthScore, CategoryScore, Recommendation, PriorityGroup
│   ├── parsers/
│   │   └── pubspec_parser.dart  # pubspec.yaml parser
│   ├── services/
│   │   ├── analyzer_service.dart # Runs all registered analyzers
│   │   ├── report_service.dart   # Generates/prints/saves reports
│   │   └── health_score_engine.dart # Computes health scores
│   └── terminal/
│       ├── terminal_interface.dart # Abstract Terminal
│       └── ansi_terminal.dart      # ANSI-colored terminal output
├── test/
│   ├── analyzers/               # Analyzer-specific tests
│   ├── cli/                     # CLI command tests
│   ├── exceptions/              # Exception tests
│   ├── filesystem/              # File system tests
│   ├── integration/             # Integration/bug regression tests
│   ├── logging/                 # Logger tests
│   ├── models/                  # Model tests (severity, check_status, issues, reports, health_score, score_weights)
│   ├── parsers/                 # Parser tests
│   ├── services/                # Service tests (analyzer_service, report_service, health_score_engine)
│   ├── shared/mocks.dart        # Shared mock helpers
│   └── terminal/                # Terminal tests
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 3. Project Features

### 3.1 CLI Commands

| Command | Aliases | Description |
|---------|---------|-------------|
| `diagnose <path>` | — | Run Firebase diagnostics; prints issues per analyzer with summary |
| `doctor <path>` | — | Run all checks and generate formatted report with health scores |
| `report <path>` | — | Generate detailed JSON or terminal report (supports `--json`, `--output`) |
| `version` | `v`, `-v`, `--version` | Print version |
| `help [command]` | `h`, `-h`, `--help` | Show help |

### 3.2 Diagnostic Checklists

#### ProjectAnalyzer (8 checks)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| MISSING_PUBSPEC | critical | pubspec.yaml exists | Verifies the project has a pubspec.yaml |
| INVALID_PUBSPEC | critical | pubspec.yaml is valid YAML | Parses pubspec.yaml |
| NOT_FLUTTER_PROJECT | warning | Flutter dependency declared | Checks if `flutter` is in dependencies |
| MISSING_ANDROID | warning | android/ directory exists | Checks Android platform directory |
| MISSING_IOS | warning | ios/ directory exists | Checks iOS platform directory |
| MISSING_LIB | error | lib/ directory exists | Checks Dart source directory |
| MISSING_TEST | info | test/ directory exists | Suggests adding tests |
| FLUTTER_SDK_CONSTRAINT | info | Flutter SDK constraint in pubspec | Reports Flutter SDK version constraint |

#### DependencyAnalyzer (3 checks — FD200–FD202)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| FD200 | critical | firebase_core present with other Firebase packages | Prevents missing core dependency |
| FD201 | error | Firebase packages in proper section | Detects Firebase packages in dev_dependencies instead of dependencies |
| FD202 | warning | Loose version constraints | Detects `any`, `*`, or empty version constraints |

#### FirebaseCoreAnalyzer (8 checks — FD300–FD307)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| FD300 | critical | Firebase.initializeApp() called | No init call found with firebase_core installed |
| FD301 | warning | firebase_options.dart exists | Generated options file missing |
| FD302 | error | WidgetsFlutterBinding.ensureInitialized() before init | Required for plugin initialization |
| FD303 | info | DefaultFirebaseOptions.currentPlatform used | Platform-specific options not referenced |
| FD304 | warning | Single Firebase.initializeApp() call | Multiple init calls detected |
| FD305 | warning | Firebase.initializeApp() awaited | Non-awaited init call |
| FD306 | error | Firebase.initializeApp() before runApp() | Init called after runApp |
| FD307 | error | firebase_core dependency present | Init call but no dependency declared |

#### AndroidAnalyzer (10 checks — FD400–FD409)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| FD400 | critical | google-services.json exists | Missing Android Firebase config |
| FD401 | error | google-services.json is valid JSON | Invalid JSON content |
| FD402 | error | Package name matches build.gradle | Mismatch between google-services.json and applicationId |
| FD403 | error | google-services Gradle plugin applied | Missing `com.google.gms.google-services` plugin |
| FD404 | error | INTERNET permission declared | Missing required permission |
| FD405 | warning | POST_NOTIFICATIONS permission declared | Required for Android 13+ |
| FD406 | info | WAKE_LOCK permission declared | Recommended for FCM |
| FD407 | warning | compileSdk >= 34 | Outdated compile SDK |
| FD408 | info | minSdk >= 21 | Below firebase_core minimum |
| FD409 | warning | targetSdk >= 34 | Outdated target SDK |

#### IOSAnalyzer (13 checks — FD500–FD512)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| FD500 | critical | GoogleService-Info.plist exists | Missing iOS Firebase config |
| FD501 | error | GoogleService-Info.plist is valid | Invalid plist content |
| FD502 | error | Bundle ID matches Xcode project | Mismatch between plist and PRODUCT_BUNDLE_IDENTIFIER |
| FD503 | warning | Bundle identifier detectable | Cannot detect bundle ID from Xcode project |
| FD504 | error | Runner target exists | Missing Runner target in Xcode project |
| FD505 | warning | Push Notifications capability enabled | Missing capability |
| FD506 | warning | Background Modes capability enabled | Missing capability |
| FD507 | warning | Remote Notification background mode configured | Missing UIBackgroundModes entry |
| FD508 | error | Podfile exists | Missing Podfile |
| FD509 | warning | iOS platform version >= 12.0 | Below Firebase SDK minimum |
| FD510 | warning | Firebase pods detected | No Firebase pods in Podfile/Podfile.lock |
| FD511 | info | GoogleService-Info.plist referenced in Dart | Plist exists but no Firebase imports |
| FD512 | info | FirebaseAppDelegateProxyEnabled configured | APNs configuration missing |

#### FCMAnalyzer (6 checks — FD600–FD605)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| FD600 | warning | firebase_messaging dependency | Config files exist but no FCM package |
| FD601 | warning | FCM used in Dart code | Package declared but not used |
| FD602 | warning | Notification permission requested | Missing permission request for iOS/Android 13+ |
| FD603 | info | Background message handler configured | Missing onBackgroundMessage handler |
| FD604 | warning | FirebaseAppDelegateProxyEnabled not false | Proxy disabled breaks FCM |
| FD605 | info | FCM token refresh listener | Missing onTokenRefresh/getToken |

#### CrashlyticsAnalyzer (14 checks — FD700–FD713)
| Code | Severity | Check | Description |
|------|----------|-------|-------------|
| FD700 | warning | firebase_crashlytics dependency | Missing Crashlytics package |
| FD701 | warning | Crashlytics used in Dart code | Package declared but not used |
| FD702 | error | FlutterError.onError forwarded to Crashlytics | Missing global Flutter error handler |
| FD703 | error | PlatformDispatcher.onError configured | Missing platform error handler |
| FD704 | warning | runZonedGuarded used | Missing error zone for async errors |
| FD705 | info | Crashlytics collection enabled explicitly | Collection config verified |
| FD706 | warning | recordError usage detected | No explicit error reporting |
| FD707 | info | Fatal error reporting strategy present | No error reporting strategy at all |
| FD708 | error | Crashlytics Gradle plugin applied | Missing Android Gradle plugin |
| FD709 | info | Crashlytics build configuration present | Missing firebaseCrashlytics block |
| FD710 | error | Crashlytics CocoaPods pod present | Missing iOS pod |
| FD711 | info | dSYM upload configured | Missing dSYM upload for crash symbolication |
| FD712 | info | Custom keys usage detected | Missing setCustomKey for crash context |
| FD713 | info | User identification strategy detected | Missing setUserIdentifier |

### 3.3 Health Score Engine v2

#### ScoreWeights (Configurable)
| Severity | Default Weight |
|----------|---------------|
| critical | 25 |
| error | 15 |
| warning | 5 |
| info | 1 |
| **Max per issue** | **25** |

#### Category Scores (0–100)
| Category | Display Name |
|----------|-------------|
| project | Project Health |
| dependency | Dependencies Health |
| firebase_core | Firebase Core Health |
| android | Android Health |
| ios | iOS Health |
| fcm | Messaging Health |
| crashlytics | Crashlytics Health |

#### Priority Groups
| Group | Source Severity |
|-------|----------------|
| Critical Fixes | critical |
| High Priority | error |
| Medium Priority | warning |
| Low Priority | info |

#### Recommendations
- Top N issues sorted by weight descending (default: top 3)
- Ties broken by code lexicographic order
- Formatted as `Fix CODE: TITLE`

#### Score Formula (per category)
```
score = ((maxWeight - totalWeight) / maxWeight) * 100
```
where:
- `maxWeight = issueCount * maxScorePerIssue (25)`
- `totalWeight = sum of weights for each issue in category`
- Result clamped to [0, 100]

### 3.4 Output Formats

**Terminal (human-readable):**
- Color-coded severity icons (ℹ️ ⚠️ ❌ 🚨)
- Category score bars (█░)
- Priority breakdown
- Top N recommended next actions

**JSON (machine-readable):**
- Full issue details with severity, code, description, recommendation, filePath, lineNumber
- `healthScore` block with `overallScore`, `categoryScores`, `priorityGroups`, `recommendations`
- Compatible with CI/CD pipeline parsing

---

## 4. Project Errors & Diagnostic Codes

### 4.1 Complete Error Code Index (56 codes)

| Code | Analyzer | Severity | Summary |
|------|----------|----------|---------|
| MISSING_PUBSPEC | project | critical | pubspec.yaml not found |
| INVALID_PUBSPEC | project | critical | pubspec.yaml is invalid YAML |
| NOT_FLUTTER_PROJECT | project | warning | No Flutter dependency |
| MISSING_ANDROID | project | warning | android/ directory missing |
| MISSING_IOS | project | warning | ios/ directory missing |
| MISSING_LIB | project | error | lib/ directory missing |
| MISSING_TEST | project | info | test/ directory missing |
| FLUTTER_SDK_CONSTRAINT | project | info | Flutter SDK constraint |
| FD200 | dependency | critical | Missing firebase_core with other Firebase packages |
| FD201 | dependency | error | Firebase package in dev_dependencies |
| FD202 | dependency | warning | Loose version constraint |
| FD300 | firebase_core | critical | Firebase not initialized |
| FD301 | firebase_core | warning | Missing firebase_options.dart |
| FD302 | firebase_core | error | Missing WidgetsFlutterBinding.ensureInitialized() |
| FD303 | firebase_core | info | DefaultFirebaseOptions not used |
| FD304 | firebase_core | warning | Multiple Firebase.initializeApp() calls |
| FD305 | firebase_core | warning | Firebase.initializeApp() not awaited |
| FD306 | firebase_core | error | Firebase.initializeApp() after runApp() |
| FD307 | firebase_core | error | Missing firebase_core dependency |
| FD400 | android | critical | Missing google-services.json |
| FD401 | android | error | Invalid google-services.json |
| FD402 | android | error | Package name mismatch |
| FD403 | android | error | Missing google-services plugin |
| FD404 | android | error | Missing INTERNET permission |
| FD405 | android | warning | Missing POST_NOTIFICATIONS permission |
| FD406 | android | info | Missing WAKE_LOCK permission |
| FD407 | android | warning | compileSdk below 34 |
| FD408 | android | info | minSdk below 21 |
| FD409 | android | warning | targetSdk below 34 |
| FD500 | ios | critical | Missing GoogleService-Info.plist |
| FD501 | ios | error | Invalid GoogleService-Info.plist |
| FD502 | ios | error | Bundle ID mismatch |
| FD503 | ios | warning | Bundle identifier not detected |
| FD504 | ios | error | Runner target not found |
| FD505 | ios | warning | Push Notifications capability missing |
| FD506 | ios | warning | Background Modes capability missing |
| FD507 | ios | warning | Remote Notifications background mode missing |
| FD508 | ios | error | Missing Podfile |
| FD509 | ios | warning | iOS platform version below 12.0 |
| FD510 | ios | warning | No Firebase pods found |
| FD511 | ios | info | GoogleService-Info.plist not referenced |
| FD512 | ios | info | APNs configuration warning |
| FD600 | fcm | warning | Missing firebase_messaging dependency |
| FD601 | fcm | warning | FCM not initialized in Dart code |
| FD602 | fcm | warning | Notification permission not requested |
| FD603 | fcm | info | No background message handler |
| FD604 | fcm | warning | FirebaseAppDelegateProxyEnabled set to false |
| FD605 | fcm | info | No FCM token refresh listener |
| FD700 | crashlytics | warning | Missing firebase_crashlytics dependency |
| FD701 | crashlytics | warning | Crashlytics not initialized |
| FD702 | crashlytics | error | FlutterError.onError not forwarded |
| FD703 | crashlytics | error | PlatformDispatcher.onError not configured |
| FD704 | crashlytics | warning | Missing runZonedGuarded |
| FD705 | crashlytics | info | Collection explicitly configured |
| FD706 | crashlytics | warning | No recordError usage |
| FD707 | crashlytics | info | No fatal error reporting strategy |
| FD708 | crashlytics | error | Missing Crashlytics Gradle plugin |
| FD709 | crashlytics | info | Missing Crashlytics build config |
| FD710 | crashlytics | error | Missing Crashlytics CocoaPods pod |
| FD711 | crashlytics | info | Missing dSYM upload config |
| FD712 | crashlytics | info | No custom keys usage |
| FD713 | crashlytics | info | No user identification strategy |

### 4.2 Severity Distribution

| Severity | Count |
|----------|-------|
| critical | 6 |
| error | 15 |
| warning | 20 |
| info | 15 |
| **Total** | **56** |

### 4.3 Analyzer Coverage Distribution

| Analyzer | Checks | Critical | Error | Warning | Info |
|----------|--------|----------|-------|---------|------|
| project | 8 | 2 | 1 | 3 | 2 |
| dependency | 3 | 1 | 1 | 1 | 0 |
| firebase_core | 8 | 1 | 2 | 3 | 2 |
| android | 10 | 1 | 4 | 3 | 2 |
| ios | 13 | 1 | 4 | 5 | 3 |
| fcm | 6 | 0 | 0 | 4 | 2 |
| crashlytics | 14 | 0 | 3 | 5 | 6 |

---

## 5. Project Completed Functionalities

### 5.1 Core Infrastructure
- ✅ CLI framework with command routing, help system, version command
- ✅ Abstract `Command` and `Analyzer` base classes
- ✅ Plugin-style analyzer registration via `AnalyzerService`
- ✅ Abstract `FileSystem` interface with `LocalFileSystem` implementation
- ✅ Abstract `Terminal` interface with `AnsiTerminal` supporting colors and NO_COLOR
- ✅ `Logger` service with info/success/warning/error level output
- ✅ `FireDoctorException` for typed error handling
- ✅ Strict analysis mode (`strict-casts`, `strict-inference`, `strict-raw-types`)

### 5.2 Models
- ✅ `Severity` sealed class (info, warning, error, critical) with name, label, emoji
- ✅ `CheckStatus` sealed class (passed, failed, warning, skipped, not_applicable)
- ✅ `DiagnosticIssue` with full metadata (severity, code, title, description, recommendation, filePath, lineNumber, metadata)
- ✅ `DiagnosticResult` per-analyzer results with status, issues, duration, timestamp
- ✅ `DiagnosticReport` aggregated report with health score integration, computed score getter
- ✅ `Pubspec` model with dependency checks
- ✅ `ScoreWeights` configurable weights with copyWith, weightFor, maxScorePerIssue
- ✅ `HealthScore` model with overallScore, categoryScores, priorityGroups, recommendations, toJson()
- ✅ `CategoryScore` with display name mapping and JSON serialization
- ✅ `Recommendation` with formatted getter and JSON serialization
- ✅ `PriorityGroup` enum (critical, high, medium, low) with severity mapping

### 5.3 Parsers
- ✅ `PubspecParser` — YAML-based pubspec.yaml parsing with dependency extraction
- ✅ `PlistParser` — GoogleService-Info.plist parsing, Info.plist background modes, FirebaseAppDelegateProxy detection
- ✅ `PodfileParser` — iOS version, Firebase pods, Runner target detection
- ✅ `PodfileLockParser` — Firebase pod detection from Podfile.lock
- ✅ `PbxprojParser` — Bundle identifier, Runner target, SystemCapabilities (Push, Background Modes)

### 5.4 Analyzers (7 total, 56 checks)
- ✅ **ProjectAnalyzer** — 8 checks on project structure and metadata
- ✅ **DependencyAnalyzer** — 3 checks on Firebase package dependencies
- ✅ **FirebaseCoreAnalyzer** — 8 checks on Firebase initialization (multi-line, comment/string stripping, balanced-parenthesis matching)
- ✅ **AndroidAnalyzer** — 10 checks covering Gradle (Groovy & Kotlin DSL), AndroidManifest, google-services.json
- ✅ **IOSAnalyzer** — 13 checks with 4 specialized parsers (95.8% iOS module coverage)
- ✅ **FCMAnalyzer** — 6 checks for Firebase Cloud Messaging configuration
- ✅ **CrashlyticsAnalyzer** — 14 checks for full Crashlytics setup (Dart, Android Gradle, iOS CocoaPods)

### 5.5 Services
- ✅ **AnalyzerService** — Analyzer registration, sequential execution, timing, error handling
- ✅ **ReportService** — Report generation with health score integration, terminal output with category bars, JSON serialization, file save
- ✅ **HealthScoreEngine** — Health score computation with configurable weights, category scores, priority groups, recommendations, overall score

### 5.6 Testing
- ✅ 39 test files, 656 individual test cases
- ✅ 100% pass rate
- ✅ Unit tests for all models, parsers, analyzers, services, CLI commands, filesystem, terminal, logging
- ✅ Integration/bug regression tests
- ✅ Shared mock helpers for test files

---

## 6. Project Core - Architecture & In-Depth Details

### 6.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      bin/firedoctor.dart                     │
│                     (Entry Point / main())                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    lib/firedoctor.dart                        │
│               (runFireDoctor() - Bootstrap)                   │
│  - Creates Terminal, FileSystem, Logger                      │
│  - Creates AnalyzerService + registers all 7 analyzers       │
│  - Creates CommandRunner + registers all 5 commands          │
│  - Routes CLI args to commands                               │
└─────────┬─────────────────────────────────┬─────────────────┘
          │                                 │
          ▼                                 ▼
┌──────────────────┐          ┌──────────────────────────────┐
│  CLI Layer        │          │  Analyzer Layer               │
│  (commands/)      │          │  (analyzers/)                 │
│                   │          │                               │
│  DiagnoseCommand  │◄────────►│  Each Analyzer implements:    │
│  DoctorCommand    │          │    analyze(AnalyzerContext)   │
│  ReportCommand    │          │    → DiagnosticResult         │
│  HelpCommand      │          │                               │
│  VersionCommand   │          │  AnalyzerContext provides:    │
│                   │          │    projectPath, FileSystem    │
│  Uses:            │          │                               │
│  - AnalyzerService│          │  Parsers used by analyzers:   │
│  - ReportService  │          │  - PubspecParser              │
└──────────────────┘          │  - PlistParser                │
                              │  - PodfileParser              │
                              │  - PodfileLockParser          │
                              │  - PbxprojParser              │
                              └───────────────┬───────────────┘
                                              │
                                              ▼
                              ┌──────────────────────────────┐
                              │  Service Layer                │
                              │                               │
                              │  AnalyzerService              │
                              │  - Register/run analyzers     │
                              │  - Timing & error handling    │
                              │                               │
                              │  ReportService                │
                              │  - Generate reports           │
                              │  - Terminal output            │
                              │  - JSON serialization         │
                              │  - File save                  │
                              │                               │
                              │  HealthScoreEngine            │
                              │  - Compute health scores      │
                              │  - Category scores            │
                              │  - Priority groups            │
                              │  - Recommendations            │
                              └───────────────┬───────────────┘
                                              │
                                              ▼
                              ┌──────────────────────────────┐
                              │  Model Layer                  │
                              │  (immutable data classes)     │
                              │                               │
                              │  Severity (sealed)            │
                              │  CheckStatus (sealed)         │
                              │  DiagnosticIssue              │
                              │  DiagnosticResult             │
                              │  DiagnosticReport             │
                              │  Pubspec                      │
                              │  ScoreWeights                 │
                              │  HealthScore                  │
                              │  CategoryScore                │
                              │  Recommendation               │
                              │  PriorityGroup                │
                              └──────────────────────────────┘
```

### 6.2 Data Flow: `diagnose` Command

```
1. User runs: firedoctor diagnose /path/to/project
2. DiagnoseCommand.execute() called
3. Validates project path exists
4. Creates AnalyzerContext(path, fileSystem)
5. Calls analyzerService.runAll(context)
6. For each analyzer:
   a. Creates Stopwatch
   b. Calls analyzer.analyze(context)
   c. Records duration, wraps in DiagnosticResult
   d. Logs status and issue count
   e. Catches exceptions → returns failed result with ANALYZER_ERROR
7. Prints issues per analyzer with icons, locations, recommendations
8. Prints summary (analyzers run, passed, errors, warnings, info)
9. Returns exit code (0 = passed, 1 = has critical/error issues)
```

### 6.3 Data Flow: `report` Command with Health Score

```
1. User runs: firedoctor report /path/to/project [--json] [--output file.json]
2. ReportCommand.execute() called
3. Parse flags: --json, --output
4. Validates project path
5. Runs all analyzers (same as diagnose)
6. Creates ReportService(terminal: terminal, healthScoreEngine: HealthScoreEngine())
7. Calls reportService.generateReport(...):
   a. Creates DiagnosticReport with results
   b. Calls report.computeHealthScore(engine: healthScoreEngine)
   c. HealthScoreEngine.compute(report):
      - Collects all issues from all results
      - Computes category scores per analyzer
      - Builds priority groups (critical/high/medium/low)
      - Computes total weight and max possible weight
      - Computes overall score
      - Generates top-N recommendations sorted by weight
      - Returns HealthScore
   d. Attaches HealthScore to DiagnosticReport
8. Output:
   - Default: reportService.printReport(report) → formatted terminal output
   - --json: reportService.toJson(report) → JSON string with healthScore block
   - --output: reportService.saveReport(report, fs, path) → write JSON file
```

### 6.4 Dependency Injection & Testability

- **FileSystem abstraction**: `LocalFileSystem` wraps `dart:io`; tests use `MockFileSystem` from mocktail
- **Terminal abstraction**: `AnsiTerminal` wraps stdout/stderr; tests use `MockTerminal`
- **Logger**: Takes `Terminal` as dependency
- **HealthScoreEngine**: Pure computation with no I/O — fully unit-testable
- **ReportService**: Const constructor, takes terminal and healthScoreEngine as dependencies
- **Analyzers**: Take parsers and dependencies via constructor (e.g., `IOSAnalyzer(plistParser:, podfileParser:, ...)`)

### 6.5 Code Quality & Patterns

- **Sealed classes** for `Severity` and `CheckStatus` — exhaustive pattern matching
- **Immutable models** with `const` constructors and `copyWith` where mutation is needed
- **Named constructors** and `static const` factory instances
- **Extension methods** (`AnalyzerResultExtension` on `DiagnosticResult`)
- **Return record types** for multi-value returns from parsers
- **Comment/string stripping** in Dart scanners to avoid false positives in regex matching
- **Balanced parenthesis matching** for multi-line `Firebase.initializeApp()` detection
- **No mutable state** in services (all state is passed in and returned)

### 6.6 iOS Parser Architecture

```
IOSAnalyzer
├── PlistParser
│   ├── parseGoogleServiceInfoPlist(content) → Map<String, String>?
│   ├── parseInfoPlist(content) → ({backgroundModes, hasFirebaseAppDelegateProxy})
│   ├── parseFirebaseAppDelegateProxyValue(content) → bool?
│   └── _parseDict, _parseArray (internal recursive parsers)
├── PodfileParser
│   └── parse(content) → ({iosVersion, hasFirebasePods, pods, hasRunnerTarget})?
├── PodfileLockParser
│   └── parse(content) → ({firebasePods, hasFirebasePods})
└── PbxprojParser
    └── parse(content) → ({bundleIdentifier, runnerTargetName, hasPushCapability, hasBackgroundModes})
```

### 6.7 Health Score Computation (In Detail)

```
HealthScoreEngine.computeFromResults(results):
├── Collect all issues from all results
├── Group issues by analyzer name
│
├── Category Scores:
│   For each analyzer with results:
│     totalWeight = sum(weightFor(issue.severity)) for all issues
│     maxWeight = issues.length * weights.maxScorePerIssue (25)
│     score = (maxWeight - totalWeight) / maxWeight * 100 (clamped 0-100)
│     → CategoryScore(category, displayName, score, totalIssues, totalWeight)
│   (If analyzer has no issues: score = 100)
│
├── Priority Groups:
│   For each issue:
│     group = PriorityGroup.fromSeverity(issue.severity)
│     groups[group].add(issue)
│   → Map<PriorityGroup, List<DiagnosticIssue>>
│
├── Overall Score:
│   totalWeight = sum of all issue weights
│   maxPossibleWeight = totalIssues * 25
│   score = (maxPossibleWeight - totalWeight) / maxPossibleWeight * 100
│   → double (0-100, or 100 if no issues)
│
├── Recommendations:
│   Sort issues by weight descending, then code ascending
│   Take top maxRecommendations (default 3)
│   → List<Recommendation>
│
└── Return HealthScore(overallScore, categoryScores, priorityGroups,
                       recommendations, totalWeight, maxPossibleWeight, weights)
```

### 6.8 Legacy vs Health Score

The `DiagnosticReport` retains a legacy `score` getter:
```dart
score = (maxWeighted - weighted) / maxWeighted * 100
where weighted = totalErrors * 3 + totalWarnings * 1
```
This is separate and independent from the `healthScore.overallScore` which uses the new weighted formula. Both are preserved for backward compatibility.

### 6.9 Test Coverage Breakdown

| Area | Files | Test Cases |
|------|-------|-----------|
| Analyzers | 10 | 298 |
| Models | 7 | 148 |
| Services | 3 | 57 |
| CLI Commands | 5 | 48 |
| Parsers | 5 | 72 |
| Filesystem | 2 | 45 |
| Terminal | 1 | 18 |
| Logging | 1 | 17 |
| Exceptions | 1 | 7 |
| Integration | 1 | 11 |
| Root | 1 | 2 |
| **Total** | **39** | **656** |

### 6.10 GitHub Actions CI Status

The project passes:
- `dart analyze` — 1 pre-existing info-level lint (`prefer_final_locals` in `podfile_lock_parser.dart:27`)
- `dart test` — 692/692 tests passing (includes health score tests)
- `dart format` — all files formatted

### 6.11 Build & Run

```bash
# Run diagnostics on a project
dart run bin/firedoctor.dart diagnose /path/to/flutter/project

# Generate terminal report with health scores
dart run bin/firedoctor.dart report /path/to/flutter/project

# Generate JSON report
dart run bin/firedoctor.dart report /path/to/flutter/project --json

# Save JSON report to file
dart run bin/firedoctor.dart report /path/to/flutter/project --output report.json

# Run all tests
dart test

# Run specific test files
dart test test/models/health_score_test.dart
dart test test/services/health_score_engine_test.dart
dart test test/models/score_weights_test.dart
dart test test/services/report_service_test.dart

# Compile AOT snapshot
dart compile exe bin/firedoctor.dart -o firedoctor
```

### 6.12 Design Decisions

1. **Health Score Engine as separate service** — Not coupled into analyzers, keeping the analyzer layer pure and focused on detection only.

2. **Category scores map 1:1 to analyzers** — Unknown analyzer names get title-cased display names automatically.

3. **Recommendations default to top 3** — Configurable via `maxRecommendations` parameter. Ties broken by code lexicographic order.

4. **`DiagnosticReport.computeHealthScore()` returns new instance** — Preserves immutability rather than mutating the report.

5. **Weights are per-severity, not per-code** — Keeps configuration surface simple and manageable. Code-specific weighting can be added later via `ScoreWeights` extension.

6. **iOS parsers are constructor-injectable** — Enables unit testing with mock parsers across all 13 iOS checks.

7. **Comment/string stripping** — Shared across FirebaseCoreAnalyzer, FCMAnalyzer, and CrashlyticsAnalyzer to prevent false positives when scanning Dart source code.

### 6.13 Next Steps / Roadmap

- **v1 beta release** — Polish CLI help text, verify cross-platform behavior on Linux/Windows
- **JSON schema documentation** — Finalize schema for report output
- **Additional analyzers** — AnalyticsAnalyzer, RemoteConfigAnalyzer, AuthAnalyzer, FirestoreAnalyzer (explicitly deferred)
- **Performance optimizations** — Parallel analyzer execution, incremental analysis
- **Plugin/extension system** — Allow third-party analyzers to be registered

---

*Generated from codebase analysis — all information reflects the current state of the repository as of 2026-06-12.*
