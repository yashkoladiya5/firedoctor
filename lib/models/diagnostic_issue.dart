import 'package:firedoctor/models/severity.dart';

final class DiagnosticIssue {
  final Severity severity;
  final String code;
  final String title;
  final String description;
  final String? recommendation;
  final String? filePath;
  final int? lineNumber;
  final Map<String, String>? metadata;

  const DiagnosticIssue({
    required this.severity,
    required this.code,
    required this.title,
    required this.description,
    this.recommendation,
    this.filePath,
    this.lineNumber,
    this.metadata,
  });

  DiagnosticIssue copyWith({
    Severity? severity,
    String? code,
    String? title,
    String? description,
    String? Function()? recommendation,
    String? Function()? filePath,
    int? Function()? lineNumber,
    Map<String, String>? Function()? metadata,
  }) {
    return DiagnosticIssue(
      severity: severity ?? this.severity,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendation: recommendation != null ? recommendation() : this.recommendation,
      filePath: filePath != null ? filePath() : this.filePath,
      lineNumber: lineNumber != null ? lineNumber() : this.lineNumber,
      metadata: metadata != null ? metadata() : this.metadata,
    );
  }
}
