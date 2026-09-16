import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../states/decryption_state.dart';

/// Gère l'état du parcours de déchiffrement sans dépendre de l'interface.
class DecryptionController extends ChangeNotifier {
  DecryptionController({
    DecryptFileUseCase? decryptFileUseCase,
  })  : _decryptFileUseCase = decryptFileUseCase ??
            DecryptFileUseCase(
              cryptoRepository: CryptoRepositoryImpl(),
              fileRepository: FileRepositoryImpl(),
              historyRepository: HistoryRepositoryImpl(),
            );

  final DecryptFileUseCase _decryptFileUseCase;
  DecryptionState _state = const DecryptionState();

  DecryptionState get state => _state;

  Future<void> pickEncryptedFile() async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.any,
    );
    if (result.isEmpty) return;
    final file = result.first;
    final path = file.path;
    if (path == null || path.isEmpty) return;

    try {
      final size = await File(path).length();
      _state = _state.copyWith(
        currentStep: 0,
        inputPath: path,
        fileName: file.name,
        encryptedFileSizeBytes: size,
        status: DecryptionStatus.idle,
        clearOutputPath: true,
        clearOutputFileSize: true,
        clearErrorMessage: true,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(
        status: DecryptionStatus.error,
        errorMessage: 'Impossible de lire le fichier : ${error.message}',
      );
    }
    notifyListeners();
  }

  void updatePassword(String password) {
    if (password == _state.password) return;
    _state = _state.copyWith(password: password, clearErrorMessage: true);
    notifyListeners();
  }

  void nextStep() {
    if (_state.currentStep == 0 && !_state.canGoToPasswordStep) return;
    if (_state.currentStep == 1 && !_state.canGoToSummaryStep) return;
    if (_state.currentStep >= 2) return;
    _state = _state.copyWith(currentStep: _state.currentStep + 1);
    notifyListeners();
  }

  void previousStep() {
    if (_state.currentStep == 0 || _state.isLoading) return;
    _state = _state.copyWith(currentStep: _state.currentStep - 1);
    notifyListeners();
  }

  Future<void> decrypt({String? outputDirectoryOrPath}) async {
    if (!_state.canGoToSummaryStep || _state.isLoading) return;

    _state = _state.copyWith(
      status: DecryptionStatus.loading,
      clearErrorMessage: true,
    );
    notifyListeners();

    final result = await _decryptFileUseCase(
      inputPath: _state.inputPath!,
      password: _state.password,
      outputDirectoryOrPath: outputDirectoryOrPath,
    );
    _state = _state.copyWith(
      status: result.isSuccess
          ? DecryptionStatus.success
          : DecryptionStatus.error,
      outputPath: result.outputPath.isEmpty ? null : result.outputPath,
      outputFileSizeBytes: result.fileSizeBytes,
      errorMessage: result.errorMessage,
    );
    notifyListeners();
  }

  void reset() {
    _state = const DecryptionState();
    notifyListeners();
  }
}
