import 'package:flutter/material.dart';
import '../states/decryption_state.dart';

class DecryptionController extends ChangeNotifier {
  DecryptionState _state = const DecryptionState();
  DecryptionState get state => _state;

  void selectFile(String filePath) {
    _state = _state.copyWith(
      selectedFilePath: filePath,
      status: DecryptionStatus.initial,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> decryptFile(String password) async {
    if (_state.selectedFilePath == null) {
      _state = _state.copyWith(
        status: DecryptionStatus.failure,
        errorMessage: "Veuillez sélectionner un fichier.",
      );
      notifyListeners();
      return;
    }

    if (password.isEmpty) {
      _state = _state.copyWith(
        status: DecryptionStatus.failure,
        errorMessage: "Veuillez entrer une clé de déchiffrement.",
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(status: DecryptionStatus.loading, progress: 0.0);
    notifyListeners();

    try {
      // MOCK — sera remplacé par le vrai Core
      await Future.delayed(const Duration(seconds: 2));
      _state = _state.copyWith(progress: 0.5);
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      _state = _state.copyWith(
        status: DecryptionStatus.success,
        progress: 1.0,
        outputFilePath: "/storage/fichier_restaure.pdf",
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: DecryptionStatus.failure,
        errorMessage: "Clé incorrecte, vérifiez et réessayez.",
      );
      notifyListeners();
    }
  }

  void reset() {
    _state = const DecryptionState();
    notifyListeners();
  }
}
