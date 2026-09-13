import 'package:args/command_runner.dart';

import '../lib/src/commands/decrypt_command.dart';
import '../lib/src/commands/encrypt_command.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'file_encryptor',
    'Outil de chiffrement et de déchiffrement de fichiers.',
  )
    ..addCommand(EncryptCommand())
    ..addCommand(DecryptCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (error) {
    print(error.message);
    print('');
    print(error.usage);
  } catch (error) {
    print('Erreur : $error');
  }
}
