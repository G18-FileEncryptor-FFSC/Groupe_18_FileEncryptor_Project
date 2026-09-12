/// Résultat d'une opération de chiffrement ou de déchiffrement.
class EncryptionResult {
  /// Indique si l'opération s'est déroulée avec succès.
  final bool isSuccess;

  /// Chemin du fichier produit en sortie.
  final String outputPath;

  /// Nom d'origine du fichier s'il a pu être extrait.
  final String? originalFileName;

  /// Taille en octets du fichier généré.
  final int fileSizeBytes;

  /// Durée nécessaire à l'exécution de l'opération.
  final Duration duration;

  /// Message d'erreur éventuel en cas d'échec.
  final String? errorMessage;

  const EncryptionResult({
    required this.isSuccess,
    required this.outputPath,
    this.originalFileName,
    required this.fileSizeBytes,
    required this.duration,
    this.errorMessage,
  });

  /// Fabrique pour un résultat avec succès.
  factory EncryptionResult.success({
    required String outputPath,
    String? originalFileName,
    required int fileSizeBytes,
    required Duration duration,
  }) {
    return EncryptionResult(
      isSuccess: true,
      outputPath: outputPath,
      originalFileName: originalFileName,
      fileSizeBytes: fileSizeBytes,
      duration: duration,
    );
  }

  /// Fabrique pour un résultat en échec.
  factory EncryptionResult.failure({
    required String outputPath,
    required String errorMessage,
    required Duration duration,
    int fileSizeBytes = 0,
    String? originalFileName,
  }) {
    return EncryptionResult(
      isSuccess: false,
      outputPath: outputPath,
      originalFileName: originalFileName,
      fileSizeBytes: fileSizeBytes,
      duration: duration,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() => isSuccess
      ? 'EncryptionResult.success(output: $outputPath, size: $fileSizeBytes, duration: ${duration.inMilliseconds}ms)'
      : 'EncryptionResult.failure(error: $errorMessage, duration: ${duration.inMilliseconds}ms)';
}
