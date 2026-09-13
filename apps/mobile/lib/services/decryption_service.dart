import 'package:file_encryptor_core/file_encryptor_core.dart';

class DecryptionService {
  final DecryptFileUseCase _decryptUseCase;

  DecryptionService({DecryptFileUseCase? decryptUseCase})
    : _decryptUseCase =
          decryptUseCase ??
          DecryptFileUseCase(
            cryptoRepository: CryptoRepositoryImpl(),
            fileRepository: FileRepositoryImpl(),
            historyRepository: HistoryRepositoryImpl(),
          );

  Future<EncryptionResult> decrypt({
    required String filePath,
    required String password,
    required void Function(double progress) onProgress,
  }) async {
    return await _decryptUseCase(
      inputPath: filePath,
      password: password,
      onProgress: (progressData) {
        onProgress(progressData.percentage);
      },
    );
  }
}
