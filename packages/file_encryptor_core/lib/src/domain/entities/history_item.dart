/// Type d'opération cryptographique.
enum CryptoOperationType {
  encrypt,
  decrypt,
}

/// Entité représentant une entrée dans l'historique des opérations de chiffrement/déchiffrement.
class HistoryItem {
  /// Identifiant unique (UUID).
  final String id;

  /// Type de l'opération effectuée.
  final CryptoOperationType operation;

  /// Nom du fichier concerné.
  final String fileName;

  /// Chemin du fichier source.
  final String sourcePath;

  /// Chemin du fichier cible (produit ou attendu).
  final String destinationPath;

  /// Horodatage de l'opération.
  final DateTime timestamp;

  /// Taille en octets du fichier.
  final int fileSizeBytes;

  /// Statut de l'opération (vrai si réussie, faux sinon).
  final bool isSuccess;

  /// Message d'erreur éventuel.
  final String? errorMessage;

  const HistoryItem({
    required this.id,
    required this.operation,
    required this.fileName,
    required this.sourcePath,
    required this.destinationPath,
    required this.timestamp,
    required this.fileSizeBytes,
    required this.isSuccess,
    this.errorMessage,
  });

  @override
  String toString() =>
      'HistoryItem(id: $id, op: ${operation.name}, file: $fileName, success: $isSuccess)';
}
