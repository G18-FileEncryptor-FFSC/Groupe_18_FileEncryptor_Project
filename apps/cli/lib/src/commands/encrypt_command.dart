import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';

class EncryptCommand extends Command<void> {
  EncryptCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Chemin du fichier .enc de sortie.',
      )
      ..addOption(
        'password',
        abbr: 'p',
        help: 'Mot de passe. Préférez la saisie interactive.',
      );
  }

  @override
  String get name => 'encrypt';

  @override
  String get description => 'Chiffrer un fichier.';

  @override
  String get invocation => '<input> [options]';

  @override
  Future<void> run() async {
    final results = argResults!;

    if (results.rest.length != 1) {
      throw UsageException('Un seul fichier d’entrée est requis.', usage);
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
    final useCase = EncryptFileUseCase(
      cryptoRepository: CryptoRepositoryImpl(),
      fileRepository: FileRepositoryImpl(),
      historyRepository: historyRepository,
    );

    stdout.write('\r[0%] Lecture du fichier source...');
    final result = await useCase(
      inputPath: input,
      outputPath: results['output'] as String?,
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
        'Erreur : ${_friendlyError(result.errorMessage ?? 'Échec du chiffrement.')}',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('Fichier chiffré avec succès.');
    stdout.writeln();
    stdout.writeln('Fichier de sortie : ${result.outputPath}');
    stdout.writeln('Taille : ${result.fileSizeBytes} octets');
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
