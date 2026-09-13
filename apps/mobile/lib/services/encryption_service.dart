import 'package:file_encryptor_core/file_encryptor_core.dart';

class EncryptionService {
  final EncryptFileUseCase _encryptUseCase;

  EncryptionService({EncryptFileUseCase? encryptUseCase})
      : _encryptUseCase = encryptUseCase ??
            EncryptFileUseCase(
              cryptoRepository: CryptoRepositoryImpl(),
              fileRepository: FileRepositoryImpl(),
              historyRepository: HistoryRepositoryImpl(),
            );

  Future<EncryptionResult> encrypt({
    required String filePath,
    required String password,
    required void Function(double progress) onProgress,
  }) async {
    return await _encryptUseCase(
      inputPath: filePath,
      password: password,
      onProgress: (progressData) {
        onProgress(progressData.percentage);
      },
    );
  }
}