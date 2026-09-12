import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../entities/encrypted_file.dart';
import '../entities/encryption_result.dart';
import '../entities/history_item.dart';
import '../entities/processing_progress.dart';
import '../exceptions/crypto_exceptions.dart';
import '../repositories/crypto_repository.dart';
import '../repositories/file_repository.dart';
import '../repositories/history_repository.dart';

/// Cas d'utilisation : Orchestre le chiffrement d'un fichier en conteneur `.enc`.
class EncryptFileUseCase {
  final CryptoRepository cryptoRepository;
  final FileRepository fileRepository;
  final HistoryRepository? historyRepository;
  final Uuid uuid;

  EncryptFileUseCase({
    required this.cryptoRepository,
    required this.fileRepository,
    this.historyRepository,
    this.uuid = const Uuid(),
  });

  /// Exécute le chiffrement du fichier.
  ///
  /// [inputPath] : Chemin vers le fichier source à chiffrer.
  /// [outputPath] : Chemin vers le fichier `.enc` cible (par défaut : `inputPath.enc`).
  /// [password] : Mot de passe utilisé pour la dérivation de clé.
  /// [onProgress] : Callback optionnel pour suivre l'état d'avancement.
  /// [rethrowOnError] : Si vrai, relance l'exception après l'avoir consignée dans l'historique.
  Future<EncryptionResult> call({
    required String inputPath,
    String? outputPath,
    required String password,
    void Function(ProcessingProgress progress)? onProgress,
    bool rethrowOnError = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final targetOutputPath = outputPath ?? '$inputPath.enc';
    final originalFileName = p.basename(inputPath);
    int originalFileSize = 0;

    try {
      // 1. Vérification d'existence
      if (!await fileRepository.fileExists(inputPath)) {
        throw FileNotFoundException(inputPath);
      }

      originalFileSize = await fileRepository.getFileSize(inputPath);

      onProgress?.call(ProcessingProgress(
        percentage: 0.1,
        processedBytes: 0,
        totalBytes: originalFileSize,
        phase: 'Lecture du fichier source...',
      ));

      // 2. Lecture du fichier
      final clearBytes = await fileRepository.readFileBytes(inputPath);

      onProgress?.call(ProcessingProgress(
        percentage: 0.25,
        processedBytes: clearBytes.length,
        totalBytes: originalFileSize,
        phase: 'Génération des paramètres cryptographiques...',
      ));

      // 3. Génération du sel (32 octets) et du nonce (12 octets)
      final salt = cryptoRepository.generateSalt(32);
      final nonce = cryptoRepository.generateNonce(12);

      onProgress?.call(ProcessingProgress(
        percentage: 0.4,
        processedBytes: clearBytes.length,
        totalBytes: originalFileSize,
        phase: 'Dérivation de la clé de chiffrement (PBKDF2)...',
      ));

      // 4. Dérivation de clé PBKDF2 (100 000 itérations)
      final key = await cryptoRepository.deriveKey(
        password: password,
        salt: salt,
      );

      // Calcul des données associées (en-tête conteneur)
      final headerBytes = fileRepository.computeHeaderBytes(
        originalFileName: originalFileName,
        salt: salt,
        nonce: nonce,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 0.6,
        processedBytes: clearBytes.length,
        totalBytes: originalFileSize,
        phase: 'Chiffrement des données (AES-256-GCM)...',
      ));

      // 5. Chiffrement AES-GCM avec AAD
      final encryptedPayload = await cryptoRepository.encryptBytes(
        clearBytes: clearBytes,
        key: key,
        nonce: nonce,
        aad: headerBytes,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 0.85,
        processedBytes: clearBytes.length,
        totalBytes: originalFileSize,
        phase: 'Écriture du conteneur chiffré...',
      ));

      // 6. Écriture du conteneur binaire
      final encryptedFile = EncryptedFile(
        originalFileName: originalFileName,
        salt: salt,
        nonce: nonce,
        ciphertext: encryptedPayload.ciphertext,
        authTag: encryptedPayload.authTag,
      );

      await fileRepository.writeEncryptedContainer(targetOutputPath, encryptedFile);

      stopwatch.stop();

      final result = EncryptionResult.success(
        outputPath: targetOutputPath,
        originalFileName: originalFileName,
        fileSizeBytes: await fileRepository.getFileSize(targetOutputPath),
        duration: stopwatch.elapsed,
      );

      // 7. Enregistrement dans l'historique
      await _recordHistory(
        operation: CryptoOperationType.encrypt,
        fileName: originalFileName,
        sourcePath: inputPath,
        destinationPath: targetOutputPath,
        fileSizeBytes: result.fileSizeBytes,
        isSuccess: true,
      );

      onProgress?.call(ProcessingProgress(
        percentage: 1.0,
        processedBytes: originalFileSize,
        totalBytes: originalFileSize,
        phase: 'Chiffrement terminé avec succès.',
      ));

      return result;
    } catch (e) {
      stopwatch.stop();

      await _recordHistory(
        operation: CryptoOperationType.encrypt,
        fileName: originalFileName,
        sourcePath: inputPath,
        destinationPath: targetOutputPath,
        fileSizeBytes: originalFileSize,
        isSuccess: false,
        errorMessage: e.toString(),
      );

      if (rethrowOnError) {
        rethrow;
      }

      return EncryptionResult.failure(
        outputPath: targetOutputPath,
        originalFileName: originalFileName,
        fileSizeBytes: originalFileSize,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    }
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
      final historyItem = HistoryItem(
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
      await historyRepository!.saveHistoryItem(historyItem);
    } catch (_) {
      // Les erreurs d'historique ne doivent pas bloquer l'opération principale
    }
  }
}
