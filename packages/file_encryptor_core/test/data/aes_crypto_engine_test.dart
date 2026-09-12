import 'dart:convert';
import 'dart:typed_data';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:test/test.dart';

void main() {
  group('AesCryptoEngine Tests', () {
    late AesCryptoEngine engine;

    setUp(() {
      engine = AesCryptoEngine();
    });

    test('generateSalt returns 32 bytes by default and produces different values', () {
      final salt1 = engine.generateSalt();
      final salt2 = engine.generateSalt();

      expect(salt1.length, equals(32));
      expect(salt2.length, equals(32));
      expect(salt1, isNot(equals(salt2)));
    });

    test('generateNonce returns 12 bytes by default and produces different values', () {
      final nonce1 = engine.generateNonce();
      final nonce2 = engine.generateNonce();

      expect(nonce1.length, equals(12));
      expect(nonce2.length, equals(12));
      expect(nonce1, isNot(equals(nonce2)));
    });

    test('deriveKey produces a 32-byte (256 bits) key deterministically', () async {
      const password = 'SuperSecretPassword123!';
      final salt = engine.generateSalt();

      final key1 = await engine.deriveKey(password: password, salt: salt);
      final key2 = await engine.deriveKey(password: password, salt: salt);

      expect(key1.length, equals(32));
      expect(key1, equals(key2));

      // Un mot de passe différent doit donner une clé différente
      final key3 = await engine.deriveKey(password: 'OtherPassword', salt: salt);
      expect(key1, isNot(equals(key3)));
    });

    test('encryptBytes and decryptBytes roundtrip successfully with AAD', () async {
      const password = 'MyPassword456';
      final salt = engine.generateSalt();
      final nonce = engine.generateNonce();
      final key = await engine.deriveKey(password: password, salt: salt);

      final originalData = utf8.encode('Hello World! Confidential file content here.');
      final aad = utf8.encode('HeaderData-filename.txt');

      final encrypted = await engine.encryptBytes(
        clearBytes: originalData,
        key: key,
        nonce: nonce,
        aad: aad,
      );

      expect(encrypted.ciphertext.length, equals(originalData.length));
      expect(encrypted.authTag.length, equals(16));
      expect(encrypted.ciphertext, isNot(equals(originalData)));

      final decrypted = await engine.decryptBytes(
        ciphertext: encrypted.ciphertext,
        authTag: encrypted.authTag,
        key: key,
        nonce: nonce,
        aad: aad,
      );

      expect(decrypted, equals(originalData));
      expect(utf8.decode(decrypted), equals('Hello World! Confidential file content here.'));
    });

    test('decryptBytes fails with InvalidPasswordException if key is incorrect', () async {
      final salt = engine.generateSalt();
      final nonce = engine.generateNonce();
      final validKey = await engine.deriveKey(password: 'ValidPassword', salt: salt);
      final wrongKey = await engine.deriveKey(password: 'WrongPassword', salt: salt);

      final originalData = utf8.encode('Top Secret Data');
      final encrypted = await engine.encryptBytes(
        clearBytes: originalData,
        key: validKey,
        nonce: nonce,
      );

      expect(
        () async => engine.decryptBytes(
          ciphertext: encrypted.ciphertext,
          authTag: encrypted.authTag,
          key: wrongKey,
          nonce: nonce,
        ),
        throwsA(isA<InvalidPasswordException>()),
      );
    });

    test('decryptBytes fails with InvalidPasswordException if ciphertext is modified', () async {
      final salt = engine.generateSalt();
      final nonce = engine.generateNonce();
      final key = await engine.deriveKey(password: 'Key123', salt: salt);

      final originalData = utf8.encode('Important Message');
      final encrypted = await engine.encryptBytes(
        clearBytes: originalData,
        key: key,
        nonce: nonce,
      );

      final tamperedCiphertext = Uint8List.fromList(encrypted.ciphertext);
      tamperedCiphertext[0] ^= 0xFF; // Altération du premier octet

      expect(
        () async => engine.decryptBytes(
          ciphertext: tamperedCiphertext,
          authTag: encrypted.authTag,
          key: key,
          nonce: nonce,
        ),
        throwsA(isA<InvalidPasswordException>()),
      );
    });

    test('decryptBytes fails with InvalidPasswordException if auth tag is modified', () async {
      final salt = engine.generateSalt();
      final nonce = engine.generateNonce();
      final key = await engine.deriveKey(password: 'Key123', salt: salt);

      final originalData = utf8.encode('Important Message');
      final encrypted = await engine.encryptBytes(
        clearBytes: originalData,
        key: key,
        nonce: nonce,
      );

      final tamperedTag = Uint8List.fromList(encrypted.authTag);
      tamperedTag[0] ^= 0xFF;

      expect(
        () async => engine.decryptBytes(
          ciphertext: encrypted.ciphertext,
          authTag: tamperedTag,
          key: key,
          nonce: nonce,
        ),
        throwsA(isA<InvalidPasswordException>()),
      );
    });

    test('decryptBytes fails with InvalidPasswordException if AAD is altered', () async {
      final salt = engine.generateSalt();
      final nonce = engine.generateNonce();
      final key = await engine.deriveKey(password: 'Key123', salt: salt);

      final originalData = utf8.encode('Important Message');
      final aad = utf8.encode('OriginalAAD');

      final encrypted = await engine.encryptBytes(
        clearBytes: originalData,
        key: key,
        nonce: nonce,
        aad: aad,
      );

      final alteredAad = utf8.encode('AlteredAAD');

      expect(
        () async => engine.decryptBytes(
          ciphertext: encrypted.ciphertext,
          authTag: encrypted.authTag,
          key: key,
          nonce: nonce,
          aad: alteredAad,
        ),
        throwsA(isA<InvalidPasswordException>()),
      );
    });
  });
}
