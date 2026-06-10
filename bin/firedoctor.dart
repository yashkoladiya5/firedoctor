import 'dart:io';
import 'package:firedoctor/firedoctor.dart';

Future<void> main(List<String> args) async {
  try {
    await runFireDoctor(args);
  } catch (e, st) {
    stderr.writeln('Fatal error: $e');
    stderr.writeln(st);
    exit(1);
  }
}
