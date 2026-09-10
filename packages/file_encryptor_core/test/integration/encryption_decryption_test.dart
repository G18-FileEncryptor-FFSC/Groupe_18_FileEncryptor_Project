import 'dart:io';
import 'dart:typed_data';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('Encryption & Decryption Integration Tests', () {
    late Directory tempDir;
    late EncryptFileUseCase encryptUseCase;
    late DecryptFileUseCase decryptUseCase;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('integration_test_');

      final cryptoRepository = CryptoRepositoryImpl();
      final fileRepository = FileRepositoryImpl();
      final historyRepository = HistoryRepositoryImpl(
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

    test('Full End-to-End roundtrip with binary data (exact byte-to-byte match)', () async {
      final originalFilePath = '${tempDir.path}${Platform.pathSeparator}binary_image.bin';
      final encFilePath = '${tempDir.path}${Platform.pathSeparator}binary_image.bin.enc';
      final restoreDir = '${tempDir.path}${Platform.pathSeparator}restored_folder';

      // 1. Création d'un fichier binaire aléatoire/pseudorandom de 64 Ko
      final rawData = Uint8List(64 * 1024);
      for (var i = 0; i < rawData.length; i++) {
        rawData[i] = (i * 31 + 7) % 256;
      }
      await File(originalFilePath).writeAsBytes(rawData);

      const password = 'StrongPassword!2026';

      // 2. Chiffrement
      final encResult = await encryptUseCase(
        inputPath: originalFilePath,
        outputPath: encFilePath,
        password: password,
      );

      expect(encResult.isSuccess, isTrue);
      expect(await File(encFilePath).exists(), isTrue);

      // Vérifier le format binaire de sortie (Magic Bytes FENC)
      final encBytes = await File(encFilePath).readAsBytes();
      expect(encBytes.sublist(0, 4), equals([0x46, 0x45, 0x4E, 0x43])); // FENC
      expect(encBytes[4], equals(0x01)); // Version 1

      // 3. Déchiffrement
      final decResult = await decryptUseCase(
        inputPath: encFilePath,
        outputDirectoryOrPath: restoreDir,
        password: password,
      );

      expect(decResult.isSuccess, isTrue);
      expect(decResult.originalFileName, equals('binary_image.bin'));

      final restoredFile = File(decResult.outputPath);
      expect(await restoredFile.exists(), isTrue);

      final restoredBytes = await restoredFile.readAsBytes();
      expect(restoredBytes, equals(rawData));
    });

    test('Rejects decryption when password is wrong', () async {
      final originalFilePath = '${tempDir.path}${Platform.pathSeparator}document.pdf';
      final encFilePath = '${tempDir.path}${Platform.pathSeparator}document.pdf.enc';

      await File(originalFilePath).writeAsString('Confidential PDF contents');

      await encryptUseCase(
        inputPath: originalFilePath,
        outputPath: encFilePath,
        password: 'RightPassword123',
      );

      final result = await decryptUseCase(
        inputPath: encFilePath,
        password: 'WrongPassword999',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('InvalidPasswordException'));
    });

    test('Fails authentication when ciphertext is altered', () async {
      final originalFilePath = '${tempDir.path}${Platform.pathSeparator}contract.txt';
      final encFilePath = '${tempDir.path}${Platform.pathSeparator}contract.txt.enc';

      await File(originalFilePath).writeAsString('Sign here for agreement');

      await encryptUseCase(
        inputPath: originalFilePath,
        outputPath: encFilePath,
        password: 'Password!',
      );

      // Altération d'un octet dans le payload chiffré
      final encFile = File(encFilePath);
      final bytes = await encFile.readAsBytes();
      // On altère un octet au milieu
      bytes[bytes.length - 20] ^= 0xFF;
      await encFile.writeAsBytes(bytes);

      final result = await decryptUseCase(
        inputPath: encFilePath,
        password: 'Password!',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('InvalidPasswordException'));
    });

    test('Fails authentication when header/metadata is tampered (AAD integrity)', () async {
      final originalFilePath = '${tempDir.path}${Platform.pathSeparator}report.docx';
      final encFilePath = '${tempDir.path}${Platform.pathSeparator}report.docx.enc';

      await File(originalFilePath).writeAsString('Annual Report 2026');

      await encryptUseCase(
        inputPath: originalFilePath,
        outputPath: encFilePath,
        password: 'Password!',
      );

      // Altération du nom original dans l'en-tête (octet 50)
      final encFile = File(encFilePath);
      final bytes = await encFile.readAsBytes();
      bytes[50] ^= 0x01; // altère le premier caractère du nom
      await encFile.writeAsBytes(bytes);

      final result = await decryptUseCase(
        inputPath: encFilePath,
        password: 'Password!',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('InvalidPasswordException'));
    });
  });
}
