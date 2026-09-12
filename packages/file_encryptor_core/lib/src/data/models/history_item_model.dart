import '../../domain/entities/history_item.dart';

/// Modèle pour la sérialisation et la désérialisation d'un [HistoryItem].
class HistoryItemModel {
  final String id;
  final String operation;
  final String fileName;
  final String sourcePath;
  final String destinationPath;
  final String timestamp;
  final int fileSizeBytes;
  final bool isSuccess;
  final String? errorMessage;

  const HistoryItemModel({
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

  factory HistoryItemModel.fromEntity(HistoryItem entity) {
    return HistoryItemModel(
      id: entity.id,
      operation: entity.operation.name,
      fileName: entity.fileName,
      sourcePath: entity.sourcePath,
      destinationPath: entity.destinationPath,
      timestamp: entity.timestamp.toIso8601String(),
      fileSizeBytes: entity.fileSizeBytes,
      isSuccess: entity.isSuccess,
      errorMessage: entity.errorMessage,
    );
  }

  HistoryItem toEntity() {
    return HistoryItem(
      id: id,
      operation: operation == CryptoOperationType.decrypt.name
          ? CryptoOperationType.decrypt
          : CryptoOperationType.encrypt,
      fileName: fileName,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
      fileSizeBytes: fileSizeBytes,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) {
    return HistoryItemModel(
      id: json['id'] as String? ?? '',
      operation: json['operation'] as String? ?? CryptoOperationType.encrypt.name,
      fileName: json['fileName'] as String? ?? '',
      sourcePath: json['sourcePath'] as String? ?? '',
      destinationPath: json['destinationPath'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      isSuccess: json['isSuccess'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'fileName': fileName,
      'sourcePath': sourcePath,
      'destinationPath': destinationPath,
      'timestamp': timestamp,
      'fileSizeBytes': fileSizeBytes,
      'isSuccess': isSuccess,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}
