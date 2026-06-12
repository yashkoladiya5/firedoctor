# Platform Compatibility Review

> **Project:** FireDoctor v0.1.0  
> **Review Date:** 2026-06-12  
> **SDK Range:** Dart `>=3.0.0 <4.0.0`  
> **Target Platforms:** macOS, Linux, Windows (cmd, PowerShell, Git Bash), CI environments

---

## 1. Windows Path Issues

### 1.1 Path Construction

**Verdict: Mostly safe — but some residual risks**

The `LocalFileSystem.join()` delegates to `package:path`'s `p.joinAll()`, which is fully platform-aware and uses `\` on Windows. All analyzers construct paths through `fs.join()`:

| Analyzer | Path usage | Safe? |
|----------|-----------|-------|
| `project_analyzer.dart` | `fs.join(projectPath, 'android')`, `fs.join(projectPath, 'ios')`, etc. | ✅ |
| `android_analyzer.dart` | `fs.join(projectPath, 'android', 'app')`, etc. | ✅ |
| `ios_analyzer.dart` | `fs.join(iosPath, 'Runner')`, `fs.join(projectPath, 'lib')` | ✅ |
| `fcm_analyzer.dart` | `fs.join(projectPath, 'ios', 'Runner')` | ✅ (redundant nesting) |
| `crashlytics_analyzer.dart` | `fs.join(projectPath, 'android', 'app')` | ✅ |

**Hardcoded `/` in string literals** — All occurrences of `'android/'`, `'ios/'`, `'lib/'`, `'test/'` are in user-facing issue *titles* and *descriptions* (e.g., `title: 'Missing android/ directory'`), NOT in path construction. These are cosmetic only.

### 1.2 `listDirectory()` returns native paths

In `local_file_system.dart:31`:
```dart
return dir.listSync().map((e) => e.path).toList();
```

On Windows, `e.path` contains `\` separators (e.g., `C:\project\lib\main.dart`). These paths are consumed by:
- `fs.isDirectory(entry)` / `fs.exists(entry)` — works (Dart's `FileSystemEntity` handles both `/` and `\` on Windows)
- `entry.endsWith('.dart')` — works correctly on all platforms
- Recursive calls back into `listDirectory` — works

**Risk:** Low. Dart's IO APIs normalize paths internally. However, any future code that manipulates these paths as strings (e.g., `split('/')`, `replaceAll('/')`) would break on Windows.

### 1.3 RegExp or string splitting on `/`

| File | Pattern | Context | Safe? |
|------|---------|---------|-------|
| `crashlytics_analyzer.dart:450` | `source[i] == '/'` | Detecting Dart `//` comments in source code | ✅ (not file paths) |
| `fcm_analyzer.dart:266` | `source[i] == '/'` | Same — Dart comment detection | ✅ |
| `android_analyzer.dart:285` | `RegExp(r'<manifest...')` | Parsing XML content | ✅ |
| `health_score_engine.dart:154` | `.split(RegExp(r'[_\s]'))` | Title-casing category names | ✅ |

**No RegExp or string splitting on `/` for file path manipulation was found.**

### 1.4 Windows-specific filesystem concerns

