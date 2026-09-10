import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('HistoryLocalDataSource Tests', () {
    late Directory tempDir;
    late String storagePath;
    late HistoryLocalDataSource dataSource;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_encryptor_history_');
      storagePath = '${tempDir.path}${Platform.pathSeparator}history.json';
      dataSource = HistoryLocalDataSource(customStoragePath: storagePath);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadHistory returns empty list when file does not exist', () async {
      final history = await dataSource.loadHistory();
      expect(history, isEmpty);
    });

    test('saveHistoryItem and loadHistory correctly persist items', () async {
      final item1 = HistoryItemModel(
        id: 'uuid-1',
        operation: 'encrypt',
        fileName: 'file1.txt',
        sourcePath: '/path/file1.txt',
        destinationPath: '/path/file1.txt.enc',
        timestamp: DateTime.now().toIso8601String(),
        fileSizeBytes: 1024,
        isSuccess: true,
      );

      final item2 = HistoryItemModel(
        id: 'uuid-2',
        operation: 'decrypt',
        fileName: 'file2.txt',
        sourcePath: '/path/file2.txt.enc',
        destinationPath: '/path/file2.txt',
        timestamp: DateTime.now().toIso8601String(),
        fileSizeBytes: 2048,
        isSuccess: false,
        errorMessage: 'Mot de passe erroné',
      );

      await dataSource.saveHistoryItem(item1);
      await dataSource.saveHistoryItem(item2);

      // Une nouvelle instance pointant vers le même fichier doit recharger les données
      final freshDataSource = HistoryLocalDataSource(customStoragePath: storagePath);
      final loaded = await freshDataSource.loadHistory();

      expect(loaded.length, equals(2));
      // item2 a été ajouté en second, donc il est en tête (antichronologique)
      expect(loaded[0].id, equals('uuid-2'));
      expect(loaded[0].isSuccess, isFalse);
      expect(loaded[0].errorMessage, equals('Mot de passe erroné'));

      expect(loaded[1].id, equals('uuid-1'));
      expect(loaded[1].isSuccess, isTrue);
    });

    test('clearHistory removes the file and subsequent load returns empty', () async {
      final item = HistoryItemModel(
        id: 'uuid-test',
        operation: 'encrypt',
        fileName: 'test.pdf',
        sourcePath: '/source.pdf',
        destinationPath: '/source.pdf.enc',
        timestamp: DateTime.now().toIso8601String(),
        fileSizeBytes: 512,
        isSuccess: true,
      );

      await dataSource.saveHistoryItem(item);
      expect(await dataSource.loadHistory(), isNotEmpty);

      await dataSource.clearHistory();
      expect(await dataSource.loadHistory(), isEmpty);
      expect(await File(storagePath).exists(), isFalse);
    });
  });
}
