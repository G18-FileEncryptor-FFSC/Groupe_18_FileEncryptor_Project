import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/encryption_service.dart';

void main() {
  test('Test de bout en bout du chiffrement d\'un vrai fichier', () async {
    final tempDir = await Directory.systemTemp.createTemp('encrypt_real_');
    final sourceFile = File('${tempDir.path}/test_secret.txt');
    await sourceFile.writeAsString('FileEncryptor 2026 - Test de validation chiffrement mobile !');

    final service = EncryptionService();
    double lastProgress = 0.0;

    final result = await service.encrypt(
      filePath: sourceFile.path,
      password: 'MonMotDePasseFort#2026',
      onProgress: (p) => lastProgress = p,
    );

    expect(result.isSuccess, isTrue);
    expect(lastProgress, 1.0);

    final encryptedFile = File(result.outputPath);
    expect(await encryptedFile.exists(), isTrue);

    final bytes = await encryptedFile.readAsBytes();
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    expect(header, 'FENC');

    print('\n[SUCCÈS] Fichier chiffré généré : ${result.outputPath}');
    print('[SUCCÈS] Taille : ${result.fileSizeBytes} octets, Durée : ${result.duration.inMilliseconds} ms\n');

    await tempDir.delete(recursive: true);
  });
}