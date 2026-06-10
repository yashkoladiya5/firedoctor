import 'package:firedoctor/models/models.dart';
import 'analyzer_context.dart';

abstract class Analyzer {
  String get name;
  String get description;
  String get category;

  Future<DiagnosticResult> analyze(AnalyzerContext context);
}