| Concern | Severity | Details |
|---------|----------|---------|
| **Max path length (260 chars)** | Medium | `Directory` / `File` in Dart on Windows are subject to the 260-char MAX_PATH limit unless `\\?\` prefix is used. A deeply nested Flutter project (`android/app/src/main/...`) could theoretically hit this. |
| **Case sensitivity** | Low | Dart's `File.existsSync()` on Windows is case-insensitive. `pubspec.yaml` vs `Pubspec.yaml` — minor edge case. |
| **Symlinks / Junctions** | Low | `Directory.listSync()` follows symlinks by default, which is fine. |
| **Line endings (CRLF)** | Medium | `_stripCommentsAndStrings()` in `crashlytics_analyzer.dart` and `fcm_analyzer.dart` uses `source[i] == '\n'` to detect newlines. On Windows, if a Dart file was created with CRLF line endings, the `\r` before `\n` is not stripped, which can cause false positives in comment detection. |

---

## 2. Linux/macOS Path Issues

**Verdict: No issues.**

- All paths use `/` separators natively.
- `package:path`'s `joinAll()` produces correct Unix paths.
- No file permission assumptions in path construction.
- No `~` (home directory) expansion — paths come from CLI args or `Directory.current`.

---

## 3. ANSI Terminal Compatibility

### 3.1 Current implementation (`ansi_terminal.dart`)

| Check | Code | Safe? |
|-------|------|-------|
| `NO_COLOR` env var | `Platform.environment.containsKey('NO_COLOR')` → return false | ✅ |
| TTY detection | `stdout.hasTerminal` → return false if not | ✅ |
| ANSI escape support | `stdout.supportsAnsiEscapes` | ✅ |
| Fallback text | `[SUCCESS]`, `[WARN]`, `[ERROR]`, `[INFO]` prefixes | ✅ |

### 3.2 clear() uses raw ANSI

**Risk: Medium** — `clear()` at line 63-66:
```dart
void clear() {
  if (stdout.hasTerminal) {
    stdout.write('\x1B[2J\x1B[0;0H');
  }
}
```

Only checks `hasTerminal`, not `_supportsAnsi`. On Windows where `stdout.hasTerminal` is true but `supportsAnsiEscapes` is false (e.g., old `cmd.exe`), this will print raw escape codes.

### 3.3 Platform-specific ANSI behavior

| Platform/Terminal | `hasTerminal` | `supportsAnsiEscapes` | Behavior |
|-------------------|---------------|----------------------|----------|
| macOS Terminal | true | true | ✅ ANSI colors |
| Linux (any) | true | true | ✅ ANSI colors |
| Windows Terminal | true | true (Win10+) | ✅ ANSI colors |
| Windows PowerShell 5 | true | true (Win10+) | ✅ ANSI colors |
| Windows cmd.exe (Win10+) | true | true (Win10 1511+) | ✅ ANSI colors |
| Windows cmd.exe (Win7/8) | true | false | ⚠️ Fallback works, `clear()` broken |
| Git Bash (mintty) | true | true | ✅ ANSI colors |
| CI (GitHub Actions) | false (piped) | false | ✅ Fallback |
| CI (Jenkins) | depends | depends | ✅ Fallback when no TTY |
| SSH / no TTY | false | false | ✅ Fallback |

### 3.4 CI environment detection

The `_supportsAnsi` getter returns `false` when `!stdout.hasTerminal`, which covers most CI environments. However, some CI systems (e.g., Jenkins with an attached terminal) may have `hasTerminal = true` but expect plain output.

---

## 4. NO_COLOR and TERM Support

### 4.1 Current state

| Variable | Checked? | Location |
|----------|----------|----------|
| `NO_COLOR` | ✅ Yes | `ansi_terminal.dart:7` |
| `TERM` | ❌ No | Missing |
| `CI` | ❌ No | Missing |

### 4.2 Recommendations

Add these checks to `_supportsAnsi`:

```dart
bool get _supportsAnsi {
  // Standard NO_COLOR: https://no-color.org/
  if (Platform.environment.containsKey('NO_COLOR')) return false;
  // TERM=dumb: terminal that cannot handle ANSI
  if (Platform.environment['TERM'] == 'dumb') return false;
  // No TTY: piped output (CI, file redirection)
  if (!stdout.hasTerminal) return false;
  // Some CI systems set CI=true even with a pseudo-TTY
  if (Platform.environment.containsKey('CI')) return false;
  return stdout.supportsAnsiEscapes;
}
```

**Note:** Setting `return false` for `CI` is opinionated — some users want colors in CI logs. Consider a `--color` / `--no-color` flag instead of blindly disabling for `CI`.

---

## 5. File Permissions

### 5.1 `bin/firedoctor.dart`

- Does NOT need execute permission when run via `dart run bin/firedoctor.dart` or `dart bin/firedoctor.dart`.
- Does NOT need execute permission for `dart compile exe` source input.
- If users run `./bin/firedoctor.dart` directly with a shebang, it needs `+x`. The current file has no shebang line (`#!/usr/bin/env dart`), so direct execution would fail regardless.

