import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('DecryptFileUseCase Tests', () {
    late Directory tempDir;
    late CryptoRepository cryptoRepository;
    late FileRepository fileRepository;
    late HistoryRepository historyRepository;
    late EncryptFileUseCase encryptUseCase;
    late DecryptFileUseCase decryptUseCase;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('decrypt_usecase_test_');
      cryptoRepository = CryptoRepositoryImpl();
      fileRepository = FileRepositoryImpl();
      historyRepository = HistoryRepositoryImpl(
        dataSource: HistoryLocalDataSource(
          customStoragePath: '${tempDir.path}${Platform.pathSeparator}history.json',
        ),
      );

      encryptUseCase = EncryptFileUseCase(
        cryptoRepository: cryptoRepository,
        fileRepository: fileRepository,
        historyRepository: historyRepository,
      );

      decryptUseCase = DecryptFileUseCase(
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

    test('decrypts a previously encrypted file and restores original content', () async {
      final originalPath = '${tempDir.path}${Platform.pathSeparator}note.txt';
      final encPath = '${tempDir.path}${Platform.pathSeparator}note.txt.enc';
      const originalText = 'Important meeting notes: launch on September 2026.';
      await File(originalPath).writeAsString(originalText);

      // 1. Chiffrement
      await encryptUseCase(
        inputPath: originalPath,
        outputPath: encPath,
        password: 'Password999!',
      );

      // 2. Déchiffrement vers un nouveau dossier
      final outputDir = '${tempDir.path}${Platform.pathSeparator}restored';
      final progressSteps = <ProcessingProgress>[];

      final decryptResult = await decryptUseCase(
        inputPath: encPath,
        outputDirectoryOrPath: outputDir,
        password: 'Password999!',
        onProgress: (p) => progressSteps.add(p),
      );

      expect(decryptResult.isSuccess, isTrue);
      expect(decryptResult.originalFileName, equals('note.txt'));
      expect(progressSteps, isNotEmpty);
      expect(progressSteps.last.percentage, equals(1.0));

      final restoredFile = File(decryptResult.outputPath);
      expect(await restoredFile.exists(), isTrue);
      expect(await restoredFile.readAsString(), equals(originalText));
    });

    test('fails when password is wrong and records failure in history', () async {
      final originalPath = '${tempDir.path}${Platform.pathSeparator}secret.txt';
      final encPath = '${tempDir.path}${Platform.pathSeparator}secret.txt.enc';
      await File(originalPath).writeAsString('Confidential');

      await encryptUseCase(
        inputPath: originalPath,
        outputPath: encPath,
        password: 'CorrectPassword',
      );

      final result = await decryptUseCase(
        inputPath: encPath,
        password: 'BadPassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('InvalidPasswordException'));

      final history = await historyRepository.getHistory();
      final lastEntry = history.first;
      expect(lastEntry.operation, equals(CryptoOperationType.decrypt));
      expect(lastEntry.isSuccess, isFalse);
    });

    test('fails when encrypted file is missing', () async {
      final nonExistent = '${tempDir.path}${Platform.pathSeparator}none.enc';
      final result = await decryptUseCase(
        inputPath: nonExistent,
        password: 'AnyPassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('FileNotFoundException'));
    });
  });
}
