import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';

import '../state/decryption_state.dart';

class DecryptionService {
  DecryptionService({required DecryptFileUseCase decryptFileUseCase})
      : _decryptFileUseCase = decryptFileUseCase;

  final DecryptFileUseCase _decryptFileUseCase;

  Future<DecryptionState> decrypt({
    required String inputPath,
    required String password,
    String? outputDirectoryOrPath,
  }) async {
    if (!await File(inputPath).exists()) {
      return const DecryptionState(
        status: DecryptionStatus.error,
        errorMessage: 'Fichier introuvable.',
      );
    }

    final result = await _decryptFileUseCase(
      inputPath: inputPath,
      password: password,
      outputDirectoryOrPath: outputDirectoryOrPath,
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
  }
}
