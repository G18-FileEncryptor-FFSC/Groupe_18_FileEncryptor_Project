enum DecryptionStatus { initial, loading, success, failure }

class DecryptionState {
  final DecryptionStatus status;
  final String? selectedFilePath;
  final String? outputFilePath;
  final String? errorMessage;
  final double progress;

  const DecryptionState({
    this.status = DecryptionStatus.initial,
    this.selectedFilePath,
    this.outputFilePath,
    this.errorMessage,
    this.progress = 0.0,
  });

  DecryptionState copyWith({
    DecryptionStatus? status,
    String? selectedFilePath,
    String? outputFilePath,
    String? errorMessage,
    double? progress,
  }) {
    return DecryptionState(
      status: status ?? this.status,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      outputFilePath: outputFilePath ?? this.outputFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}
