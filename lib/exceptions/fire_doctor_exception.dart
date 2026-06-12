/// Core class.
final class FireDoctorException implements Exception {
  /// Public property or field.
  final String message;
  /// Public property or field.
  final String? code;
  /// Public property or field.
  final StackTrace? stackTrace;

  const FireDoctorException(this.message, {this.code, this.stackTrace});

  @override
  /// Public method or function.
  String toString() {
    final buffer = StringBuffer('FireDoctorException: $message');
    if (code != null) buffer.write(' (code: $code)');
    return buffer.toString();
  }
}