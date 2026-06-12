# Getting Started with FireDoctor

FireDoctor is a CLI tool that diagnoses Firebase configuration and setup issues in Flutter projects. It scans project structure, dependencies, platform configuration (Android & iOS), Firebase Core initialization, Firebase Cloud Messaging, and Crashlytics integration.

## Prerequisites

- **Dart SDK** `>=3.0.0 <4.0.0`
- A Flutter project with Firebase dependencies (for meaningful results)

## Installation

Install FireDoctor globally via `dart pub global activate`:

```bash
# From pub.dev
dart pub global activate firedoctor

# From a local checkout
dart pub global activate --source path /path/to/firedoctor
```

After installation, the `firedoctor` command is available on your `PATH`.

### Verify Installation

```bash
firedoctor version
# Output: FireDoctor v0.1.0
```

### Run Without Installing

```bash
# From the FireDoctor project root
dart run bin/firedoctor.dart doctor /path/to/your/flutter/project
```

## Quick Start

Navigate to your Flutter project and run the full doctor check:

```bash
cd my_flutter_project
firedoctor doctor
```

This runs all 7 analyzers and produces a health score, issue report, and recommendations.

For a lighter output:

```bash
firedoctor diagnose
```

To generate a JSON report for CI consumption:

```bash
firedoctor report --json
```

## Command Reference

FireDoctor provides 5 commands:

### `help`

Shows usage information and lists all available commands.

```bash
firedoctor help
firedoctor help doctor
```

Aliases: `h`, `-h`, `--help`

Exit codes: `0` (success), `4` (unknown command)

### `version`

Prints the current FireDoctor version.

```bash
firedoctor version
```

Aliases: `v`, `-v`, `--version`

Exit code: `0`

### `diagnose`

Runs Firebase diagnostics with lightweight output. Shows per-analyzer status, issues found, and a summary. No health score computation.

```bash
firedoctor diagnose
firedoctor diagnose /path/to/project
```

Exit codes: `0`, `1`, `2`, `3`, `4`

### `doctor`

The full FireDoctor check. Runs all analyzers, computes a health score, shows category scores, priority breakdown, and recommendations.

```bash
firedoctor doctor
firedoctor doctor --fail-on error
firedoctor doctor --min-score 70
firedoctor doctor /path/to/project --fail-on critical
```

Flags: `--fail-on`, `--min-score`

Exit codes: `0`, `1`, `2`, `3`, `4`

### `report`

Generates a detailed diagnostic report. Supports JSON output and file export.

```bash
firedoctor report                  # Human-readable report to stdout
firedoctor report --json           # Machine-readable JSON to stdout
firedoctor report --output report.json  # Save JSON to file
firedoctor report --json --output report.json
firedoctor report --fail-on warning --min-score 80
```

Flags: `--fail-on`, `--min-score`, `--json`, `--output <path>`

Exit codes: `0`, `1`, `2`, `3`, `4`

## Flag Reference

### `--fail-on <severity>`

Available on: `doctor`, `report`

Set the minimum severity that causes a non-zero exit code. Useful for CI/CD pipelines.

| Value | Meaning |
|-------|---------|
| `warning` | Fail on warnings, errors, or critical issues |
| `error` (default) | Fail on errors or critical issues |
| `critical` | Fail only on critical issues |

Usage:

```bash
firedoctor doctor --fail-on warning
firedoctor report --json --fail-on critical
```

### `--min-score <0-100>`

Available on: `doctor`, `report`

Fail the run if the health score is below the given threshold. The score is a double between 0.0 and 100.0.

```bash
firedoctor doctor --min-score 75
firedoctor report --json --min-score 85.5
```

### `--json`

Available on: `report`

Output the report as a JSON object to stdout. The JSON follows the FireDoctor JSON schema.

```bash
firedoctor report --json | jq '.score'
```

### `--output <path>`

Available on: `report`

Save the report JSON to a file at the specified path.

```bash
firedoctor report --json --output ./reports/firebase-audit.json
```

## Exit Code Reference

FireDoctor uses deterministic exit codes suitable for CI/CD pipelines:

| Code | Constant | Meaning |
|------|----------|---------|
| `0` | `exitNoIssues` | No issues found — all checks passed |
| `1` | `exitWarningsOnly` | Only warning-level issues found |
| `2` | `exitErrorsOnly` | Error-level issues found (no critical) |
| `3` | `exitCriticalIssues` | Critical issues found |
| `4` | `exitInternalFailure` | Internal failure (invalid args, path not found, analyzer crash) |

The exit code is determined by the most severe issue rank:

```
mostSevereRank:  0 (none) → exit 0
                 1 (info)  → exit 0
                 2 (warning) → exit 1
                 3 (error) → exit 2
                 4 (critical) → exit 3
```

## Basic Workflow Example

```bash
# 1. Run a quick diagnosis
firedoctor diagnose
# Review issues and fix them

# 2. Run the full doctor check
firedoctor doctor
# Review health score and recommendations

# 3. Generate a JSON report for your records
firedoctor report --json --output firedoctor-report.json

# 4. Use in CI with thresholds
firedoctor doctor --fail-on error --min-score 75
```

## Next Steps

- [CI/CD Integration](ci-cd.md) — Integrate FireDoctor into your CI pipelines
- [Health Score](health-score.md) — Understand how the health score is computed
- [Diagnostic Codes](diagnostic-codes.md) — Complete reference of all 56 diagnostic codes
- [Architecture](architecture.md) — FireDoctor's internal architecture and extensibility
