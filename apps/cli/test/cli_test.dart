import 'dart:io';

import 'package:cli/cli.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class FakeHistoryRepository implements HistoryRepository {
  final List<HistoryItem> items = [];

  @override
  Future<List<HistoryItem>> getHistory() async => List.unmodifiable(items);

  @override
  Future<void> saveHistoryItem(HistoryItem item) async => items.add(item);

  @override
  Future<void> clearHistory() async => items.clear();
}

class BufferIo extends CliIo {
  final List<String> output = [];
  final List<String> errors = [];

  BufferIo();

  @override
  void write(String message) => output.add(message);

  @override
  void writeln([String message = '']) => output.add(message);

  @override
  void error(String message) => errors.add(message);
}

void main() {
  test('affiche l’aide avec succès', () async {
    final io = BufferIo();
    final code = await CliApplication(io: io).run(['--help']);

    expect(code, 0);
    final joined = io.output.join('\n');
    expect(joined, contains('FileEncryptor CLI'));
    expect(joined, contains('encrypt'));
    expect(joined, contains('decrypt'));
    expect(joined, contains('history'));
  });

  test('affiche le menu de sélection si aucun argument n’est fourni en mode non interactif', () async {
    final io = BufferIo();
    final code = await CliApplication(io: io).run([]);

    expect(code, 0);
    final joined = io.output.join('\n');
    expect(joined, contains('FileEncryptor'));
    expect(joined, contains('Que souhaitez-vous faire ?'));
    expect(joined, contains('1) Chiffrer un fichier'));
    expect(joined, contains('2) Déchiffrer un fichier'));
    expect(joined, contains('3) Voir l’historique'));
    expect(joined, contains('4) Quitter'));
  });

  test('refuse encrypt sans fichier', () async {
    final io = BufferIo();
    final code = await CliApplication(io: io).run(['encrypt']);

    expect(code, 1);
    expect(io.errors.join('\n'), contains('Usage: file-encryptor encrypt'));
  });

  test('refuse une commande inconnue', () async {
    final io = BufferIo();
    final code = await CliApplication(io: io).run(['unknown']);

    expect(code, 1);
    expect(io.errors.join('\n'), contains('commande inconnue'));
  });

  test('history --clear utilise le repository', () async {
    final history = FakeHistoryRepository();
    history.items.add(
      HistoryItem(
        id: '1',
        operation: CryptoOperationType.encrypt,
        fileName: 'test.txt',
        sourcePath: 'test.txt',
        destinationPath: 'test.txt.enc',
        timestamp: DateTime(2026),
        fileSizeBytes: 10,
        isSuccess: true,
      ),
    );
    final io = BufferIo();
    final code = await CliApplication(
      io: io,
      historyRepository: history,
    ).run(['history', '--clear']);

    expect(code, 0);
    expect(history.items, isEmpty);
    expect(io.output.join('\n'), contains('Historique effacé'));
  });

  test('round trip encrypt/decrypt avec un fichier temporaire', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'file_encryptor_cli_',
    );
    addTearDown(() async => tempDir.delete(recursive: true));

    final sourcePath = p.join(tempDir.path, 'demo.txt');
    const originalContent = 'Bonjour FileEncryptor !\n';
    final sourceFile = File(sourcePath)..writeAsStringSync(originalContent);

    final outputPath = p.join(tempDir.path, 'demo.txt.enc');
    final restoredPath = p.join(tempDir.path, 'restored.txt');

    final io = BufferIo();
    final app = CliApplication(io: io);

    final encryptCode = await app.run([
      'encrypt',
      sourceFile.path,
      '--output',
      outputPath,
      '--password',
      'secret-password',
    ]);

    expect(encryptCode, 0);
    expect(File(outputPath).existsSync(), isTrue);

    final decryptCode = await app.run([
      'decrypt',
      outputPath,
      '--output',
      restoredPath,
      '--password',
      'secret-password',
    ]);

    expect(decryptCode, 0);
    expect(File(restoredPath).existsSync(), isTrue);
    expect(File(restoredPath).readAsStringSync(), originalContent);
  });
}
