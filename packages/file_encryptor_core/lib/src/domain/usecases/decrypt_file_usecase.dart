import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../entities/encryption_result.dart';
import '../entities/history_item.dart';
import '../entities/processing_progress.dart';
import '../exceptions/crypto_exceptions.dart';
import '../repositories/crypto_repository.dart';
import '../repositories/file_repository.dart';
import '../repositories/history_repository.dart';

/// Cas d'utilisation : Orchestre le déchiffrement d'un conteneur `.enc` et restaure le fichier original.
class DecryptFileUseCase {
  final CryptoRepository cryptoRepository;
  final FileRepository fileRepository;
  final HistoryRepository? historyRepository;
  final Uuid uuid;

  DecryptFileUseCase({
    required this.cryptoRepository,
    required this.fileRepository,
    this.historyRepository,
    this.uuid = const Uuid(),
  });

  /// Exécute le déchiffrement du conteneur.
  ///
  /// [inputPath] : Chemin vers le fichier `.enc`.
  /// [outputDirectoryOrPath] : Dossier de destination ou chemin précis de sortie.
  /// [password] : Mot de passe fourni par l'utilisateur.
  /// [onProgress] : Callback de progression.
  /// [rethrowOnError] : Relance l'exception si vrai.
  Future<EncryptionResult> call({
    required String inputPath,
    String? outputDirectoryOrPath,
    required String password,
    void Function(ProcessingProgress progress)? onProgress,
    bool rethrowOnError = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? originalFileName;
    String targetOutputPath = '';
    int encryptedFileSize = 0;

    try {
      // 1. Vérification d'existence
      if (!await fileRepository.fileExists(inputPath)) {
        throw FileNotFoundException(inputPath);
      }

      encryptedFileSize = await fileRepository.getFileSize(inputPath);

      onProgress?.call(ProcessingProgress(
        percentage: 0.15,
        processedBytes: 0,
        totalBytes: encryptedFileSize,
        phase: 'Lecture et vérification du conteneur .enc...',
      ));

      // 2. Lecture et désérialisation du conteneur (vérifie Magic Bytes, Version, Longueur)
      final encryptedFile = await fileRepository.readEncryptedContainer(inputPath);
      originalFileName = encryptedFile.originalFileName;

      // Détermination du chemin de sortie
      targetOutputPath = _resolveOutputPath(
        inputPath: inputPath,
        originalFileName: originalFileName,
        outputDirectoryOrPath: outputDirectoryOrPath,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 0.35,
        processedBytes: encryptedFile.ciphertext.length,
        totalBytes: encryptedFileSize,
        phase: 'Dérivation de la clé (PBKDF2)...',
      ));

      // 3. Dérivation de clé avec le sel extrait du conteneur
      final key = await cryptoRepository.deriveKey(
        password: password,
        salt: encryptedFile.salt,
      );

      // Calcul des données associées AAD
      final headerBytes = fileRepository.computeHeaderBytes(
        originalFileName: encryptedFile.originalFileName,
        salt: encryptedFile.salt,
        nonce: encryptedFile.nonce,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 0.65,
        processedBytes: encryptedFile.ciphertext.length,
        totalBytes: encryptedFileSize,
        phase: 'Déchiffrement et vérification de l\'intégrité (AES-GCM)...',
      ));

      // 4. Déchiffrement et vérification du tag d'authentification MAC
      final clearBytes = await cryptoRepository.decryptBytes(
        ciphertext: encryptedFile.ciphertext,
        authTag: encryptedFile.authTag,
        key: key,
        nonce: encryptedFile.nonce,
        aad: headerBytes,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 0.9,
        processedBytes: clearBytes.length,
        totalBytes: clearBytes.length,
        phase: 'Restauration du fichier sur le disque...',
      ));

      // 5. Écriture du fichier restauré
      await fileRepository.writeFileBytes(targetOutputPath, clearBytes);

      stopwatch.stop();

      final result = EncryptionResult.success(
        outputPath: targetOutputPath,
        originalFileName: originalFileName,
        fileSizeBytes: clearBytes.length,
        duration: stopwatch.elapsed,
      );

      // 6. Enregistrement dans l'historique
      await _recordHistory(
        operation: CryptoOperationType.decrypt,
        fileName: originalFileName,
        sourcePath: inputPath,
        destinationPath: targetOutputPath,
        fileSizeBytes: clearBytes.length,
        isSuccess: true,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 1.0,
        processedBytes: clearBytes.length,
        totalBytes: clearBytes.length,
        phase: 'Déchiffrement terminé avec succès.',
      ));

      return result;
    } catch (e) {
      stopwatch.stop();

      await _recordHistory(
        operation: CryptoOperationType.decrypt,
        fileName: originalFileName ?? p.basename(inputPath),
        sourcePath: inputPath,
        destinationPath: targetOutputPath.isNotEmpty ? targetOutputPath : inputPath,
        fileSizeBytes: encryptedFileSize,
        isSuccess: false,
        errorMessage: e.toString(),
      );

      if (rethrowOnError) {
        rethrow;
      }

      return EncryptionResult.failure(
        outputPath: targetOutputPath,
        originalFileName: originalFileName,
        fileSizeBytes: encryptedFileSize,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    }
  }

  String _resolveOutputPath({
    required String inputPath,
    required String originalFileName,
    String? outputDirectoryOrPath,
  }) {
    if (outputDirectoryOrPath == null || outputDirectoryOrPath.isEmpty) {
      final dir = p.dirname(inputPath);
      final candidateName = originalFileName.isNotEmpty
          ? originalFileName
          : (inputPath.endsWith('.enc')
              ? p.basename(inputPath.substring(0, inputPath.length - 4))
              : '${p.basename(inputPath)}.dec');
      return p.join(dir, candidateName);
    }

    final entityType = FileSystemEntity.typeSync(outputDirectoryOrPath);
    if (entityType == FileSystemEntityType.directory ||
        outputDirectoryOrPath.endsWith(p.separator) ||
        outputDirectoryOrPath.endsWith('/')) {
      final name = originalFileName.isNotEmpty ? originalFileName : 'decrypted_file';
      return p.join(outputDirectoryOrPath, name);
    }

    return outputDirectoryOrPath;
  }

  Future<void> _recordHistory({
    required CryptoOperationType operation,
    required String fileName,
    required String sourcePath,
    required String destinationPath,
    required int fileSizeBytes,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    if (historyRepository == null) return;
    try {
      final item = HistoryItem(
        id: uuid.v4(),
        operation: operation,
        fileName: fileName,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        timestamp: DateTime.now(),
        fileSizeBytes: fileSizeBytes,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
      );
      await historyRepository!.saveHistoryItem(item);
    } catch (_) {
      // Ignorer les erreurs d'historique pour ne pas altérer le flux principal
    }
  }
}
