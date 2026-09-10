import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

/// Cas d'utilisation : Récupérer l'historique complet des opérations.
class GetHistoryUseCase {
  final HistoryRepository repository;

  GetHistoryUseCase({required this.repository});

  /// Retourne la liste des opérations d'historique.
  Future<List<HistoryItem>> call() {
    return repository.getHistory();
  }
}
