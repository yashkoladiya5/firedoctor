# Health Score

The FireDoctor Health Score quantifies your Firebase configuration quality on a 0–100 scale. It is computed by the `HealthScoreEngine` and provides a single number you can track over time, plus granular category scores and prioritized recommendations.

## What is the Health Score?

The health score is a weighted composite of all issues found across every analyzer. A score of 100 means zero issues. Each issue reduces the score based on its severity. The score helps you:

- **Track progress** — Monitor your score over time as you fix issues
- **Set quality gates** — Enforce minimum scores in CI/CD pipelines
- **Identify weak areas** — Category scores show which parts of your Firebase setup need attention
- **Prioritize fixes** — Recommendations are sorted by impact weight

## How the Health Score Engine Works

### Score Weights

Each severity level carries a weight that determines its impact on the score:

| Severity | Weight | Impact |
|----------|--------|--------|
| Critical | 25 | Highest penalty |
| Error | 15 | High penalty |
| Warning | 5 | Moderate penalty |
| Info | 1 | Minor penalty |

These weights are defined in `ScoreWeights` and are configurable for custom scoring.

### Per-Category Score

Each analyzer produces a category score:

```
categoryScore = max(0, 100 - (totalWeight / maxPossibleWeight) × 100)

Where:
  totalWeight = sum of weights for all issues in this category
  maxPossibleWeight = number of issues × maxScorePerIssue (25)
```

For example, if an analyzer finds 2 errors (weight 15 each) and 1 warning (weight 5):
```
totalWeight = 15 + 15 + 5 = 35
maxPossibleWeight = 3 × 25 = 75
categoryScore = max(0, 100 - (35/75 × 100)) = max(0, 100 - 46.7) = 53.3
```

### Overall Score

The overall score is a weighted average of category scores, where each category's contribution is proportional to its `maxPossibleWeight`. This means categories with more issues have a larger impact on the final score.

```
overallScore = weightedAverage of categoryScores by maxPossibleWeight
```

### Priority Groups

Issues are organized into four priority groups based on severity:

| Priority Group | Severity | Label | Meaning |
|----------------|----------|-------|---------|
| Critical | Critical | Critical Fixes | Blocking issues that will prevent Firebase from working |
| High | Error | High Priority | Serious issues that cause incorrect behavior |
| Medium | Warning | Medium Priority | Configuration problems or missing best practices |
| Low | Info | Low Priority | Recommendations and informational items |

### Recommendations Generation

The engine generates up to 3 recommendations (configurable) by:

1. Collecting all issues from all analyzers
2. Sorting by weight descending (critical first)
3. Taking the top N recommendations

Each recommendation includes the diagnostic code, title, severity, and weight.

## How to Interpret Scores

| Score Range | Meaning | Suggested Action |
|-------------|---------|------------------|
| 90–100 | Excellent | Maintain — minor improvements only |
| 70–89 | Good | Review warnings — address medium-priority items |
| 50–69 | Fair | Several issues — fix errors and warnings |
| 25–49 | Poor | Significant problems — address critical and error items |
| 0–24 | Critical | Major configuration gaps — immediate attention required |

## Using `--min-score` in CI/CD

The `--min-score` flag enables health score gates in CI pipelines:

```bash
# Require minimum score of 70
firedoctor doctor --min-score 70

# Require 85 with strict fail-on
firedoctor doctor --min-score 85 --fail-on warning

# In CI, fail if score drops below threshold
firedoctor report --json --min-score 75
```

When the score is below the threshold, FireDoctor exits with code 4 (internal failure).

## Example Output Walkthrough

### Running `firedoctor doctor`

```
═══════════════════════════════════════════
  FireDoctor Diagnostic Report
═══════════════════════════════════════════

  ┌─ Project
  │ Project: my_flutter_app
  │ Path: /Users/me/projects/my_flutter_app
  └─

  ┌─ Health Score
  │ Overall: 66.7/100
  │ Issues: 4
  │ Weight: 20/100
  └─

  ┌─ Category Scores
  │ Project: 100.0/100 [█████]
  │ Dependency: 100.0/100 [█████]
  │ Firebase Core: 83.3/100 [████░]
  │ Android: 40.0/100 [██░░░]
  │ iOS: 35.0/100 [█░░░░]
  │ Messaging: 100.0/100 [█████]
  │ Crashlytics: 100.0/100 [█████]
  └─

  ┌─ Priority Breakdown
  │ High Priority: 1
  │ Medium Priority: 2
  │ Low Priority: 1
  └─

  ┌─ Recommended Next Actions
  │ 1. Fix FD500: Missing GoogleService-Info.plist
  │ 2. Fix FD400: Missing google-services.json
  │ 3. Fix FD205: Missing POST_NOTIFICATIONS permission
  └─

  Score: 66.7/100
  Status: FAILED

  Issues: 4
  Errors: 1
  Warnings: 2
```

### Breaking Down the Walkthrough

**Overall Score (66.7)**: This project has several configuration gaps. It falls in the "Fair" range.

**Category Scores**:
- **Project (100)**: Perfect — project structure is sound
- **Dependency (100)**: Perfect — all Firebase dependencies are correctly declared
- **Firebase Core (83.3)**: Good — minor initialization issue
- **Android (40.0)**: Poor — `google-services.json` is missing and permissions are incomplete
- **iOS (35.0)**: Poor — `GoogleService-Info.plist` is missing
- **Messaging (100)**: Perfect — no FCM issues
- **Crashlytics (100)**: Perfect — Crashlytics is well configured

**Priority Breakdown**: 1 high priority (error), 2 medium (warnings), 1 low (info).

**Recommendations**: The top 3 issues sorted by impact weight:
1. FD500 (iOS config file missing) — weight 25 (critical)
2. FD400 (Android config file missing) — weight 25 (critical)
3. FD405 (notification permission missing) — weight 5 (warning)

### CI Application

For this project, setting `--min-score 75` would fail CI with exit code 4 because the score is 66.7. The team would need to address the missing configuration files before merging.
