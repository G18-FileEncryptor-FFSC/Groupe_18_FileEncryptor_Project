enum EncryptionStatus { initial, loading, success, error }

/// État de la page de chiffrement.
class EncryptionState {
  final EncryptionStatus status;
  final String? selectedFilePath;
  final double progress;
  final String statusMessage;
  final String? errorMessage;
  final String? resultPath;

  const EncryptionState({
    required this.status,
    this.selectedFilePath,
    this.progress = 0.0,
    this.statusMessage = '',
    this.errorMessage,
    this.resultPath,
  });

  factory EncryptionState.initial() => const EncryptionState(
        status: EncryptionStatus.initial,
      );

  EncryptionState copyWith({
    EncryptionStatus? status,
    String? selectedFilePath,
    double? progress,
    String? statusMessage,
    String? errorMessage,
    String? resultPath,
  }) {
    return EncryptionState(
      status: status ?? this.status,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      resultPath: resultPath ?? this.resultPath,
    );
  }
}
