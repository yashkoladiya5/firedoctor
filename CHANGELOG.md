# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Placeholder for future enhancements.

## [0.1.0-beta] - 2026-06-12

### Added

#### Analyzers (7)
- **Project Analyzer** — Validates project structure: detects missing `pubspec.yaml`, invalid YAML, missing Flutter SDK constraint, non-Flutter projects, and missing `android/`, `ios/`, `lib/`, `test/` directories. (9 codes: FD100-FD10x, `NOT_FLUTTER_PROJECT`, `MISSING_*`)
- **Dependency Analyzer** — Inspects Firebase package dependencies: missing `firebase_core`, Firebase packages in `dev_dependencies`, loose version constraints. (3 codes: FD200-FD202)
- **Firebase Core Analyzer** — Scans Dart source for `Firebase.initializeApp()` correctness: missing dependency, missing `firebase_options.dart`, unawaited initialization, post-`runApp()` calls, missing `WidgetsFlutterBinding.ensureInitialized()`. (8 codes: FD300-FD307)
- **Android Analyzer** — Android platform configuration: missing/invalid `google-services.json`, package name mismatches, missing Gradle plugin, outdated SDK versions, missing permissions. (13 codes: FD400-FD412)
- **iOS Analyzer** — iOS platform configuration with dedicated parsers for plist, Podfile, Podfile.lock, and Xcode project files: missing/invalid `GoogleService-Info.plist`, bundle ID mismatches, missing Podfile, push/background capabilities. (10 codes: FD500-FD509)
- **FCM Analyzer** — Firebase Cloud Messaging setup: missing `firebase_messaging` dependency, background message handler, iOS proxy settings, permission requests, token refresh handler. (6 codes: FD601-FD606)
- **Crashlytics Analyzer** — Full Crashlytics integration validation: dependency, Dart API usage, Gradle plugin, CocoaPods, dSYM upload, error handlers (`runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`). (11 codes: FD700-FD711)

#### Diagnostic Codes
- **56 diagnostic codes** across all 7 analyzers
- Severity levels: `info` (28), `warning` (21), `error` (9), `critical` (2)
- 4-letter code format with analyzer-specific prefixes (FD100-FD700 series)

#### CLI (5 Commands)
- `firedoctor diagnose` — Lightweight diagnostics output with exit code
- `firedoctor doctor` — Full health check with scored report, ANSI terminal output
- `firedoctor report` — Detailed JSON/text report with file export support
- `firedoctor version` — Version information
- `firedoctor help` — Help and usage information

#### Health Score Engine v2
- Category-level per-analyzer scoring
- Priority groups: Critical, High, Medium, Low
- Configurable `ScoreWeights` (critical=25, error=15, warning=5, info=1)
- Recommendation engine (top 5 recommendations by weight)
- Overall score: weighted average of category scores

#### CI/CD Support
- Deterministic exit codes: 0 (no issues), 1 (warnings), 2 (errors), 3 (critical), 4 (internal failure)
- `--fail-on` flag for doctor and report commands (`warning`, `error`, `critical`)
- `--min-score` flag for health score thresholds
- Machine-readable JSON output with `--json` and `--output` flags
- JSON schema v1.0.0 with `schemaVersion`, `firedoctorVersion`, `generatedAt`, `analyzerResults`, `categoryScores`, `recommendations`

#### Documentation
- README with installation, usage, and examples
- Architecture overview and data flow documentation
- Complete diagnostic codes reference (all 56 codes)
- Health score computation documentation
- CI/CD integration guide

#### Internal
- Plug-in analyzer pattern: abstract `Analyzer` base class, `AnalyzerContext`, `AnalyzerService`
- Filesystem abstraction (`FileSystem` interface + `LocalFileSystem`)
- Terminal abstraction (`Terminal` interface + `AnsiTerminal`)
- iOS parsers: `PlistParser`, `PodfileParser`, `PodfileLockParser`, `PbxprojParser`
- YAML-based pubspec parser (`PubspecParser`)
- 692 unit tests across all modules using `test` + `mocktail`
- Dart 3.0 sealed classes for `Severity` and `CheckStatus`

[0.1.0-beta]: https://github.com/firedoctor-cli/firedoctor/releases/tag/v0.1.0-beta