### 5.2 Compiled binary (`dart compile exe`)

- `dart compile exe bin/firedoctor.dart -o firedoctor` produces a native executable.
- Dart's compiler sets execute permissions automatically on Linux/macOS.
- On Windows, `.exe` extension conventions apply — no special handling needed.

### 5.3 `bin/firedoctor.dill`

- Kernel binary (compiled Dart) — does NOT need execute permission.
- Used by `dart run` for faster startup.
- Permissions should be `644` (readable by all, writable by owner).

### 5.4 Recommendation

Add a shebang to `bin/firedoctor.dart`:
```dart
#!/usr/bin/env dart
```
This enables direct execution on Unix (`./bin/firedoctor.dart doctor`) when the file is marked executable.

---

## 6. Dart SDK Compatibility

### 6.1 Features used and minimum SDK requirements

| Feature | Used in | Min Dart Version |
|---------|---------|-----------------|
| `sealed class` | `severity.dart`, `check_status.dart` | 3.0 |
| `final class` | All classes | 3.0 |
| `switch` expressions | `severity.dart:16`, `check_status.dart:15` | 3.0 |
| Records (named fields) | `android_analyzer.dart:279`, `ios_analyzer.dart:112-117,227-232` | 3.0 |
| `firstOrNull` extension | `command_runner.dart:29` | 3.0 |

### 6.2 Version compatibility matrix

| Dart SDK | `sealed` | `final` | switch expr | Records | Works? |
|----------|----------|---------|-------------|---------|--------|
| 3.0.x | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3.1.x | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3.2.x | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3.3.x | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3.4.x | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3.5.x | ✅ | ✅ | ✅ | ✅ | ✅ |

**All required features are available since Dart 3.0.** The project is fully compatible with the declared range `>=3.0.0 <4.0.0`.

### 6.3 No future-incompatible features

The code does NOT use:
- Wildcard variables (`_` as an assignable expression) — available since Dart 3.1
- `if-case` statements — available since Dart 3.0
- Null safety — already standard since Dart 2.12+

---

## 7. Risk Assessment Summary

### Risk Register

| # | Risk | Severity | File(s) | Impact | Fix |
|---|------|----------|---------|--------|-----|
| R1 | `clear()` emits raw ANSI on terminals without ANSI support | **Medium** | `ansi_terminal.dart:63-66` | User sees garbage escape codes on Windows cmd.exe (pre-Win10) | Change `if (stdout.hasTerminal)` to `if (_supportsAnsi)` |
| R2 | No `TERM=dumb` check | **Low** | `ansi_terminal.dart:6-10` | ANSI codes emitted in terminals that explicitly request no formatting | Add `Platform.environment['TERM'] == 'dumb'` check |
| R3 | No per-instance `--color` / `--no-color` flag | **Low** | All CLI commands | Users cannot override auto-detection | Add `--color` / `--no-color` flag |
| R4 | CRLF line endings in `_stripCommentsAndStrings` | **Medium** | `crashlytics_analyzer.dart:446-517`, `fcm_analyzer.dart:262-333` | Windows-line-ending Dart files may confuse comment stripping | Compare against both `\n` and `\r\n`, or `.trimRight()` |
| R5 | No filesystem abstraction tests for Windows paths | **Medium** | — | No test coverage ensures `join()` and `listDirectory()` work cross-platform | Add tests that verify `join()` produces correct platform separators |
| R6 | `listDirectory()` returns native `\` paths on Windows | **Low** | `local_file_system.dart:31` | Future code may incorrectly assume `/` separators | Document in code; add a `normalize(String path)` util |
| R7 | `CI` env var not honored for ANSI suppression | **Low** | `ansi_terminal.dart:6-10` | Some CI systems may show ANSI codes in logs | Add `Platform.environment.containsKey('CI')` (opinionated — see §4.2) |
| R8 | Windows MAX_PATH (260 chars) | **Low** | All path constructors | Deeply nested Flutter paths may fail on Windows | Low probability; document as known limitation |
| R9 | No shebang in `bin/firedoctor.dart` | **Low** | `bin/firedoctor.dart` | Cannot execute directly on Unix | Add `#!/usr/bin/env dart` line |
| R10 | `entry.endsWith('.dart')` on Windows | **None** | `crashlytics_analyzer.dart:439`, `fcm_analyzer.dart:255`, `ios_analyzer.dart:346` | Works correctly on all platforms | No action needed |
| R11 | Hardcoded path strings in user messages | **None** | Project analyzer, issue descriptions | Cosmetic only — displayed to user | No action needed (improve strings from `android/` to `android/` later) |
| R12 | Redundant `fs.join` nesting in FCM analyzer | **None** | `fcm_analyzer.dart:55-61` | Works correctly but looks fragile | Simplify to single `fs.join(projectPath, 'ios', 'Runner', 'GoogleService-Info.plist')` |

