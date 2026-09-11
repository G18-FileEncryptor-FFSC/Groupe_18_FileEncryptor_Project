import 'package:cli/cli.dart';

Future<void> main(List<String> arguments) async {
  final exitCode = await CliApplication().run(arguments);
  if (exitCode != 0) {
    // ignore: avoid_print
    print('');
  }
}
