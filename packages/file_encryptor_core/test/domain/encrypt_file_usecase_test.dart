import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptFileUseCase Tests', () {
    late Directory tempDir;
    late CryptoRepository cryptoRepository;
    late FileRepository fileRepository;
    late HistoryRepository historyRepository;
    late EncryptFileUseCase useCase;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('encrypt_usecase_test_');
      cryptoRepository = CryptoRepositoryImpl();
      fileRepository = FileRepositoryImpl();
      historyRepository = HistoryRepositoryImpl(
        dataSource: HistoryLocalDataSource(
          customStoragePath: '${tempDir.path}${Platform.pathSeparator}history.json',
        ),
      );

      useCase = EncryptFileUseCase(
        cryptoRepository: cryptoRepository,
        fileRepository: fileRepository,
        historyRepository: historyRepository,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('encrypts a valid file successfully and notifies progress', () async {
      final inputPath = '${tempDir.path}${Platform.pathSeparator}sample.txt';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}sample.txt.enc';
      await File(inputPath).writeAsString('Secret clear text data for unit test.');

      final progressSteps = <ProcessingProgress>[];

      final result = await useCase(
        inputPath: inputPath,
        outputPath: outputPath,
        password: 'TestPassword123',
        onProgress: (p) => progressSteps.add(p),
      );

      expect(result.isSuccess, isTrue);
      expect(result.outputPath, equals(outputPath));
      expect(result.originalFileName, equals('sample.txt'));
      expect(await File(outputPath).exists(), isTrue);
      expect(progressSteps, isNotEmpty);
      expect(progressSteps.last.percentage, equals(1.0));

      // Vérifier que l'historique a bien enregistré l'opération
      final history = await historyRepository.getHistory();
      expect(history.length, equals(1));
      expect(history.first.operation, equals(CryptoOperationType.encrypt));
      expect(history.first.isSuccess, isTrue);
    });

    test('fails gracefully when input file does not exist', () async {
      final nonExistentPath = '${tempDir.path}${Platform.pathSeparator}unknown.txt';

      final result = await useCase(
        inputPath: nonExistentPath,
        password: 'Password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('FileNotFoundException'));

      final history = await historyRepository.getHistory();
      expect(history.length, equals(1));
      expect(history.first.isSuccess, isFalse);
    });

    test('rethrows exception when rethrowOnError is true', () async {
      final nonExistentPath = '${tempDir.path}${Platform.pathSeparator}unknown.txt';

      expect(
        () => useCase(
          inputPath: nonExistentPath,
          password: 'Password123',
          rethrowOnError: true,
        ),
        throwsA(isA<FileNotFoundException>()),
      );
    });
  });
}
