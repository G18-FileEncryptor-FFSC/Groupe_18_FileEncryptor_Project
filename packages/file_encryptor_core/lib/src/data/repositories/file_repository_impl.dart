import 'dart:typed_data';

import '../../domain/entities/encrypted_file.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/io/local_file_service.dart';

/// Implémentation concrète de [FileRepository] s'appuyant sur [LocalFileService].
class FileRepositoryImpl implements FileRepository {
  final LocalFileService _fileService;

  FileRepositoryImpl({LocalFileService? fileService})
      : _fileService = fileService ?? LocalFileService();

  @override
  Future<bool> fileExists(String path) {
    return _fileService.fileExists(path);
  }

  @override
  Future<int> getFileSize(String path) {
    return _fileService.getFileSize(path);
  }

  @override
  Future<Uint8List> readFileBytes(String path) {
    return _fileService.readFileBytes(path);
  }

  @override
  Future<void> writeFileBytes(String path, List<int> bytes) {
    return _fileService.writeFileBytes(path, bytes);
  }

  @override
  Future<void> writeEncryptedContainer(String outputPath, EncryptedFile encryptedFile) {
    return _fileService.writeEncryptedContainer(outputPath, encryptedFile);
  }

  @override
  Future<EncryptedFile> readEncryptedContainer(String inputPath) {
    return _fileService.readEncryptedContainer(inputPath);
  }

  @override
  Uint8List computeHeaderBytes({
    required String originalFileName,
    required List<int> salt,
    required List<int> nonce,
  }) {
    return _fileService.computeHeaderBytes(
      originalFileName: originalFileName,
      salt: salt,
      nonce: nonce,
    );
  }
}
