import 'package:firedoctor/models/severity.dart';

/// Core class.
final class DiagnosticIssue {
  /// Public property or field.
  final Severity severity;
  /// Public property or field.
  final String code;
  /// Public property or field.
  final String title;
  /// Public property or field.
  final String description;
  /// Public property or field.
  final String? recommendation;
  /// Public property or field.
  final String? filePath;
  /// Public property or field.
  final int? lineNumber;
  /// Public property or field.
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

  /// Public method or function.
  DiagnosticIssue copyWith({
    Severity? severity,
    String? code,
    String? title,
    String? description,
    String? Function()? recommendation,
    String? Function()? filePath,
    int? Function()? lineNumber,
    /// Public method or function.
    Map<String, String>? Function()? metadata,
  }) {
    return DiagnosticIssue(
      severity: severity ?? this.severity,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendation: recommendation != null
          ? recommendation()
          : this.recommendation,
      filePath: filePath != null ? filePath() : this.filePath,
      lineNumber: lineNumber != null ? lineNumber() : this.lineNumber,
      metadata: metadata != null ? metadata() : this.metadata,
    );
  }
}