import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';

class DecryptCommand extends Command<void> {
  DecryptCommand() {
    argParser
      ..addOption('output', abbr: 'o', help: 'Dossier ou fichier de sortie.')
      ..addOption(
        'password',
        abbr: 'p',
        help: 'Mot de passe. Préférez la saisie interactive.',
      );
  }

  @override
  String get name => 'decrypt';

  @override
  String get description => 'Déchiffrer un fichier .enc.';

  @override
  String get invocation => '<input.enc> [options]';

  @override
  Future<void> run() async {
    final results = argResults!;

    if (results.rest.length != 1) {
      throw UsageException('Un seul fichier .enc d’entrée est requis.', usage);
    }

    final input = results.rest.single;
    if (!File(input).existsSync()) {
      throw UsageException(
        'Le fichier spécifié est introuvable : $input',
        usage,
      );
    }

    final password = await _readPassword(results['password'] as String?);
    if (password == null || password.isEmpty) {
      throw UsageException('Le mot de passe ne peut pas être vide.', usage);
    }

    final historyRepository = HistoryRepositoryImpl(
      dataSource: HistoryLocalDataSource(
        customStoragePath: '.file_encryptor_history.json',
      ),
    );
    final useCase = DecryptFileUseCase(
      cryptoRepository: CryptoRepositoryImpl(),
      fileRepository: FileRepositoryImpl(),
      historyRepository: historyRepository,
    );

    stdout.write('\r[0%] Lecture et vérification du conteneur .enc...');
    final result = await useCase(
      inputPath: input,
      outputDirectoryOrPath: results['output'] as String?,
      password: password,
      rethrowOnError: true,
      onProgress: (progress) {
        final percentage = (progress.percentage * 100).clamp(0, 100).round();
        stdout.write('\r[$percentage%] ${progress.phase}');
      },
    );

    stdout.writeln();

    if (!result.isSuccess) {
      stderr.writeln(
        'Erreur : ${_friendlyError(result.errorMessage ?? 'Échec du déchiffrement.')}',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('Fichier déchiffré avec succès.');
    stdout.writeln();
    stdout.writeln('Fichier restauré : ${result.outputPath}');
    if (result.originalFileName != null &&
        result.originalFileName!.isNotEmpty) {
      stdout.writeln('Nom original : ${result.originalFileName}');
    }
    stdout.writeln('Durée : ${result.duration.inMilliseconds} ms');
  }

  Future<String?> _readPassword(String? supplied) async {
    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }

    if (!stdin.hasTerminal) {
      return null;
    }

    stdout.write('Mot de passe : ');
    final previousMode = stdin.echoMode;
    stdin.echoMode = false;
    try {
      final input = stdin.readLineSync();
      stdout.writeln();
      return input == null || input.isEmpty ? null : input;
    } finally {
      stdin.echoMode = previousMode;
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (error is FileEncryptorException) {
      return error.message;
    }
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
