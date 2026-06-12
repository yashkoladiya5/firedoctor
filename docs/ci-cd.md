# CI/CD Integration

FireDoctor is designed from the ground up for CI/CD pipelines. Its deterministic exit codes, severity threshold flags, and machine-readable JSON output make it straightforward to integrate into any CI system.

## Why CI/CD Integration Matters

Firebase configuration issues often go unnoticed until deployment time. Running FireDoctor in CI:

- Catches missing configuration files (`google-services.json`, `GoogleService-Info.plist`) before builds fail
- Validates Firebase dependency versions are consistent
- Ensures proper initialization patterns (`WidgetsFlutterBinding.ensureInitialized()` before `Firebase.initializeApp()`)
- Enforces a minimum health score for Firebase configuration quality
- Provides machine-readable reports for dashboards and audit trails

## Exit Code Strategy

FireDoctor's exit codes map directly to issue severity, making it natural to define pipeline pass/fail conditions:

| Exit Code | Meaning | CI Action |
|-----------|---------|-----------|
| `0` | No issues | ✅ Pass |
| `1` | Warnings only | ✅ Pass (or warn) |
| `2` | Errors found | ❌ Fail |
| `3` | Critical issues | ❌ Fail |
| `4` | Internal failure | ❌ Fail (infra issue) |

By default, `--fail-on` is set to `error`, meaning exit codes 0 and 1 pass, while 2, 3, and 4 fail. Adjust with `--fail-on`.

## GitHub Actions

```yaml
# .github/workflows/firebase-audit.yml
name: Firebase Configuration Audit

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  firedoctor-audit:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: 3.0.0

      - name: Install FireDoctor
        run: dart pub global activate firedoctor

      - name: Run FireDoctor audit
        id: firedoctor
        continue-on-error: true
        run: |
          firedoctor report --json --output firedoctor-report.json --fail-on error --min-score 70
        working-directory: ./my_flutter_app

      - name: Upload report artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: firedoctor-report
          path: ./my_flutter_app/firedoctor-report.json

      - name: Parse and comment on PR
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = JSON.parse(fs.readFileSync('./my_flutter_app/firedoctor-report.json', 'utf8'));
            const summary = [
              `## FireDoctor Audit Results`,
              ``,
              `**Score:** ${report.score.toFixed(1)}/100`,
              `**Status:** ${report.passed ? '✅ PASSED' : '❌ FAILED'}`,
              `**Issues:** ${report.totalIssues} (${report.totalErrors} errors, ${report.totalWarnings} warnings)`,
              `**Exit Code:** ${report.exitCode}`,
              ``,
            ].join('\n');

            if (report.recommendations?.length > 0) {
              summary += `**Recommendations:**\n`;
              report.recommendations.forEach(r => {
                summary += `- ${r.severity}: ${r.title}\n`;
              });
            }

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: summary,
            });
```

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - audit

firedoctor-audit:
  stage: audit
  image: dart:3.0.0
  script:
    - dart pub global activate firedoctor
    - firedoctor report --json --output firedoctor-report.json --fail-on error --min-score 70
  artifacts:
    paths:
      - firedoctor-report.json
    when: always
    reports:
      dotenv: firedoctor.env
  after_script:
    # Parse report and export summary as environment variables
    - |
      if [ -f firedoctor-report.json ]; then
        SCORE=$(dart -e "import 'dart:convert'; import 'dart:io'; var r = jsonDecode(File('firedoctor-report.json').readAsStringSync()); print(r['score']);")
        ISSUES=$(dart -e "import 'dart:convert'; import 'dart:io'; var r = jsonDecode(File('firedoctor-report.json').readAsStringSync()); print(r['totalIssues']);")
        echo "FIREDOCTOR_SCORE=$SCORE" >> firedoctor.env
        echo "FIREDOCTOR_ISSUES=$ISSUES" >> firedoctor.env
        echo "FireDoctor audit complete — Score: $SCORE, Issues: $ISSUES"
      fi

firedoctor-quality-gate:
  stage: audit
  image: dart:3.0.0
  script:
    - dart pub global activate firedoctor
    - firedoctor doctor --min-score 75 --fail-on warning
  needs: []
```

## Bitbucket Pipelines

