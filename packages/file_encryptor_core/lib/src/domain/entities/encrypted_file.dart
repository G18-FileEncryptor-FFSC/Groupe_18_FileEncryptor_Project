import 'dart:typed_data';

/// Entité représentant la structure d'un fichier chiffré selon le format conteneur `.enc`.
class EncryptedFile {
  /// Nom initial du fichier avant chiffrement (ex: "document.pdf").
  final String originalFileName;

  /// Sel cryptographique pour KDF PBKDF2 (32 octets).
  final Uint8List salt;

  /// Nonce / Vecteur d'initialisation pour AES-GCM (12 octets).
  final Uint8List nonce;

  /// Données chiffrées (payload AES-GCM).
  final Uint8List ciphertext;

  /// Tag d'authentification MAC (16 octets).
  final Uint8List authTag;

  /// Taille en octets du payload chiffré.
  int get ciphertextSize => ciphertext.length;

  const EncryptedFile({
    required this.originalFileName,
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.authTag,
  });

  @override
  String toString() =>
      'EncryptedFile(name: $originalFileName, ciphertextSize: $ciphertextSize)';
}
