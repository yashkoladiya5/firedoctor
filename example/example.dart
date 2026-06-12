import 'package:firedoctor/firedoctor.dart';

void main(List<String> args) async {
  // Execute FireDoctor CLI programmatically with default help argument
  await runFireDoctor(args.isEmpty ? ['help'] : args);
}
