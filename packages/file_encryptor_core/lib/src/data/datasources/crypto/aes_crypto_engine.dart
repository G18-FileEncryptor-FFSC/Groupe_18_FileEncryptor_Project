import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import '../../../domain/exceptions/crypto_exceptions.dart';

/// Moteur cryptographique de bas niveau gérant les primitives AES-256-GCM et la dérivation PBKDF2.
class AesCryptoEngine {
  final AesGcm _aesGcm;
  final Pbkdf2 _pbkdf2;
  final Random _secureRandom;

  AesCryptoEngine({
    AesGcm? aesGcm,
    Pbkdf2? pbkdf2,
    Random? secureRandom,
  })  : _aesGcm = aesGcm ?? AesGcm.with256bits(),
        _pbkdf2 = pbkdf2 ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: 100000,
              bits: 256,
            ),
        _secureRandom = secureRandom ?? Random.secure();

  /// Génère un tableau d'octets cryptographiquement sécurisé.
  Uint8List generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  /// Génère un sel de 32 octets (256 bits) pour PBKDF2.
  Uint8List generateSalt([int length = 32]) => generateRandomBytes(length);

  /// Génère un Nonce/IV de 12 octets (96 bits) pour AES-GCM.
  Uint8List generateNonce([int length = 12]) => generateRandomBytes(length);

  /// Dérive une clé AES de 256 bits à partir d'un mot de passe et d'un sel avec PBKDF2 (HMAC-SHA256, 100 000 itérations).
  Future<Uint8List> deriveKey({
    required String password,
    required List<int> salt,
  }) async {
    final passwordBytes = utf8.encode(password);
    final secretKey = SecretKey(passwordBytes);

    final derived = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );

    final extractedBytes = await derived.extractBytes();
    return Uint8List.fromList(extractedBytes);
  }

  /// Chiffre les octets en clair avec AES-256-GCM.
  /// Accepte des données associées (AAD) optionnelles pour garantir l'authenticité de l'en-tête.
  Future<({Uint8List ciphertext, Uint8List authTag})> encryptBytes({
    required List<int> clearBytes,
    required List<int> key,
    required List<int> nonce,
    List<int>? aad,
  }) async {
    final secretKey = SecretKey(key);
    final secretBox = await _aesGcm.encrypt(
      clearBytes,
      secretKey: secretKey,
      nonce: nonce,
      aad: aad ?? const <int>[],
    );

    return (
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      authTag: Uint8List.fromList(secretBox.mac.bytes),
    );
  }

  /// Déchiffre les octets chiffrés et vérifie le tag d'authentification MAC avec AES-256-GCM.
  /// Lève [InvalidPasswordException] si la clé est erronée ou si le tag ne correspond pas.
  Future<Uint8List> decryptBytes({
    required List<int> ciphertext,
    required List<int> authTag,
    required List<int> key,
    required List<int> nonce,
    List<int>? aad,
  }) async {
    final secretKey = SecretKey(key);
    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(authTag),
    );

    try {
      final decrypted = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aad ?? const <int>[],
      );
      return Uint8List.fromList(decrypted);
    } on SecretBoxAuthenticationError catch (e) {
      throw InvalidPasswordException(
        'Mot de passe incorrect ou intégrité du fichier compromise (échec du tag d\'authentification).',
        e,
      );
    } catch (e) {
      if (e is FileEncryptorException) rethrow;
      throw InvalidPasswordException(
        'Échec du déchiffrement des données.',
        e,
      );
    }
  }
}
