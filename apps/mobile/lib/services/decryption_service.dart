import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:mobile/state/decryption_state.dart';

class DecryptionService {
  final DecryptFileUseCase _decryptFileUseCase;

  DecryptionService({DecryptFileUseCase? decryptFileUseCase})
      : _decryptFileUseCase = decryptFileUseCase ??
            DecryptFileUseCase(
              cryptoRepository: CryptoRepositoryImpl(),
              fileRepository: FileRepositoryImpl(),
              historyRepository: HistoryRepositoryImpl(),
            );

  Future<DecryptionState> decrypt({
    required String inputPath,
    required String password,
    String? outputDirectory,
  }) async {
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return const DecryptionState(
          status: DecryptionStatus.error,
          errorMessage: 'Fichier introuvable.',
        );
      }

      final result = await _decryptFileUseCase(
        inputPath: inputPath,
        password: password,
        outputDirectoryOrPath: outputDirectory,
      );

      return DecryptionState(
        status: result.isSuccess
            ? DecryptionStatus.success
            : DecryptionStatus.error,
        selectedFilePath: inputPath,
        fileName: result.originalFileName,
        fileSizeBytes: result.fileSizeBytes,
        outputPath: result.outputPath.isEmpty ? null : result.outputPath,
        errorMessage: result.errorMessage,
      );
    } catch (error) {
      return DecryptionState(
        status: DecryptionStatus.error,
        errorMessage: error.toString(),
      );
    }
  }
}
