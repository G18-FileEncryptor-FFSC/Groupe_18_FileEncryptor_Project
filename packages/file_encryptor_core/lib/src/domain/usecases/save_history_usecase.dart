import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

/// Cas d'utilisation : Sauvegarder ou nettoyer les entrées d'historique.
class SaveHistoryUseCase {
  final HistoryRepository repository;

  SaveHistoryUseCase({required this.repository});

  /// Ajoute une entrée dans l'historique.
  Future<void> call(HistoryItem item) {
    return repository.saveHistoryItem(item);
  }

  /// Réinitialise l'ensemble de l'historique.
  Future<void> clear() {
    return repository.clearHistory();
  }
}
