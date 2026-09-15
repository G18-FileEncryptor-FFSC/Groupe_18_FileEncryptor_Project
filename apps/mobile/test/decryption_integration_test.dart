import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:mobile/services/decryption_service.dart';

void main() {
  test('DecryptionService restores an encrypted file', () async {
    final tempDir = await Directory.systemTemp.createTemp('decrypt_test_');
    addTearDown(() => tempDir.delete(recursive: true));

    final originalPath = '${tempDir.path}${Platform.pathSeparator}test.txt';
    final encryptedPath = '$originalPath.enc';
    const content = 'Contenu à restaurer';
    final cryptoRepository = CryptoRepositoryImpl();
    final fileRepository = FileRepositoryImpl();

    await File(originalPath).writeAsString(content);
    final encryptionResult = await EncryptFileUseCase(
      cryptoRepository: cryptoRepository,
      fileRepository: fileRepository,
    )(
      inputPath: originalPath,
      outputPath: encryptedPath,
      password: 'MotDePasseFort123!',
    );
    expect(encryptionResult.isSuccess, isTrue);

    final service = DecryptionService(
      decryptFileUseCase: DecryptFileUseCase(
        cryptoRepository: cryptoRepository,
        fileRepository: fileRepository,
      ),
    );
    final state = await service.decrypt(
      inputPath: encryptedPath,
      password: 'MotDePasseFort123!',
      outputDirectory: '${tempDir.path}${Platform.pathSeparator}restored${Platform.pathSeparator}',
    );

    expect(state.isSuccess, isTrue);
    expect(state.outputPath, isNotNull);
    expect(await File(state.outputPath!).readAsString(), content);
  });
}
