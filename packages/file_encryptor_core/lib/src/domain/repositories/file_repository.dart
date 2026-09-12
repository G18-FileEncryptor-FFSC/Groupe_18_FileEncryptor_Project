import 'dart:typed_data';
import '../entities/encrypted_file.dart';

/// Contrat d'interface pour les opérations d'entrées/sorties sur les fichiers et conteneurs `.enc`.
abstract class FileRepository {
  /// Vérifie si un fichier existe au chemin donné.
  Future<bool> fileExists(String path);

  /// Récupère la taille d'un fichier en octets.
  Future<int> getFileSize(String path);

  /// Lit l'intégralité du contenu d'un fichier sous forme de tableau d'octets.
  Future<Uint8List> readFileBytes(String path);

  /// Écrit un tableau d'octets dans un fichier.
  Future<void> writeFileBytes(String path, List<int> bytes);

  /// Écrit un fichier conteneur chiffré `.enc` selon la spécification binaire (Magic, Version, Salt, Nonce, Filename, Ciphertext, Tag).
  Future<void> writeEncryptedContainer(String outputPath, EncryptedFile encryptedFile);

  /// Lit et désérialise un fichier conteneur `.enc`.
  /// Lève [InvalidHeaderException] ou [CorruptedFileException] si le format est invalide.
  Future<EncryptedFile> readEncryptedContainer(String inputPath);

  /// Calcule et retourne les octets d'en-tête du conteneur (utilisés comme AAD pour l'intégrité AEAD).
  Uint8List computeHeaderBytes({
    required String originalFileName,
    required List<int> salt,
    required List<int> nonce,
  });
}
