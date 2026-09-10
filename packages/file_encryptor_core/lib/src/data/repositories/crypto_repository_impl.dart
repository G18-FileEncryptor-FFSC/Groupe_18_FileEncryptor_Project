import 'dart:typed_data';

import '../../domain/repositories/crypto_repository.dart';
import '../datasources/crypto/aes_crypto_engine.dart';

/// Implémentation concrète de [CryptoRepository] s'appuyant sur [AesCryptoEngine].
class CryptoRepositoryImpl implements CryptoRepository {
  final AesCryptoEngine _engine;

  CryptoRepositoryImpl({AesCryptoEngine? engine})
      : _engine = engine ?? AesCryptoEngine();

  @override
  Uint8List generateSalt([int length = 32]) {
    return _engine.generateSalt(length);
  }

  @override
  Uint8List generateNonce([int length = 12]) {
    return _engine.generateNonce(length);
  }

  @override
  Future<Uint8List> deriveKey({
    required String password,
    required List<int> salt,
  }) {
    return _engine.deriveKey(password: password, salt: salt);
  }

  @override
  Future<EncryptedPayload> encryptBytes({
    required List<int> clearBytes,
    required List<int> key,
    required List<int> nonce,
    List<int>? aad,
  }) async {
    final result = await _engine.encryptBytes(
      clearBytes: clearBytes,
      key: key,
      nonce: nonce,
      aad: aad,
    );

    return EncryptedPayload(
      ciphertext: result.ciphertext,
      authTag: result.authTag,
    );
  }

  @override
  Future<Uint8List> decryptBytes({
    required List<int> ciphertext,
    required List<int> authTag,
    required List<int> key,
    required List<int> nonce,
    List<int>? aad,
  }) {
    return _engine.decryptBytes(
      ciphertext: ciphertext,
      authTag: authTag,
      key: key,
      nonce: nonce,
      aad: aad,
    );
  }
}
