import '../entities/history_item.dart';

/// Contrat d'interface pour la persistance de l'historique.
abstract class HistoryRepository {
  /// Récupère la liste des opérations triée par date décroissante.
  Future<List<HistoryItem>> getHistory();

  /// Ajoute une entrée dans l'historique.
  Future<void> saveHistoryItem(HistoryItem item);

  /// Efface la totalité de l'historique.
  Future<void> clearHistory();
}
