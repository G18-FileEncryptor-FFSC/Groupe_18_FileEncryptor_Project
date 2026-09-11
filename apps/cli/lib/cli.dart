import 'dart:io';

import 'package:args/args.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:path/path.dart' as p;

class CliApplication {
  final CliIo io;
  final HistoryRepository historyRepository;
  final EncryptFileUseCase encryptUseCase;
  final DecryptFileUseCase decryptUseCase;

  CliApplication({CliIo? io, HistoryRepository? historyRepository})
      : io = io ?? const CliIo(),
        historyRepository = historyRepository ?? HistoryRepositoryImpl(),
        encryptUseCase = EncryptFileUseCase(
          cryptoRepository: CryptoRepositoryImpl(),
          fileRepository: FileRepositoryImpl(),
          historyRepository: historyRepository ?? HistoryRepositoryImpl(),
        ),
        decryptUseCase = DecryptFileUseCase(
          cryptoRepository: CryptoRepositoryImpl(),
          fileRepository: FileRepositoryImpl(),
          historyRepository: historyRepository ?? HistoryRepositoryImpl(),
        );

  Future<int> run(List<String> arguments) async {
    final parser = _buildParser();
    ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      io.error('Erreur: ${e.message}');
      io.error(parser.usage);
      return 1;
    }

    if (results['help'] == true || results.command == null) {
      io.writeln(parser.usage);
      return 0;
    }

    try {
      switch (results.command!.name) {
        case 'encrypt':
          return await _encrypt(results.command!);
        case 'decrypt':
          return await _decrypt(results.command!);
        case 'history':
          return await _history(results.command!);
        default:
          io.error('Commande inconnue.');
          return 1;
      }
    } catch (e) {
      io.error('Erreur: ${_cleanError(e)}');
      return 1;
    }
  }

  ArgParser _buildParser() {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Afficher cette aide.');

    final encrypt = ArgParser()
      ..addOption('output', abbr: 'o', help: 'Chemin du fichier .enc de sortie.')
      ..addOption('password', abbr: 'p', help: 'Mot de passe. Évitez cette option pour ne pas l’exposer dans l’historique du shell.')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Afficher l’aide du chiffrement.');

    final decrypt = ArgParser()
      ..addOption('output', abbr: 'o', help: 'Chemin du fichier ou dossier de sortie.')
      ..addOption('password', abbr: 'p', help: 'Mot de passe. Évitez cette option pour ne pas l’exposer dans l’historique du shell.')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Afficher l’aide du déchiffrement.');

    final history = ArgParser()
      ..addFlag('clear', negatable: false, help: 'Effacer tout l’historique.')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Afficher l’aide de l’historique.');

    parser
      ..addCommand('encrypt', encrypt)
      ..addCommand('decrypt', decrypt)
      ..addCommand('history', history);
    return parser;
  }

  Future<int> _encrypt(ArgResults args) async {
    if (args['help'] == true) {
      io.writeln('Usage: file-encryptor encrypt <file> [options]');
      io.writeln(args.usage);
      return 0;
    }
    if (args.rest.length != 1) {
      io.error('Usage: file-encryptor encrypt <file> [--output <path>] [--password <password>]');
      return 1;
    }
    final input = args.rest.single;
    final password = await _resolvePassword(args['password'] as String?, confirm: true);
    if (password == null) return 1;

    io.writeln('Chiffrement de ${p.basename(input)}...');
    final result = await encryptUseCase.call(
      inputPath: input,
      outputPath: args['output'] as String?,
      password: password,
      rethrowOnError: true,
      onProgress: _printProgress,
    );
    io.writeln('Succès: fichier chiffré -> ${result.outputPath}');
    io.writeln('Taille: ${result.fileSizeBytes} octets');
    io.writeln('Durée: ${result.duration.inMilliseconds} ms');
    return 0;
  }

  Future<int> _decrypt(ArgResults args) async {
    if (args['help'] == true) {
      io.writeln('Usage: file-encryptor decrypt <file.enc> [options]');
      io.writeln(args.usage);
      return 0;
    }
    if (args.rest.length != 1) {
      io.error('Usage: file-encryptor decrypt <file.enc> [--output <path-or-directory>] [--password <password>]');
      return 1;
    }
    final input = args.rest.single;
    final password = await _resolvePassword(args['password'] as String?);
    if (password == null) return 1;

    io.writeln('Déchiffrement de ${p.basename(input)}...');
    final result = await decryptUseCase.call(
      inputPath: input,
      outputDirectoryOrPath: args['output'] as String?,
      password: password,
      rethrowOnError: true,
      onProgress: _printProgress,
    );
    io.writeln('Succès: fichier restauré -> ${result.outputPath}');
    io.writeln('Taille: ${result.fileSizeBytes} octets');
    io.writeln('Durée: ${result.duration.inMilliseconds} ms');
    return 0;
  }

  Future<int> _history(ArgResults args) async {
    if (args['help'] == true) {
      io.writeln('Usage: file-encryptor history [--clear]');
      io.writeln(args.usage);
      return 0;
    }
    if (args['clear'] == true) {
      await historyRepository.clearHistory();
      io.writeln('Historique effacé.');
      return 0;
    }

    final items = await historyRepository.getHistory();
    if (items.isEmpty) {
      io.writeln('Aucune opération dans l’historique.');
      return 0;
    }

    io.writeln('Historique (${items.length} opération(s))');
    for (final item in items) {
      final status = item.isSuccess ? 'SUCCÈS' : 'ÉCHEC';
      io.writeln('${item.timestamp.toLocal().toIso8601String()} | ${item.operation.name.toUpperCase()} | $status | ${item.fileName}');
      io.writeln('  Source: ${item.sourcePath}');
      io.writeln('  Destination: ${item.destinationPath}');
      io.writeln('  Taille: ${item.fileSizeBytes} octets');
      if (!item.isSuccess && item.errorMessage != null) {
        io.writeln('  Erreur: ${item.errorMessage}');
      }
    }
    return 0;
  }

  Future<String?> _resolvePassword(String? provided, {bool confirm = false}) async {
    if (provided != null && provided.isNotEmpty) return provided;
    if (!stdin.hasTerminal) {
      io.error('Mot de passe requis: utilisez --password ou exécutez la commande dans un terminal interactif.');
      return null;
    }

    io.write('Mot de passe: ');
    final first = io.readLineHidden();
    if (first == null || first.isEmpty) {
      io.error('Le mot de passe ne peut pas être vide.');
      return null;
    }
    if (confirm) {
      io.write('Confirmer le mot de passe: ');
      final second = io.readLineHidden();
      if (first != second) {
        io.error('Les mots de passe ne correspondent pas.');
        return null;
      }
    }
    return first;
  }

  void _printProgress(ProcessingProgress progress) {
    final percentage = (progress.percentage * 100).clamp(0, 100).toStringAsFixed(0);
    io.writeln('[$percentage%] ${progress.phase}');
  }

  String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

class CliIo {
  const CliIo();

  void write(String message) => stdout.write(message);
  void writeln([String message = '']) => stdout.writeln(message);
  void error(String message) => stderr.writeln(message);
  Future<String?> readLine() => stdin.readLine();

  String? readLineHidden() {
    final line = stdin.readLineSync();
    return line;
  }
}
