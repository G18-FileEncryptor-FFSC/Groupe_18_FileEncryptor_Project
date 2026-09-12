import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/storage/history_local_datasource.dart';
import '../models/history_item_model.dart';

/// Implémentation concrète de [HistoryRepository] s'appuyant sur [HistoryLocalDataSource].
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource _dataSource;

  HistoryRepositoryImpl({HistoryLocalDataSource? dataSource})
      : _dataSource = dataSource ?? HistoryLocalDataSource();

  @override
  Future<List<HistoryItem>> getHistory() async {
    final models = await _dataSource.loadHistory();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveHistoryItem(HistoryItem item) async {
    final model = HistoryItemModel.fromEntity(item);
    await _dataSource.saveHistoryItem(model);
  }

  @override
  Future<void> clearHistory() async {
    await _dataSource.clearHistory();
  }
}
