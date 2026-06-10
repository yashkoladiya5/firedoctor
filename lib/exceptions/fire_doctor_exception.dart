final class FireDoctorException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const FireDoctorException(this.message, {this.code, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('FireDoctorException: $message');
    if (code != null) buffer.write(' (code: $code)');
    return buffer.toString();
  }
}