### Risk matrix

```
Severity:  High  ██  Medium  ██  Low  ██  None  ██
Count:     0         3         4         5
```

### Overall Platform Readiness Score: **85/100**

Breakdown:
- **Path handling (Windows):** 25/30 — `package:path` used everywhere, but `listDirectory()` returns native paths and CRLF is unhandled.
- **ANSI terminal (cross-platform):** 22/25 — Solid foundation with NO_COLOR support; `clear()` bug and missing `TERM` check are minor.
- **Dart SDK compatibility:** 15/15 — All features available since 3.0.
- **File permissions:** 8/10 — Missing shebang line.
- **Testing & CI readiness:** 15/20 — No filesystem cross-platform tests; no CI workflows; no `--color` flag.

---

## 8. Actionable Recommendations

### Critical (fix immediately)

None.

### High priority (fix before first major release)

1. **`ansi_terminal.dart` — Fix `clear()` to use `_supportsAnsi`** (`lib/terminal/ansi_terminal.dart:63-66`):
   ```dart
   void clear() {
     if (_supportsAnsi) {
       stdout.write('\x1B[2J\x1B[0;0H');
     }
   }
   ```

2. **Add `TERM=dumb` check** (`lib/terminal/ansi_terminal.dart:7-8`):
   ```dart
   if (Platform.environment['TERM'] == 'dumb') return false;
   ```

### Medium priority

3. **Fix CRLF handling in `_stripCommentsAndStrings`** — Replace `source[i] == '\n'` checks with `source[i] == '\n' || source[i] == '\r'` handling, or normalize input with `.replaceAll('\r\n', '\n')` at the start.

4. **Add shebang to `bin/firedoctor.dart`**.

5. **Add Windows path tests** — Test `LocalFileSystem.join()` and `LocalFileSystem.listDirectory()` with mocked paths.

6. **Simplify redundant `fs.join` nesting** in `fcm_analyzer.dart:55-61`.

### Low priority

7. **Add `--color` / `--no-color` CLI flag** for explicit ANSI control.

8. **Consider adding CI detection** (`Platform.environment.containsKey('CI')`) to `_supportsAnsi`, gated behind a flag.

9. **Document Windows MAX_PATH limitation** in project README for deeply nested projects.

---

## 9. Appendix: Test Coverage for Cross-Platform Concerns

| Area | Tests exist? | Notes |
|------|-------------|-------|
| `AnsiTerminal` | ❌ No | Only `FakeTerminal` is tested (terminal_test.dart) |
| `LocalFileSystem` | ❌ No | No filesystem test file found |
| `Severity` sealed class | ✅ Yes | Model tests |
| `CheckStatus` sealed class | ✅ Yes | Model tests |
| Cross-platform `join()` | ❌ No | Not explicitly tested |
| ANSI fallback (NO_COLOR) | ❌ No | No test for env var behavior |
| CRLF handling | ❌ No | Untested edge case |

**Key gap:** `AnsiTerminal` and `LocalFileSystem` have no dedicated unit tests for their core behavior. The terminal test only tests `FakeTerminal` (a test double), not `AnsiTerminal` itself.

---

*Review generated by FireDoctor Platform Compatibility Analyzer.*
