/// Service de sélection de fichiers natifs sur mobile.
abstract class FilePickerService {
  Future<String?> pickFile();
}
