/// Entité représentant la progression d'une opération cryptographique.
class ProcessingProgress {
  /// Pourcentage d'avancement normalisé entre 0.0 et 1.0.
  final double percentage;

  /// Nombre d'octets traités.
  final int processedBytes;

  /// Nombre total d'octets prévus.
  final int totalBytes;

  /// Description de l'étape courante (ex: "Dérivation de clé...", "Chiffrement...", "Écriture...").
  final String phase;

  const ProcessingProgress({
    required this.percentage,
    required this.processedBytes,
    required this.totalBytes,
    required this.phase,
  });

  @override
  String toString() =>
      'ProcessingProgress(${(percentage * 100).toStringAsFixed(1)}% - $phase - $processedBytes/$totalBytes)';
}
