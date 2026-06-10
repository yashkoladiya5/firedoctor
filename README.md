# FireDoctor

![License](https://img.shields.io/badge/license-MIT-blue.svg)

FireDoctor is a CLI tool that diagnoses Firebase configuration and setup issues in Flutter projects.

## Installation

```bash
dart pub global activate --source path .
```

Or from pub.dev:

```bash
dart pub global activate firedoctor
```

## Usage

FireDoctor provides the following commands:

| Command | Description |
|---------|-------------|
| `diagnose` | Run Firebase diagnostics on the current project |
| `doctor` | Check the overall health of Firebase setup |
| `report` | Generate a detailed diagnostics report |
| `version` | Print the current version |
| `help` | Display help information |

```bash
firedoctor diagnose
firedoctor doctor
firedoctor report
firedoctor version
firedoctor help
```

## Requirements

- Dart SDK >=3.0.0

## License

MIT

---

**Phase 1 — Foundation.** Phase 2 — Coming soon with real Firebase analyzers.
