import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalFileService Tests', () {
    late LocalFileService service;
    late Directory tempDir;

    setUp(() async {
      service = LocalFileService();
      tempDir = await Directory.systemTemp.createTemp('file_encryptor_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('computeHeaderBytes formats header strictly according to .enc specifications', () {
      final salt = Uint8List(32)..fillRange(0, 32, 0xAA);
      final nonce = Uint8List(12)..fillRange(0, 12, 0xBB);
      const fileName = 'document.txt';

      final header = service.computeHeaderBytes(
        originalFileName: fileName,
        salt: salt,
        nonce: nonce,
      );

      // Magic Bytes (4 octets)
      expect(header.sublist(0, 4), equals([0x46, 0x45, 0x4E, 0x43]));
      // Version (1 octet)
      expect(header[4], equals(0x01));
      // Sel (32 octets)
      expect(header.sublist(5, 37), equals(salt));
      // Nonce (12 octets)
      expect(header.sublist(37, 49), equals(nonce));
      // Longueur nom (1 octet)
      expect(header[49], equals(fileName.length));
      // Nom (UTF-8)
      expect(utf8.decode(header.sublist(50, 50 + fileName.length)), equals(fileName));
    });

    test('serializeEncryptedFile and deserializeEncryptedFile roundtrip cleanly', () {
      final originalFile = EncryptedFile(
        originalFileName: 'photo_vacances.jpg',
        salt: Uint8List.fromList(List.generate(32, (i) => i)),
        nonce: Uint8List.fromList(List.generate(12, (i) => i + 10)),
        ciphertext: Uint8List.fromList(utf8.encode('EncryptedPayloadBytesHere1234567890')),
        authTag: Uint8List.fromList(List.generate(16, (i) => i + 20)),
      );

      final serializedBytes = service.serializeEncryptedFile(originalFile);
      final parsed = service.deserializeEncryptedFile(serializedBytes);

      expect(parsed.originalFileName, equals(originalFile.originalFileName));
      expect(parsed.salt, equals(originalFile.salt));
      expect(parsed.nonce, equals(originalFile.nonce));
      expect(parsed.ciphertext, equals(originalFile.ciphertext));
      expect(parsed.authTag, equals(originalFile.authTag));
    });

    test('deserialize throws InvalidHeaderException when magic bytes do not match', () {
      final originalFile = EncryptedFile(
        originalFileName: 'test.txt',
        salt: Uint8List(32),
        nonce: Uint8List(12),
        ciphertext: Uint8List(10),
        authTag: Uint8List(16),
      );

      final bytes = service.serializeEncryptedFile(originalFile);
      bytes[0] = 0x00; // Altère le 'F' de 'FENC'

      expect(
        () => service.deserializeEncryptedFile(bytes),
        throwsA(isA<InvalidHeaderException>()),
      );
    });

    test('deserialize throws InvalidHeaderException when version is unknown', () {
      final originalFile = EncryptedFile(
        originalFileName: 'test.txt',
        salt: Uint8List(32),
        nonce: Uint8List(12),
        ciphertext: Uint8List(10),
        authTag: Uint8List(16),
      );

      final bytes = service.serializeEncryptedFile(originalFile);
      bytes[4] = 0x99; // Version inconnue

      expect(
        () => service.deserializeEncryptedFile(bytes),
        throwsA(isA<InvalidHeaderException>()),
      );
    });

    test('deserialize throws CorruptedFileException on truncated files', () {
      final truncatedBytes = Uint8List(20); // Moins que le préfixe minimal de 50 octets
      expect(
        () => service.deserializeEncryptedFile(truncatedBytes),
        throwsA(isA<CorruptedFileException>()),
      );
    });

    test('file I/O operations work with actual files', () async {
      final filePath = '${tempDir.path}${Platform.pathSeparator}sample.txt';
      final content = utf8.encode('Hello File Service');

      expect(await service.fileExists(filePath), isFalse);

      await service.writeFileBytes(filePath, content);

      expect(await service.fileExists(filePath), isTrue);
      expect(await service.getFileSize(filePath), equals(content.length));

      final readContent = await service.readFileBytes(filePath);
      expect(readContent, equals(content));
    });
  });
}
