import 'package:cli/cli.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';
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
    expect(io.output.join('\n'), contains('encrypt'));
    expect(io.output.join('\n'), contains('decrypt'));
    expect(io.output.join('\n'), contains('history'));
  });

  test('refuse encrypt sans fichier', () async {
    final io = BufferIo();
    final code = await CliApplication(io: io).run(['encrypt']);

    expect(code, 1);
    expect(io.errors.join('\n'), contains('Usage'));
  });

  test('refuse une commande inconnue', () async {
    final io = BufferIo();
    final code = await CliApplication(io: io).run(['unknown']);

    expect(code, 1);
    expect(io.errors.join('\n'), isNotEmpty);
  });

  test('history --clear utilise le repository', () async {
    final history = FakeHistoryRepository();
    history.items.add(HistoryItem(
      id: '1',
      operation: CryptoOperationType.encrypt,
      fileName: 'test.txt',
      sourcePath: 'test.txt',
      destinationPath: 'test.txt.enc',
      timestamp: DateTime(2026),
      fileSizeBytes: 10,
      isSuccess: true,
    ));
    final io = BufferIo();
    final code = await CliApplication(io: io, historyRepository: history).run(['history', '--clear']);

    expect(code, 0);
    expect(history.items, isEmpty);
    expect(io.output.join('\n'), contains('Historique effacé'));
  });
}
