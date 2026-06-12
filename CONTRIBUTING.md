# Contributing to FireDoctor

Thank you for your interest in contributing to FireDoctor! We welcome contributions of all kinds: bug reports, feature requests, documentation improvements, and code changes.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/firedoctor.git`
3. Install dependencies: `dart pub get`
4. Run tests: `dart test`
5. Run analysis: `dart analyze`

## Development Process

### 1. Find or Create an Issue

- Check [existing issues](https://github.com/firedoctor-cli/firedoctor/issues) before creating a new one
- Use the appropriate issue template (bug report or feature request)
- Wait for maintainer feedback before starting work

### 2. Create a Branch

```bash
git checkout -b fix/issue-123-description
```

Branch naming convention:
- `fix/` — bug fixes
- `feat/` — new features
- `docs/` — documentation
- `refactor/` — code refactoring

### 3. Make Changes

- Follow the existing code style (run `dart format .`)
- Ensure `dart analyze` passes with no errors
- Add tests for new functionality
- Update documentation where applicable

### 4. Run Tests

```bash
dart test
dart analyze
```

All 692+ tests must pass. New features require new tests.

### 5. Commit

```bash
git add .
git commit -m "type: brief description"
```

Commit message format (conventional commits):
- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation
- `refactor:` — code refactoring
- `test:` — test changes
- `chore:` — infrastructure/build

### 6. Submit a Pull Request

- Push your branch: `git push origin fix/issue-123-description`
- Open a PR against the `main` branch
- Reference the issue number in the PR description
- Ensure CI checks pass (analyze + test workflows)

## Adding a New Diagnostic Code

1. Add the issue creation logic in the relevant analyzer
2. Add the code to `docs/diagnostic-codes.md`
3. Add tests for the new code

Do NOT add new analyzer categories without maintainer approval.

## Code of Conduct

Be respectful, inclusive, and constructive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/).

## Questions?

Open a [Discussion](https://github.com/firedoctor-cli/firedoctor/discussions) or ask in the issue before starting work.
