import 'dart:typed_data';

/// Résultat du chiffrement de données brutes contenant le ciphertext et son tag d'authentification MAC.
class EncryptedPayload {
  final Uint8List ciphertext;
  final Uint8List authTag;

  const EncryptedPayload({
    required this.ciphertext,
    required this.authTag,
  });
}

/// Contrat d'interface pour les primitives cryptographiques.
abstract class CryptoRepository {
  /// Génère un sel cryptographiquement sécurisé (par défaut 32 octets / 256 bits).
  Uint8List generateSalt([int length = 32]);

  /// Génère un nonce / IV cryptographiquement sécurisé (par défaut 12 octets / 96 bits).
  Uint8List generateNonce([int length = 12]);

  /// Dérive une clé AES de 256 bits à partir d'un mot de passe et d'un sel via PBKDF2 (HMAC-SHA256, 100k itérations).
  Future<Uint8List> deriveKey({
    required String password,
    required List<int> salt,
  });

  /// Chiffre un tableau d'octets avec AES-256-GCM.
  Future<EncryptedPayload> encryptBytes({
    required List<int> clearBytes,
    required List<int> key,
    required List<int> nonce,
    List<int>? aad,
  });

  /// Déchiffre un tableau d'octets avec AES-256-GCM et vérifie son tag d'authentification.
  /// Lève [InvalidPasswordException] si le mot de passe / clé ou le tag est invalide.
  Future<Uint8List> decryptBytes({
    required List<int> ciphertext,
    required List<int> authTag,
    required List<int> key,
    required List<int> nonce,
    List<int>? aad,
  });
}
