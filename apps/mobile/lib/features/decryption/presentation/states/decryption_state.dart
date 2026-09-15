enum DecryptionStatus { idle, loading, success, error }

class DecryptionState {
  final int currentStep;
  final String? inputPath;
  final String? fileName;
  final int? encryptedFileSizeBytes;
  final String password;
  final String? outputPath;
  final int? outputFileSizeBytes;
  final DecryptionStatus status;
  final String? errorMessage;

  const DecryptionState({
    this.currentStep = 0,
    this.inputPath,
    this.fileName,
    this.encryptedFileSizeBytes,
    this.password = '',
    this.outputPath,
    this.outputFileSizeBytes,
    this.status = DecryptionStatus.idle,
    this.errorMessage,
  });

  bool get hasSelectedFile => inputPath != null && inputPath!.isNotEmpty;

  bool get hasPassword => password.trim().isNotEmpty;

  bool get canGoToPasswordStep => hasSelectedFile;

  bool get canGoToSummaryStep => hasSelectedFile && hasPassword;

  bool get isLoading => status == DecryptionStatus.loading;

  bool get isSuccess => status == DecryptionStatus.success;

  bool get hasError => status == DecryptionStatus.error;

  DecryptionState copyWith({
    int? currentStep,
    String? inputPath,
    String? fileName,
    int? encryptedFileSizeBytes,
    String? password,
    String? outputPath,
    int? outputFileSizeBytes,
    DecryptionStatus? status,
    String? errorMessage,
    bool clearOutputPath = false,
    bool clearOutputFileSize = false,
    bool clearErrorMessage = false,
  }) {
    return DecryptionState(
      currentStep: currentStep ?? this.currentStep,
      inputPath: inputPath ?? this.inputPath,
      fileName: fileName ?? this.fileName,
      encryptedFileSizeBytes:
          encryptedFileSizeBytes ?? this.encryptedFileSizeBytes,
      password: password ?? this.password,
      outputPath: clearOutputPath ? null : outputPath ?? this.outputPath,
      outputFileSizeBytes: clearOutputFileSize
          ? null
          : outputFileSizeBytes ?? this.outputFileSizeBytes,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
