enum EncryptionStatus { idle, loading, success, error }

class EncryptionState {
  final EncryptionStatus status;
  final String? selectedFilePath;
  final double progress; // 0.0 à 1.0
  final String? outputPath;
  final String? errorMessage;

  const EncryptionState({
    this.status = EncryptionStatus.idle,
    this.selectedFilePath,
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
  });

  EncryptionState copyWith({
    EncryptionStatus? status,
    String? selectedFilePath,
    double? progress,
    String? outputPath,
    String? errorMessage,
  }) {
    return EncryptionState(
      status: status ?? this.status,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}