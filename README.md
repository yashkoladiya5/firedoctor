# FireDoctor

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.0-blue)](https://dart.dev)
[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](https://github.com/firedoctor-cli/firedoctor)
[![Coverage](https://img.shields.io/badge/coverage-692%20tests-brightgreen)](https://github.com/firedoctor-cli/firedoctor)
[![Version](https://img.shields.io/badge/version-0.1.0--beta-orange)](https://github.com/firedoctor-cli/firedoctor)

**FireDoctor** is a CLI tool that diagnoses Firebase configuration and setup issues in Flutter projects. It scans your project's structure, dependencies, platform configuration files (Android & iOS), Firebase Core initialization, Firebase Cloud Messaging (FCM) setup, and Crashlytics integration — reporting issues, computing a health score, and providing actionable recommendations.

Designed for CI/CD pipelines with deterministic exit codes, threshold flags, and machine-readable JSON output.

## Quick Installation

```bash
dart pub global activate --source path .
```

Or from pub.dev:

```bash
dart pub global activate firedoctor
```

## Quick Usage

```bash
# Lightweight diagnostics
firedoctor diagnose

# Full health check with health score
firedoctor doctor

# Generate JSON report
firedoctor report --json

# Save report to file
firedoctor report --output report.json

# Fail CI on warnings or above
firedoctor doctor --fail-on warning

# Require minimum health score of 80
firedoctor doctor --min-score 80
```

## Features

- **7 Analyzers** — Project structure, dependencies, Firebase Core, Android, iOS, FCM, and Crashlytics
- **56 Diagnostic Codes** — Granular issue detection with `info`, `warning`, `error`, and `critical` severity levels
- **Health Score Engine** — Category-level scoring, priority grouping, weighted recommendations
- **CI/CD Ready** — Deterministic exit codes (0–4), `--fail-on` and `--min-score` thresholds
- **JSON Report** — Machine-readable output with full schema (`schemaVersion`, `analyzerResults`, `categoryScores`, `recommendations`)
- **Cross-Platform** — Works on macOS, Linux, and Windows
- **ANSI Terminal** — Colorized output with `NO_COLOR` support

## Example Output

```
Running FireDoctor analysis on /path/to/flutter-project...

[FD300] ERROR   Missing firebase_core dependency
[FD400] CRITICAL Missing google-services.json
[FD500] CRITICAL Missing GoogleService-Info.plist

Health Score: 42.3 / 100 — Failed

Categories:
  Project:        100.0 / 100
  Dependency:     100.0 / 100
  Firebase Core:   0.0  / 100
  Android:         0.0  / 100
  iOS:             0.0  / 100
  FCM:            100.0 / 100
  Crashlytics:    100.0 / 100

Recommendations:
  1. Add google-services.json to android/app/
  2. Add GoogleService-Info.plist to ios/Runner/
  3. Add firebase_core dependency to pubspec.yaml
```

## CI/CD Integration

```bash
# Fail pipeline if any error-level issues found
firedoctor doctor --fail-on error

# Fail pipeline if health score drops below 75
firedoctor doctor --min-score 75

# Generate JSON report for downstream processing
firedoctor report --json > firedoctor-report.json
```

Exit codes: `0` (passed), `1` (warnings), `2` (errors), `3` (critical), `4` (internal failure).

See the [CI/CD integration guide](docs/ci-cd.md) for detailed CI setup examples.

## Documentation

| Resource | Description |
|----------|-------------|
| [Getting Started](docs/getting-started.md) | Installation and first steps |
| [Diagnostic Codes](docs/diagnostic-codes.md) | Complete reference of all 56 codes |
| [Health Score](docs/health-score.md) | How the scoring engine works |
| [CI/CD Integration](docs/ci-cd.md) | Using FireDoctor in CI pipelines |
| [Architecture](docs/architecture.md) | Project architecture and design |
| [CHANGELOG](CHANGELOG.md) | Release history |

## Requirements

- Dart SDK >= 3.0.0

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/firedoctor-cli/firedoctor).

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feat/my-feature`)
5. Open a Pull Request

Run tests before submitting:

```bash
dart test
dart analyze
```

## License

MIT — see [LICENSE](LICENSE) for details.
