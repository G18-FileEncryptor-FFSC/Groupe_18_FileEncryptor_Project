import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('HistoryUseCases Tests', () {
    late Directory tempDir;
    late HistoryRepository repository;
    late GetHistoryUseCase getHistoryUseCase;
    late SaveHistoryUseCase saveHistoryUseCase;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('history_usecases_test_');
      repository = HistoryRepositoryImpl(
        dataSource: HistoryLocalDataSource(
          customStoragePath: '${tempDir.path}${Platform.pathSeparator}history.json',
        ),
      );
      getHistoryUseCase = GetHistoryUseCase(repository: repository);
      saveHistoryUseCase = SaveHistoryUseCase(repository: repository);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getHistory returns empty list initially', () async {
      final list = await getHistoryUseCase();
      expect(list, isEmpty);
    });

    test('saveHistory adds item and clear removes all items', () async {
      final item = HistoryItem(
        id: 'hist-1',
        operation: CryptoOperationType.encrypt,
        fileName: 'archive.zip',
        sourcePath: '/files/archive.zip',
        destinationPath: '/files/archive.zip.enc',
        timestamp: DateTime.now(),
        fileSizeBytes: 4096,
        isSuccess: true,
      );

      await saveHistoryUseCase(item);

      final listAfterSave = await getHistoryUseCase();
      expect(listAfterSave.length, equals(1));
      expect(listAfterSave.first.id, equals('hist-1'));
      expect(listAfterSave.first.fileName, equals('archive.zip'));

      await saveHistoryUseCase.clear();
      final listAfterClear = await getHistoryUseCase();
      expect(listAfterClear, isEmpty);
    });
  });
}
