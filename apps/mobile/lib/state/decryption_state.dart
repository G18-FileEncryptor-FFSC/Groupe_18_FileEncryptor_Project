enum DecryptionStatus { initial, loading, success, error }

class DecryptionState {
  final DecryptionStatus status;
  final String? selectedFilePath;
  final String? fileName;
  final int? fileSizeBytes;
  final String? outputPath;
  final String? errorMessage;

  const DecryptionState({
    this.status = DecryptionStatus.initial,
    this.selectedFilePath,
    this.fileName,
    this.fileSizeBytes,
    this.outputPath,
    this.errorMessage,
  });

  bool get isInitial => status == DecryptionStatus.initial;
  bool get isLoading => status == DecryptionStatus.loading;
  bool get isSuccess => status == DecryptionStatus.success;
  bool get isError => status == DecryptionStatus.error;

  DecryptionState copyWith({
    DecryptionStatus? status,
    String? selectedFilePath,
    String? fileName,
    int? fileSizeBytes,
    String? outputPath,
    String? errorMessage,
  }) {
    return DecryptionState(
      status: status ?? this.status,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
