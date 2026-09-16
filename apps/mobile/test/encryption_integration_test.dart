import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/encryption_service.dart';

void main() {
  group('EncryptionService Integration Tests', () {
    test('chiffre correctement un fichier réel', () async {
      final tempDir = await Directory.systemTemp.createTemp('encrypt_test_');

      try {
        final sourceFile = File('${tempDir.path}/test_secret.txt');

        const originalContent =
            'FileEncryptor 2026 - Test de chiffrement mobile.';

        await sourceFile.writeAsString(originalContent);

        final service = EncryptionService();

        double lastProgress = 0.0;

        final result = await service.encrypt(
          filePath: sourceFile.path,
          password: 'MonMotDePasseFort#2026',
          onProgress: (progress) {
            lastProgress = progress;
          },
        );

        // Le chiffrement doit réussir.
        expect(result.isSuccess, isTrue);

        // La progression doit atteindre 100 %.
        expect(lastProgress, closeTo(1.0, 0.001));

        // Un fichier de sortie doit être retourné. (modifie)
        expect(result.outputPath, isNotNull);

        final encryptedFile = File(result.outputPath);

        // Le fichier chiffré doit exister.
        expect(await encryptedFile.exists(), isTrue);

        // Le fichier ne doit pas être vide.
        final encryptedBytes = await encryptedFile.readAsBytes();
        expect(encryptedBytes, isNotEmpty);

        // Le fichier doit commencer par le header FENC.
        expect(
          String.fromCharCodes(encryptedBytes.sublist(0, 4)),
          equals('FENC'),
        );

        // Le contenu chiffré doit être différent du fichier original.
        final originalBytes = originalContent.codeUnits;

        expect(
          encryptedBytes,
          isNot(equals(originalBytes)),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('retourne une erreur si le fichier source n existe pas', () async {
      final service = EncryptionService();

      final result = await service.encrypt(
        filePath: '/path/that/does/not/exist/test.txt',
        password: 'MonMotDePasseFort#2026',
        onProgress: (_) {},
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('signale correctement la progression du chiffrement', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('encrypt_progress_');

      try {
        final sourceFile = File('${tempDir.path}/progress_test.txt');

        await sourceFile.writeAsString(
          'Testing encryption progress in FileEncryptor.',
        );

        final service = EncryptionService();

        final progressValues = <double>[];

        final result = await service.encrypt(
          filePath: sourceFile.path,
          password: 'MonMotDePasseFort#2026',
          onProgress: progressValues.add,
        );

        expect(result.isSuccess, isTrue);
        expect(progressValues, isNotEmpty);

        // Toutes les valeurs doivent être entre 0 et 1.
        for (final progress in progressValues) {
          expect(progress, inInclusiveRange(0.0, 1.0));
        }

        // La progression finale doit être de 100 %.
        expect(
          progressValues.last,
          closeTo(1.0, 0.001),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
