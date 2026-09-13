enum DecryptionStatus { idle, loading, success, error }

class DecryptionState {
  final DecryptionStatus status;
  final String? selectedFilePath;
  final double progress;
  final String? outputPath;
  final String? errorMessage;

  const DecryptionState({
    this.status = DecryptionStatus.idle,
    this.selectedFilePath,
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
  });

  DecryptionState copyWith({
    DecryptionStatus? status,
    String? selectedFilePath,
    double? progress,
    String? outputPath,
    String? errorMessage,
  }) {
    return DecryptionState(
      status: status ?? this.status,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
