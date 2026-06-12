/// Core class.
final class AnalyzerConfidence {
  /// Public property or field.
  final String code;
  /// Public property or field.
  final double confidence;
  /// Public property or field.
  final String reasoning;

  const AnalyzerConfidence({
    required this.code,
    required this.confidence,
    required this.reasoning,
  });

  /// Public method or function.
  Map<String, dynamic> toJson() => {
    'code': code,
    'confidence': confidence,
    'reasoning': reasoning,
  };

  static Map<String, AnalyzerConfidence> get defaults => {
    // Project Analyzer
    'FD101': const AnalyzerConfidence(
      code: 'FD101',
      confidence: 1.0,
      reasoning: 'Deterministic YAML parse check',
    ),
    'FD102': const AnalyzerConfidence(
      code: 'FD102',
      confidence: 0.95,
      reasoning: 'Filesystem check — low FP risk',
    ),
    'FD103': const AnalyzerConfidence(
      code: 'FD103',
      confidence: 0.95,
      reasoning: 'Filesystem check — low FP risk',
    ),
    'FD104': const AnalyzerConfidence(
      code: 'FD104',
      confidence: 0.95,
      reasoning: 'Filesystem check — low FP risk',
    ),
    'FD105': const AnalyzerConfidence(
      code: 'FD105',
      confidence: 0.90,
      reasoning: 'Filesystem check — web directory optional',
    ),
    'FD106': const AnalyzerConfidence(
      code: 'FD106',
      confidence: 0.90,
      reasoning: 'YAML constraint parse — semantic versioning',
    ),
    // Dependency Analyzer
    'FD201': const AnalyzerConfidence(
      code: 'FD201',
      confidence: 1.0,
      reasoning: 'Deterministic YAML dependency check',
    ),
    'FD202': const AnalyzerConfidence(
      code: 'FD202',
      confidence: 1.0,
      reasoning: 'Deterministic version comparison',
    ),
    'FD203': const AnalyzerConfidence(
      code: 'FD203',
      confidence: 0.85,
      reasoning: 'Recommended dependency — project may not need analytics',
    ),
    'FD204': const AnalyzerConfidence(
      code: 'FD204',
      confidence: 0.85,
      reasoning: 'Recommended dependency — project may not need Firestore',
    ),
    'FD205': const AnalyzerConfidence(
      code: 'FD205',
      confidence: 0.85,
      reasoning: 'Recommended dependency — project may not need Auth',
    ),
    // Firebase Core Analyzer
    'FD301': const AnalyzerConfidence(
      code: 'FD301',
      confidence: 1.0,
      reasoning: 'Deterministic code pattern match for initializeApp',
    ),
    'FD302': const AnalyzerConfidence(
      code: 'FD302',
      confidence: 0.95,
      reasoning: 'Options presence check — low FP risk',
    ),
    'FD303': const AnalyzerConfidence(
      code: 'FD303',
      confidence: 0.85,
      reasoning: 'Main function heuristic — init could be in helper',
    ),
    'FD304': const AnalyzerConfidence(
      code: 'FD304',
      confidence: 0.90,
      reasoning: 'Multiple init detection — reliable pattern match',
    ),
    'FD305': const AnalyzerConfidence(
      code: 'FD305',
      confidence: 0.80,
      reasoning: 'Conditional init heuristic — complex code paths',
    ),
    'FD306': const AnalyzerConfidence(
      code: 'FD306',
      confidence: 0.85,
      reasoning: 'Platform channel init — pattern match',
    ),
    // Android Analyzer
    'FD401': const AnalyzerConfidence(
      code: 'FD401',
      confidence: 1.0,
      reasoning: 'Deterministic filesystem check',
    ),
    'FD402': const AnalyzerConfidence(
      code: 'FD402',
      confidence: 1.0,
      reasoning: 'Deterministic build.gradle parse',
    ),
    'FD403': const AnalyzerConfidence(
      code: 'FD403',
      confidence: 1.0,
      reasoning: 'Deterministic build.gradle plugin parse',
    ),
    'FD404': const AnalyzerConfidence(
      code: 'FD404',
      confidence: 1.0,
      reasoning: 'Deterministic minSdkVersion parse',
    ),
    'FD405': const AnalyzerConfidence(
      code: 'FD405',
      confidence: 1.0,
      reasoning: 'Deterministic compileSdkVersion parse',
    ),
    'FD406': const AnalyzerConfidence(
      code: 'FD406',
      confidence: 1.0,
      reasoning: 'Deterministic targetSdkVersion parse',
    ),
    'FD407': const AnalyzerConfidence(
      code: 'FD407',
      confidence: 0.95,
      reasoning: 'Play services version — minor parse ambiguity',
    ),
    'FD408': const AnalyzerConfidence(
      code: 'FD408',
      confidence: 0.85,
      reasoning: 'Build config recommendation — heuristic',
    ),
    'FD409': const AnalyzerConfidence(
      code: 'FD409',
      confidence: 1.0,
      reasoning: 'Deterministic filesystem check',
    ),
    'FD410': const AnalyzerConfidence(
      code: 'FD410',
      confidence: 0.90,
      reasoning: 'AndroidX detection — build.gradle parse',
    ),
    // iOS Analyzer
    'FD501': const AnalyzerConfidence(
      code: 'FD501',
      confidence: 1.0,
      reasoning: 'Deterministic filesystem check',
    ),
    'FD502': const AnalyzerConfidence(
      code: 'FD502',
      confidence: 0.95,
      reasoning: 'Podfile parse — minor edge cases',
    ),
    'FD503': const AnalyzerConfidence(
      code: 'FD503',
      confidence: 0.85,
      reasoning: 'Bundle ID comparison across files',
    ),
    'FD504': const AnalyzerConfidence(
      code: 'FD504',
      confidence: 0.95,
      reasoning: 'Xcode project target parse',
    ),
    'FD505': const AnalyzerConfidence(
      code: 'FD505',
      confidence: 0.95,
      reasoning: 'iOS version parse from Podfile',
    ),
    'FD506': const AnalyzerConfidence(
      code: 'FD506',
      confidence: 0.85,
      reasoning: 'Swift/ObjC bridging detection',
    ),
    'FD507': const AnalyzerConfidence(
      code: 'FD507',
      confidence: 0.90,
      reasoning: 'Plist background mode parse',
    ),
    'FD508': const AnalyzerConfidence(
      code: 'FD508',
      confidence: 0.95,
      reasoning: 'Signing capability detection',
    ),
    'FD509': const AnalyzerConfidence(
      code: 'FD509',
      confidence: 0.95,
      reasoning: 'Platform version in Podfile',
    ),
    'FD510': const AnalyzerConfidence(
      code: 'FD510',
      confidence: 0.85,
      reasoning: 'Push capability detection',
    ),
    'FD511': const AnalyzerConfidence(
      code: 'FD511',
      confidence: 0.90,
      reasoning: 'ATS plist configuration',
    ),
    'FD512': const AnalyzerConfidence(
      code: 'FD512',
      confidence: 0.90,
      reasoning: 'Delegate proxy plist detection',
    ),
    // FCM Analyzer
    'FD600': const AnalyzerConfidence(
      code: 'FD600',
      confidence: 1.0,
      reasoning: 'Deterministic dependency check',
    ),
    'FD601': const AnalyzerConfidence(
      code: 'FD601',
      confidence: 0.85,
      reasoning: 'Dart code pattern match — false positive risk from comments',
    ),
    'FD602': const AnalyzerConfidence(
      code: 'FD602',
      confidence: 0.85,
      reasoning: 'Permission code pattern — may miss dynamic permission flows',
    ),
    'FD603': const AnalyzerConfidence(
      code: 'FD603',
      confidence: 0.85,
      reasoning: 'Background handler pattern — may miss named function refs',
    ),
    'FD604': const AnalyzerConfidence(
      code: 'FD604',
      confidence: 0.90,
      reasoning: 'Plist delegate proxy flag',
    ),
    'FD605': const AnalyzerConfidence(
      code: 'FD605',
      confidence: 0.85,
      reasoning: 'Token refresh pattern — may miss wrapped calls',
    ),
    // Crashlytics Analyzer
    'FD700': const AnalyzerConfidence(
      code: 'FD700',
      confidence: 1.0,
      reasoning: 'Deterministic dependency check',
    ),
    'FD701': const AnalyzerConfidence(
      code: 'FD701',
      confidence: 0.95,
      reasoning: 'Crashlytics init pattern match',
    ),
    'FD702': const AnalyzerConfidence(
      code: 'FD702',
      confidence: 0.85,
      reasoning: 'Error reporting pattern — heuristic',
    ),
    'FD703': const AnalyzerConfidence(
      code: 'FD703',
      confidence: 0.80,
      reasoning: 'Catch block analysis — complex coverage',
    ),
    'FD704': const AnalyzerConfidence(
      code: 'FD704',
      confidence: 0.90,
      reasoning: 'NDK build.gradle detection',
    ),
    'FD705': const AnalyzerConfidence(
      code: 'FD705',
      confidence: 0.90,
      reasoning: 'Debug disable pattern detection',
    ),
    'FD706': const AnalyzerConfidence(
      code: 'FD706',
      confidence: 0.80,
      reasoning: 'Test crash path — heuristic',
    ),
    'FD707': const AnalyzerConfidence(
      code: 'FD707',
      confidence: 0.90,
      reasoning: 'Upload symbols build.gradle detection',
    ),
    'FD708': const AnalyzerConfidence(
      code: 'FD708',
      confidence: 0.80,
      reasoning: 'User ID pattern — heuristic',
    ),
    'FD709': const AnalyzerConfidence(
      code: 'FD709',
      confidence: 0.90,
      reasoning: 'SDK version comparison — minor edge cases',
    ),
  };
}