import 'dart:convert';
import 'dart:io';

import '../../../domain/exceptions/crypto_exceptions.dart';
import '../../models/history_item_model.dart';

/// Source de données locale pour persister l'historique des opérations au format JSON.
class HistoryLocalDataSource {
  /// Chemin du fichier JSON de stockage.
  final String storageFilePath;

  HistoryLocalDataSource({
    String? customStoragePath,
  }) : storageFilePath = customStoragePath ?? _defaultStoragePath();

  static String _defaultStoragePath() {
    return '.file_encryptor_history.json';
  }

  /// Charge tous les éléments d'historique depuis le fichier local.
  Future<List<HistoryItemModel>> loadHistory() async {
    final file = File(storageFilePath);
    if (!await file.exists()) {
      return [];
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }

      final decoded = json.decode(content);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((map) => HistoryItemModel.fromJson(map))
          .toList();
    } catch (e) {
      throw StorageException('Erreur lors du chargement de l\'historique.', e);
    }
  }

  /// Sauvegarde un nouvel élément en tête de l'historique.
  Future<void> saveHistoryItem(HistoryItemModel item) async {
    try {
      final currentList = await loadHistory();
      // On insère en début de liste
      currentList.insert(0, item);

      await _writeAll(currentList);
    } catch (e) {
      if (e is FileEncryptorException) rethrow;
      throw StorageException('Impossible d\'enregistrer l\'élément dans l\'historique.', e);
    }
  }

  /// Supprime tous les éléments de l'historique.
  Future<void> clearHistory() async {
    try {
      final file = File(storageFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw StorageException('Impossible de supprimer l\'historique.', e);
    }
  }

  /// Écrit la liste complète dans le fichier de manière atomique.
  Future<void> _writeAll(List<HistoryItemModel> items) async {
    final file = File(storageFilePath);
    final tempFile = File('$storageFilePath.tmp');

    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final jsonContent = json.encode(items.map((e) => e.toJson()).toList());

    try {
      await tempFile.writeAsString(jsonContent, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw StorageException('Échec lors de l\'écriture atomique de l\'historique.', e);
    }
  }
}
