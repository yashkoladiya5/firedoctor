# Release Checklist

> **Project:** FireDoctor v0.1.0
> **Repository:** https://github.com/firedoctor-cli/firedoctor

## Pre-Release Verification

- [ ] **All tests pass** — `dart test` exits with code 0
- [ ] **No analysis issues** — `dart analyze` produces zero errors and zero warnings
- [ ] **Version bump** — `pubspec.yaml` version matches the intended release tag
- [ ] **CHANGELOG.md updated** — All changes for this release are documented
- [ ] **Git tag matches version** — Tag is created (e.g. `v0.1.0-beta`)

## Functional Verification

- [ ] `firedoctor diagnose` works on a real Flutter project
- [ ] `firedoctor doctor` works on a real Flutter project
- [ ] `firedoctor report --output report.json` generates valid JSON
- [ ] `firedoctor report --json` outputs valid JSON to stdout
- [ ] Exit codes match expected values (0–4)
- [ ] `--fail-on` flag works correctly for all severity levels
- [ ] `--min-score` flag works correctly with threshold enforcement

## JSON Schema Verification

Run `firedoctor report --json` and validate the output contains:

- [ ] `schemaVersion` field (expected: `"1.0.0"`)
- [ ] `firedoctorVersion` field (expected: `"0.1.0"`)
- [ ] `generatedAt` field (ISO 8601 timestamp)
- [ ] `analyzerResults` array (not `results`)
- [ ] `exitCode` field (integer 0–4)
- [ ] `mostSevereRank` field (integer 0–4)
- [ ] `categoryScores` array
- [ ] `recommendations` array
- [ ] Output is valid JSON (parseable with `dart:convert` or `jq`)

## Platform Verification

- [ ] Works on **macOS** — ANSI output, paths, exit codes
- [ ] Works on **Linux** — ANSI output, paths, exit codes
- [ ] Works on **Windows** — paths, exit codes (if available)
- [ ] ANSI terminal output renders correctly (colors, icons)
- [ ] `NO_COLOR` environment variable is respected (ANSI codes suppressed)

## Installation Verification

- [ ] `dart pub global activate --source path .` completes without error
- [ ] `firedoctor` command is available after activation
- [ ] Native binary compiles: `dart compile exe bin/firedoctor.dart -o firedoctor`
- [ ] Binary runs correctly: `./firedoctor doctor`

## Documentation Verification

- [ ] **README.md** is up to date
- [ ] **docs/getting-started.md** is accurate
- [ ] **docs/ci-cd.md** is accurate
- [ ] **docs/health-score.md** is accurate
- [ ] **docs/diagnostic-codes.md** is accurate
- [ ] **docs/architecture.md** is accurate
- [ ] **CHANGELOG.md** is up to date
- [ ] **FIREDOCTOR_COMPLETE.md** is up to date

## Final Sign-Off

- [ ] Release tag pushed to remote (`git push origin v0.1.0-beta`)
- [ ] GitHub Release created with release notes
- [ ] Binary attached to GitHub Release (`firedoctor` executable)
- [ ] Release announcement ready (internal or public channels)
