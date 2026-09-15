enum DecryptionStatus { initial, loading, success, error }

class DecryptionState {
  const DecryptionState({
    this.status = DecryptionStatus.initial,
    this.selectedFilePath,
    this.fileName,
    this.fileSizeBytes,
    this.password = '',
    this.outputPath,
    this.errorMessage,
  });

  final DecryptionStatus status;
  final String? selectedFilePath;
  final String? fileName;
  final int? fileSizeBytes;
  final String password;
  final String? outputPath;
  final String? errorMessage;

  bool get isLoading => status == DecryptionStatus.loading;
  bool get isSuccess => status == DecryptionStatus.success;
  bool get isError => status == DecryptionStatus.error;

  DecryptionState copyWith({
    DecryptionStatus? status,
    String? selectedFilePath,
    String? fileName,
    int? fileSizeBytes,
    String? password,
    String? outputPath,
    String? errorMessage,
  }) =>
      DecryptionState(
        status: status ?? this.status,
        selectedFilePath: selectedFilePath ?? this.selectedFilePath,
        fileName: fileName ?? this.fileName,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        password: password ?? this.password,
        outputPath: outputPath ?? this.outputPath,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
