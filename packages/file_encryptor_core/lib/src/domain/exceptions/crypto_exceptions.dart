/// Exceptions spécifiques au package FileEncryptor.
sealed class FileEncryptorException implements Exception {
  final String message;
  final Object? cause;

  const FileEncryptorException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause != null ? " (Cause: $cause)" : ""}';
}

/// Déclenchée lorsque le mot de passe fourni est incorrect ou que le tag d'authentification GCM ne correspond pas.
class InvalidPasswordException extends FileEncryptorException {
  const InvalidPasswordException([
    super.message = 'Mot de passe incorrect ou données corrompues.',
    super.cause,
  ]);
}

/// Déclenchée lorsque le fichier d'entrée est introuvable.
class FileNotFoundException extends FileEncryptorException {
  final String path;

  const FileNotFoundException(
    this.path, [
    super.message = 'Le fichier spécifié est introuvable.',
    super.cause,
  ]);

  @override
  String toString() => '$runtimeType: $message [Path: $path]';
}

/// Déclenchée lorsque le conteneur chiffré est invalide ou tronqué.
class CorruptedFileException extends FileEncryptorException {
  const CorruptedFileException([
    super.message = 'Le fichier est altéré, incomplet ou corrompu.',
    super.cause,
  ]);
}

/// Déclenchée lorsque les magic bytes ne correspondent pas à 'FENC' ou la version n'est pas supportée.
class InvalidHeaderException extends CorruptedFileException {
  const InvalidHeaderException([
    super.message = "En-tête de conteneur invalide : format '.enc' non reconnu ou version incompatible.",
    super.cause,
  ]);
}

/// Déclenchée en cas d'erreur de stockage ou de persistance de l'historique.
class StorageException extends FileEncryptorException {
  const StorageException(super.message, [super.cause]);
}
