import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../domain/entities/encrypted_file.dart';
import '../../../domain/exceptions/crypto_exceptions.dart';

/// Service responsable des entrées/sorties et de l'encodage/décodage binaire du format `.enc`.
class LocalFileService {
  /// Magic bytes spécifiés : 'FENC' (0x46454E43).
  static const List<int> magicBytes = [0x46, 0x45, 0x4E, 0x43];

  /// Version du conteneur supportée.
  static const int currentVersion = 0x01;

  /// Taille du sel (32 octets).
  static const int saltLength = 32;

  /// Taille du nonce/IV (12 octets).
  static const int nonceLength = 12;

  /// Taille du tag d'authentification MAC (16 octets).
  static const int authTagLength = 16;

  /// Taille fixe minimale de l'en-tête (Magic(4) + Version(1) + Sel(32) + Nonce(12) + LongueurNom(1) = 50).
  static const int headerPrefixLength = 50;

  /// Vérifie si le fichier existe sur le système de fichiers.
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Retourne la taille en octets d'un fichier.
  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileNotFoundException(path);
    }
    return file.length();
  }

  /// Lit l'intégralité du fichier sous forme de tableau d'octets.
  Future<Uint8List> readFileBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileNotFoundException(path);
    }
    return file.readAsBytes();
  }

  /// Écrit un tableau d'octets dans un fichier, en créant les dossiers parents si nécessaire.
  Future<void> writeFileBytes(String path, List<int> bytes) async {
    final file = File(path);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Calcule l'en-tête binaire pour un fichier (servant aussi d'Associated Authenticated Data - AAD).
  Uint8List computeHeaderBytes({
    required String originalFileName,
    required List<int> salt,
    required List<int> nonce,
  }) {
    if (salt.length != saltLength) {
      throw ArgumentError('Le sel doit faire exactement $saltLength octets.');
    }
    if (nonce.length != nonceLength) {
      throw ArgumentError('Le nonce doit faire exactement $nonceLength octets.');
    }

    final nameBytes = utf8.encode(originalFileName);
    final nameLen = nameBytes.length > 255 ? 255 : nameBytes.length;
    final truncatedNameBytes = nameBytes.sublist(0, nameLen);

    final builder = BytesBuilder(copy: false)
      ..add(magicBytes)
      ..addByte(currentVersion)
      ..add(salt)
      ..add(nonce)
      ..addByte(nameLen)
      ..add(truncatedNameBytes);

    return builder.toBytes();
  }

  /// Sérialise une entité [EncryptedFile] en flux binaire selon la spécification `.enc`.
  Uint8List serializeEncryptedFile(EncryptedFile encryptedFile) {
    if (encryptedFile.authTag.length != authTagLength) {
      throw ArgumentError('Le tag d\'authentification doit faire exactement $authTagLength octets.');
    }

    final header = computeHeaderBytes(
      originalFileName: encryptedFile.originalFileName,
      salt: encryptedFile.salt,
      nonce: encryptedFile.nonce,
    );

    final builder = BytesBuilder(copy: false)
      ..add(header)
      ..add(encryptedFile.ciphertext)
      ..add(encryptedFile.authTag);

    return builder.toBytes();
  }

  /// Désérialise les octets d'un conteneur `.enc` en entité [EncryptedFile].
  EncryptedFile deserializeEncryptedFile(Uint8List bytes) {
    // Taille minimale : HeaderPrefix (50) + Nom (0) + Payload (0) + Tag (16) = 66 octets
    if (bytes.length < headerPrefixLength + authTagLength) {
      throw const CorruptedFileException('Fichier trop court pour constituer un conteneur valide.');
    }

    // 1. Vérification Magic Bytes
    for (var i = 0; i < magicBytes.length; i++) {
      if (bytes[i] != magicBytes[i]) {
        throw const InvalidHeaderException(
          'Format non reconnu : les octets d\'identification ne correspondent pas à "FENC".',
        );
      }
    }

    // 2. Vérification Version
    final version = bytes[4];
    if (version != currentVersion) {
      throw InvalidHeaderException(
        'Version de conteneur non supportée: 0x${version.toRadixString(16).padLeft(2, '0')}.',
      );
    }

    // 3. Sel KDF (32 octets)
    final salt = Uint8List.fromList(bytes.sublist(5, 37));

    // 4. Nonce/IV (12 octets)
    final nonce = Uint8List.fromList(bytes.sublist(37, 49));

    // 5. Longueur du nom
    final nameLength = bytes[49];

    final headerTotalLength = headerPrefixLength + nameLength;
    if (bytes.length < headerTotalLength + authTagLength) {
      throw const CorruptedFileException('Conteneur tronqué : taille inférieure aux en-têtes déclarés.');
    }

    // 6. Nom original
    final nameBytes = bytes.sublist(50, headerTotalLength);
    final originalFileName = utf8.decode(nameBytes, allowMalformed: true);

    // 7. Payload chiffré et 8. Tag d'authentification
    final ciphertextEnd = bytes.length - authTagLength;
    final ciphertext = Uint8List.fromList(bytes.sublist(headerTotalLength, ciphertextEnd));
    final authTag = Uint8List.fromList(bytes.sublist(ciphertextEnd, bytes.length));

    return EncryptedFile(
      originalFileName: originalFileName,
      salt: salt,
      nonce: nonce,
      ciphertext: ciphertext,
      authTag: authTag,
    );
  }

  /// Écrit un conteneur chiffré dans le fichier cible.
  Future<void> writeEncryptedContainer(String outputPath, EncryptedFile encryptedFile) async {
    final serialized = serializeEncryptedFile(encryptedFile);
    await writeFileBytes(outputPath, serialized);
  }

  /// Lit et désérialise un fichier conteneur chiffré.
  Future<EncryptedFile> readEncryptedContainer(String inputPath) async {
    final bytes = await readFileBytes(inputPath);
    return deserializeEncryptedFile(bytes);
  }
}
