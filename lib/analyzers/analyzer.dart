import 'package:firedoctor/models/models.dart';
import 'analyzer_context.dart';

/// Core class.
abstract class Analyzer {
  /// Public property or field.
  String get name;
  /// Public property or field.
  String get description;
  /// Public property or field.
  String get category;

  /// Public method or function.
  Future<DiagnosticResult> analyze(AnalyzerContext context);
}