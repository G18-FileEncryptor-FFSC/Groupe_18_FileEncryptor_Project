import 'dart:io';

import 'package:cli/cli.dart';

Future<void> main(List<String> arguments) async {
  final code = await CliApplication().run(arguments);
  if (code != 0) exit(code);
}