```yaml
# bitbucket-pipelines.yml
image: dart:3.0.0

definitions:
  steps:
    - step: &firedoctor-audit
        name: Firebase Configuration Audit
        script:
          - dart pub global activate firedoctor
          - firedoctor report --json --output firedoctor-report.json --fail-on error --min-score 70
        artifacts:
          - firedoctor-report.json

pipelines:
  default:
    - step: *firedoctor-audit
  pull-requests:
    '**':
      - step: *firedoctor-audit
```

## Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pr:
  - main

pool:
  vmImage: ubuntu-latest

steps:
  - task: UseDotNet@2
    displayName: 'Install .NET SDK'
    inputs:
      packageType: 'sdk'
      version: '6.x'

  - script: |
      curl -fsSL https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip -o dartsdk.zip
      unzip -q dartsdk.zip -d /tmp/dart-sdk
      echo "##vso[task.prependpath]/tmp/dart-sdk/bin"
    displayName: 'Install Dart SDK'

  - script: |
      dart pub global activate firedoctor
      firedoctor report --json --output firedoctor-report.json --fail-on error --min-score 70
    displayName: 'Run FireDoctor audit'
    workingDirectory: 'my_flutter_app'

  - script: |
      SCORE=$(dart -e "import 'dart:convert'; import 'dart:io'; var r = jsonDecode(File('firedoctor-report.json').readAsStringSync()); print(r['score']);")
      ISSUES=$(dart -e "import 'dart:convert'; import 'dart:io'; var r = jsonDecode(File('firedoctor-report.json').readAsStringSync()); print(r['totalIssues']);")
      echo "FireDoctor: Score=$SCORE, Issues=$ISSUES"
      echo "##vso[task.setvariable variable=FIREDOCTOR_SCORE]$SCORE"
    displayName: 'Parse report'
    workingDirectory: 'my_flutter_app'

  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: my_flutter_app/firedoctor-report.json
      artifactName: firedoctor-report
    condition: always()
```

## Using `--fail-on` in CI

Control pipeline strictness with the `--fail-on` flag:

```bash
# Fail only on critical issues (least strict)
firedoctor doctor --fail-on critical

# Fail on errors or critical (default)
firedoctor doctor --fail-on error

# Fail on any warning, error, or critical (most strict)
firedoctor doctor --fail-on warning
```

## Using `--min-score` in CI

Enforce a minimum health score:

```bash
# Require at least 70/100
firedoctor doctor --min-score 70

# Require at least 85/100 for production deployments
firedoctor doctor --min-score 85 --fail-on critical
```

When the score falls below the threshold, FireDoctor exits with code 4 (internal failure), which fails the pipeline step.

## Parsing JSON Output in CI Scripts

### With `jq`

```bash
firedoctor report --json | jq -r '.score'
firedoctor report --json | jq -r '.totalIssues'
firedoctor report --json | jq -r '.exitCode'
firedoctor report --json | jq -r '.recommendations[].formatted'
```

### With Dart (no dependencies)

```bash
dart -e "
import 'dart:convert';
import 'dart:io';
var r = jsonDecode(stdin.readAllSync());
print('Score: \${r['score']}');
print('Issues: \${r['totalIssues']}');
"
``` < firedoctor report --json

### With Node.js

```javascript
const report = JSON.parse(fs.readFileSync('firedoctor-report.json', 'utf8'));
console.log(`Score: ${report.score}`);
console.log(`Exit Code: ${report.exitCode}`);
```

## Best Practices

1. **Run on every PR** — Catch Firebase issues before they reach production. Add FireDoctor to your PR pipeline as a mandatory check.

2. **Set appropriate thresholds** — Start with `--fail-on error` and adjust as your team addresses issues. Use `--min-score` to gradually improve configuration quality.

3. **Archive reports** — Upload the JSON report as a build artifact to track configuration health over time.

4. **Gradually increase strictness** — If your project has existing Firebase issues, start with `--fail-on critical` and incrementally tighten to `error` and then `warning` as issues are resolved.

5. **Use `--json` for dashboards** — Pipe JSON output to monitoring tools or custom dashboards. The `score`, `categoryScores`, and `recommendations` fields are particularly useful for trend tracking.

6. **Pair with Flutter build steps** — Run FireDoctor before your `flutter build` step. A failed audit can fail-fast before an expensive build.

7. **Document thresholds in your repo** — Check in your CI config with explicit `--fail-on` and `--min-score` values so the team has a shared understanding of quality standards.
