abstract final class AppConstants {
  static const String packageName = 'firedoctor';
  static const String version = '0.1.0';
  static const String jsonSchemaVersion = '1.0.0';
  static const String description =
      'Firebase diagnostics tool for Flutter projects';
  static const String githubUrl =
      'https://github.com/firedoctor-cli/firedoctor';
  static const int maxLineWidth = 80;

  /// No issues found — all checks passed.
  static const int exitNoIssues = 0;

  /// Only warning issues found (no errors or critical).
  static const int exitWarningsOnly = 1;

  /// Error issues found (no critical).
  static const int exitErrorsOnly = 2;

  /// Critical issues found.
  static const int exitCriticalIssues = 3;

  /// Internal FireDoctor failure (e.g. crash, invalid args).
  static const int exitInternalFailure = 4;

  /// Deprecated: use [exitNoIssues] instead (value 0).
  @Deprecated('Use exitNoIssues instead')
  static const int exitSuccess = 0;

  /// Deprecated: use [exitInternalFailure] instead (value 4).
  @Deprecated('Use exitInternalFailure instead')
  static const int exitFailure = 4;

  /// Map the most severe issue rank to the appropriate exit code.
  ///
  ///   [mostSevereRank]:   0 (none), 1 (info),  2 (warning),
  ///                       3 (error), 4 (critical)
  ///   Returns exit code:  0,        0,         1,
  ///                       2,        3
  static int exitCodeForSeverityRank(int mostSevereRank) {
    if (mostSevereRank <= 1) return exitNoIssues; // none or info → 0
    if (mostSevereRank == 2) return exitWarningsOnly; // warning  → 1
    if (mostSevereRank == 3) return exitErrorsOnly; // error    → 2
    return exitCriticalIssues; // critical → 3
  }
}
