import 'package:file_encryptor_core/file_encryptor_core.dart';

/// Builds the application services without duplicating crypto logic in the CLI.
class CoreFactory {
  CoreFactory._();

  static EncryptFileUseCase encryptUseCase() => EncryptFileUseCase(
    cryptoRepository: CryptoRepositoryImpl(),
    fileRepository: FileRepositoryImpl(),
    historyRepository: HistoryRepositoryImpl(),
  );

  static DecryptFileUseCase decryptUseCase() => DecryptFileUseCase(
    cryptoRepository: CryptoRepositoryImpl(),
    fileRepository: FileRepositoryImpl(),
    historyRepository: HistoryRepositoryImpl(),
  );

  static GetHistoryUseCase historyUseCase() =>
      GetHistoryUseCase(repository: HistoryRepositoryImpl());
}
