import 'dart:io';

import 'package:args/args.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:path/path.dart' as p;

class CliApplication {
  final CliIo io;
  final HistoryRepository historyRepository;
  final EncryptFileUseCase encryptUseCase;
  final DecryptFileUseCase decryptUseCase;
  final bool interactiveMode;

  factory CliApplication({
    CliIo? io,
    HistoryRepository? historyRepository,
    bool interactiveMode = false,
  }) {
    final history = historyRepository ?? HistoryRepositoryImpl();
    return CliApplication._(
      io: io ?? const CliIo(),
      historyRepository: history,
      interactiveMode: interactiveMode,
    );
  }

  CliApplication._({
    required this.io,
    required this.historyRepository,
    required this.interactiveMode,
  })  : encryptUseCase = EncryptFileUseCase(
          cryptoRepository: CryptoRepositoryImpl(),
          fileRepository: FileRepositoryImpl(),
          historyRepository: historyRepository,
        ),
        decryptUseCase = DecryptFileUseCase(
          cryptoRepository: CryptoRepositoryImpl(),
          fileRepository: FileRepositoryImpl(),
          historyRepository: historyRepository,
        );

  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      if (!interactiveMode || !stdin.hasTerminal) {
        io.writeln(_interactiveMenuText());
        return 0;
      }
      return _runInteractiveMenu();
    }

    if (_isHelpRequest(arguments)) {
      io.writeln(_usageText());
      return 0;
    }

    final command = arguments.first;
    switch (command) {
      case 'encrypt':
        return _runEncrypt(arguments.sublist(1));
      case 'decrypt':
        return _runDecrypt(arguments.sublist(1));
      case 'history':
        return _runHistory(arguments.sublist(1));
      default:
        io.error('Erreur : commande inconnue.');
        io.error(_usageText());
        return 1;
    }
  }

  Future<int> _runInteractiveMenu() async {
    if (!stdin.hasTerminal) {
      io.writeln(_interactiveMenuText());
      return 0;
    }

    io.writeln(_interactiveMenuText());
    io.write('Votre choix : ');

    final choice = io.readLine();
    io.writeln();

    switch (choice?.trim()) {
      case '1':
        return _runInteractiveEncrypt();
      case '2':
        return _runInteractiveDecrypt();
      case '3':
        return _runHistory([]);
      case '4':
      case 'q':
      case 'Q':
        io.writeln('Au revoir.');
        return 0;
      default:
        io.writeln(_usageText());
        return 0;
    }
  }

  Future<int> _runInteractiveEncrypt() async {
    io.write('Chemin du fichier source : ');
    final input = io.readLine();
    if (input == null || input.trim().isEmpty) {
      io.error('Erreur : le chemin du fichier source est requis.');
      return 1;
    }

    io.write('Chemin de sortie (.enc) [vide = chemin par défaut] : ');
    final output = io.readLine();

    final password = await _resolvePassword(null, confirm: true);
    if (password == null) {
      return 1;
    }

    final args = <String>[
      'encrypt',
      input.trim(),
      if ((output ?? '').trim().isNotEmpty) ...['--output', output!.trim()],
      '--password',
      password,
    ];

    return run(args);
  }

  Future<int> _runInteractiveDecrypt() async {
    io.write('Chemin du fichier chiffré (.enc) : ');
    final input = io.readLine();
    if (input == null || input.trim().isEmpty) {
      io.error('Erreur : le chemin du fichier chiffré est requis.');
      return 1;
    }

    io.write('Chemin de sortie [vide = emplacement par défaut] : ');
    final output = io.readLine();

    final password = await _resolvePassword(null);
    if (password == null) {
      return 1;
    }

    final args = <String>[
      'decrypt',
      input.trim(),
      if ((output ?? '').trim().isNotEmpty) ...['--output', output!.trim()],
      '--password',
      password,
    ];

    return run(args);
  }

  Future<int> _runEncrypt(List<String> arguments) async {
    if (arguments.isEmpty) {
      io.error(
        'Usage: file-encryptor encrypt <file> [--output <path>] [--password <password>]',
      );
      return 1;
    }

    if (arguments.first == '--help' || arguments.first == '-h') {
      io.writeln(_commandHelp('encrypt', 'Chiffrer un fichier'));
      return 0;
    }

    final parser = ArgParser()
      ..addOption('output', abbr: 'o')
      ..addOption('password', abbr: 'p');

    final results = _safeParse(parser, arguments);
    if (results == null) {
      io.error('Erreur : arguments invalides.');
      io.error(_commandHelp('encrypt', 'Chiffrer un fichier'));
      return 1;
    }

    if (results.rest.length != 1) {
      io.error(
        'Usage: file-encryptor encrypt <file> [--output <path>] [--password <password>]',
      );
      return 1;
    }

    final input = results.rest.single;
    final password = await _resolvePassword(
      results['password'] as String?,
      confirm: true,
    );
    if (password == null) {
      return 1;
    }

    io.writeln('Chiffrement de ${p.basename(input)}...');
    try {
      final result = await encryptUseCase.call(
        inputPath: input,
        outputPath: results['output'] as String?,
        password: password,
        rethrowOnError: true,
        onProgress: _printProgress,
      );

      if (!result.isSuccess) {
        io.error(
          'Erreur : ${_friendlyError(result.errorMessage ?? 'Échec du chiffrement.')}',
        );
        return 1;
      }

      io.writeln();
      io.writeln('Fichier chiffré avec succès.');
      io.writeln();
      io.writeln('Fichier de sortie : ${result.outputPath}');
      io.writeln('Taille : ${result.fileSizeBytes} octets');
      io.writeln('Durée : ${result.duration.inMilliseconds} ms');
      return 0;
    } catch (error) {
      io.error('Erreur : ${_friendlyError(error)}');
      return 1;
    }
  }

  Future<int> _runDecrypt(List<String> arguments) async {
    if (arguments.isEmpty) {
      io.error(
        'Usage: file-encryptor decrypt <file.enc> [--output <path-or-directory>] [--password <password>]',
      );
      return 1;
    }

    if (arguments.first == '--help' || arguments.first == '-h') {
      io.writeln(_commandHelp('decrypt', 'Déchiffrer un fichier .enc'));
      return 0;
    }

    final parser = ArgParser()
      ..addOption('output', abbr: 'o')
      ..addOption('password', abbr: 'p');

    final results = _safeParse(parser, arguments);
    if (results == null) {
      io.error('Erreur : arguments invalides.');
      io.error(_commandHelp('decrypt', 'Déchiffrer un fichier .enc'));
      return 1;
    }

    if (results.rest.length != 1) {
      io.error(
        'Usage: file-encryptor decrypt <file.enc> [--output <path-or-directory>] [--password <password>]',
      );
      return 1;
    }

    final input = results.rest.single;
    final password = await _resolvePassword(results['password'] as String?);
    if (password == null) {
      return 1;
    }

    io.writeln('Déchiffrement de ${p.basename(input)}...');
    try {
      final result = await decryptUseCase.call(
        inputPath: input,
        outputDirectoryOrPath: results['output'] as String?,
        password: password,
        rethrowOnError: true,
        onProgress: _printProgress,
      );

      if (!result.isSuccess) {
        io.error(
          'Erreur : ${_friendlyError(result.errorMessage ?? 'Échec du déchiffrement.')}',
        );
        return 1;
      }

      io.writeln();
      io.writeln('Fichier déchiffré avec succès.');
      io.writeln();
      io.writeln('Fichier restauré : ${result.outputPath}');
      if (result.originalFileName != null &&
          result.originalFileName!.isNotEmpty) {
        io.writeln('Nom original : ${result.originalFileName}');
      }
      io.writeln('Durée : ${result.duration.inMilliseconds} ms');
      return 0;
    } catch (error) {
      io.error('Erreur : ${_friendlyError(error)}');
      return 1;
    }
  }

  Future<int> _runHistory(List<String> arguments) async {
    if (arguments.firstOrNull == '--help' || arguments.firstOrNull == '-h') {
      io.writeln(
        _commandHelp('history', 'Afficher l’historique des opérations'),
      );
      return 0;
    }

    final parser = ArgParser()..addFlag('clear', negatable: false);
    final results = _safeParse(parser, arguments);
    if (results == null) {
      io.error('Erreur : arguments invalides.');
      io.error(_commandHelp('history', 'Afficher l’historique des opérations'));
      return 1;
    }

    if (results['clear'] == true) {
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
      io.writeln(
        '${item.timestamp.toLocal().toIso8601String()} | ${item.operation.name.toUpperCase()} | $status | ${item.fileName}',
      );
      io.writeln('  Source: ${item.sourcePath}');
      io.writeln('  Destination: ${item.destinationPath}');
      io.writeln('  Taille: ${item.fileSizeBytes} octets');
      if (!item.isSuccess && item.errorMessage != null) {
        io.writeln('  Erreur: ${item.errorMessage}');
      }
    }
    return 0;
  }

  ArgResults? _safeParse(ArgParser parser, List<String> arguments) {
    try {
      return parser.parse(arguments);
    } on FormatException {
      return null;
    }
  }

  Future<String?> _resolvePassword(
    String? provided, {
    bool confirm = false,
  }) async {
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }

    if (!stdin.hasTerminal) {
      io.error(
        'Erreur : mot de passe requis. Utilisez --password ou exécutez la commande dans un terminal interactif.',
      );
      return null;
    }

    io.write('Mot de passe : ');
    final first = io.readLineHidden();
    if (first == null || first.isEmpty) {
      io.error('Erreur : le mot de passe ne peut pas être vide.');
      return null;
    }

    if (confirm) {
      io.write('Confirmer le mot de passe : ');
      final second = io.readLineHidden();
      if (first != second) {
        io.error('Erreur : les mots de passe ne correspondent pas.');
        return null;
      }
    }
    return first;
  }

  void _printProgress(ProcessingProgress progress) {
    final percentage =
        (progress.percentage * 100).clamp(0, 100).toStringAsFixed(0);
    io.write('\r[$percentage%] ${progress.phase}');
  }

  String _friendlyError(Object error) {
    if (error is FileEncryptorException) {
      if (error is FileNotFoundException) {
        return 'le fichier spécifié est introuvable.';
      }
      if (error is InvalidPasswordException) {
        return 'mot de passe incorrect ou fichier altéré.';
      }
      if (error is InvalidHeaderException) {
        return 'le fichier n\'est pas un fichier FileEncryptor valide.';
      }
      if (error is CorruptedFileException) {
        return 'le fichier chiffré semble être corrompu ou incomplet.';
      }
      if (error is StorageException) {
        return 'impossible d\'écrire le fichier de sortie.';
      }
      return error.message;
    }

    final text = error.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }

  String _usageText() {
    return '''FileEncryptor CLI

Outil de chiffrement et de déchiffrement de fichiers.

Choisissez une action au lancement si aucun argument n’est fourni.

Usage:
  file_encryptor <command> [arguments]

Commands:
  encrypt    Chiffrer un fichier
  decrypt    Déchiffrer un fichier
  history    Afficher l’historique

Options:
  -h, --help    Afficher cette aide''';
  }

  String _interactiveMenuText() {
    return '''FileEncryptor
Que souhaitez-vous faire ?

1) Chiffrer un fichier
2) Déchiffrer un fichier
3) Voir l’historique
4) Quitter''';
  }

  String _commandHelp(String commandName, String description) {
    switch (commandName) {
      case 'encrypt':
        return '''Usage:
  file_encryptor encrypt <input> [options]

Description:
  $description

Options:
  -o, --output <path>    Chemin du fichier .enc de sortie
  -p, --password <pass>  Mot de passe
  -h, --help             Afficher cette aide''';
      case 'decrypt':
        return '''Usage:
  file_encryptor decrypt <input.enc> [options]

Description:
  $description

Options:
  -o, --output <path>    Chemin ou dossier de sortie
  -p, --password <pass>  Mot de passe
  -h, --help             Afficher cette aide''';
      case 'history':
        return '''Usage:
  file_encryptor history [--clear]

Description:
  $description

Options:
  --clear                Effacer tout l’historique
  -h, --help             Afficher cette aide''';
      default:
        return _usageText();
    }
  }

  bool _isHelpRequest(List<String> arguments) {
    if (arguments.isEmpty) return false;
    return arguments.length == 1 &&
        (arguments.first == '--help' || arguments.first == '-h');
  }
}

class CliIo {
  const CliIo();

  void write(String message) => stdout.write(message);
  void writeln([String message = '']) => stdout.writeln(message);
  void error(String message) => stderr.writeln(message);

  String? readLine() => stdin.readLineSync();

  String? readLineHidden() {
    if (!stdin.hasTerminal) {
      return readLine();
    }

    try {
      Process.runSync('stty', ['-echo'], runInShell: true);
      final line = readLine();
      return line;
    } finally {
      Process.runSync('stty', ['echo'], runInShell: true);
      stdout.writeln();
    }
  }
}
