import 'dart:io';

import 'package:args/command_runner.dart';

import '../utils/core_factory.dart';

class EncryptCommand extends Command<void> {
  EncryptCommand() {
    argParser
      ..addOption('output', abbr: 'o', help: 'Chemin du fichier .enc de sortie.')
      ..addOption('password', abbr: 'p', help: 'Mot de passe. Préférez la saisie interactive.');
  }

  @override
  String get name => 'encrypt';

  @override
  String get description => 'Chiffre un fichier avec le moteur FileEncryptor Core.';

  @override
  Future<void> run() async {
    final results = argResults!;
    if (results.rest.length != 1) {
      throw UsageException('Un seul fichier d’entrée est requis.', usage);
    }

    final input = results.rest.single;
    if (!File(input).existsSync()) {
      throw UsageException('Le fichier d’entrée n’existe pas : $input', usage);
    }

    final password = await _readPassword(results['password'] as String?);
    if (password.isEmpty) {
      throw UsageException('Le mot de passe ne peut pas être vide.', usage);
    }

    final result = await CoreFactory.encryptUseCase()(
      inputPath: input,
      outputPath: results['output'] as String?,
      password: password,
    );

    print('Chiffrement réussi : ${result.outputPath}');
  }

  Future<String> _readPassword(String? supplied) async {
    if (supplied != null) return supplied;
    stdout.write('Mot de passe : ');
    return stdin.readLineSync() ?? '';
  }
}
