import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli/src/commands/decrypt_command.dart';
import 'package:test/test.dart';

void main() {
  group('DecryptCommand Tests', () {
    late CommandRunner<void> runner;

    setUp(() {
      runner = CommandRunner<void>(
        'file_encryptor',
        'CLI FileEncryptor',
      )..addCommand(DecryptCommand());
    });

    test('La commande doit avoir le nom "decrypt"', () {
      final command = DecryptCommand();

      expect(command.name, equals('decrypt'));
    });

    test('La commande doit avoir une description correcte', () {
      final command = DecryptCommand();

      expect(
        command.description,
        equals('Déchiffrer un fichier .enc.'),
      );
    });

    test('L invocation doit être correcte', () {
      final command = DecryptCommand();

      expect(
        command.invocation,
        equals('<input.enc> [options]'),
      );
    });

    test(
      'Doit échouer si aucun fichier .enc n est fourni',
      () async {
        expect(
          () => runner.run(['decrypt']),
          throwsA(isA<UsageException>()),
        );
      },
    );

    test(
      'Doit échouer si plusieurs fichiers sont fournis',
      () async {
        expect(
          () => runner.run([
            'decrypt',
            'fichier1.enc',
            'fichier2.enc',
          ]),
          throwsA(isA<UsageException>()),
        );
      },
    );

    test(
      'Doit signaler une erreur si le fichier .enc n existe pas',
      () async {
        expect(
          () => runner.run([
            'decrypt',
            '/tmp/fichier_inexistant_file_encryptor.enc',
            '--password',
            'motdepasse123',
          ]),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('L option --output doit être disponible', () {
      final command = DecryptCommand();

      expect(
        command.argParser.options.containsKey('output'),
        isTrue,
      );
    });

    test('L option --output doit avoir l alias -o', () {
      final command = DecryptCommand();

      final option = command.argParser.options['output'];

      expect(option, isNotNull);
      expect(option!.abbr, equals('o'));
    });

    test('L option --password doit être disponible', () {
      final command = DecryptCommand();

      expect(
        command.argParser.options.containsKey('password'),
        isTrue,
      );
    });

    test('L option --password doit avoir l alias -p', () {
      final command = DecryptCommand();

      final option = command.argParser.options['password'];

      expect(option, isNotNull);
      expect(option!.abbr, equals('p'));
    });

    test('L option --output peut recevoir un chemin', () {
      final command = DecryptCommand();

      final results = command.argParser.parse([
        '--output',
        'restaure.txt',
      ]);

      expect(
        results['output'],
        equals('restaure.txt'),
      );
    });

    test('L option --password peut recevoir un mot de passe', () {
      final command = DecryptCommand();

      final results = command.argParser.parse([
        '--password',
        'motdepasse123',
      ]);

      expect(
        results['password'],
        equals('motdepasse123'),
      );
    });

    test('L alias -o doit fonctionner', () {
      final command = DecryptCommand();

      final results = command.argParser.parse([
        '-o',
        'restaure.txt',
      ]);

      expect(
        results['output'],
        equals('restaure.txt'),
      );
    });

    test('L alias -p doit fonctionner', () {
      final command = DecryptCommand();

      final results = command.argParser.parse([
        '-p',
        'motdepasse123',
      ]);

      expect(
        results['password'],
        equals('motdepasse123'),
      );
    });

    test(
      'Doit pouvoir utiliser un fichier .enc temporaire',
      () async {
        final temporaryDirectory =
            await Directory.systemTemp.createTemp(
          'file_encryptor_decrypt_test_',
        );

        try {
          final encryptedFile = File(
            '${temporaryDirectory.path}/test.enc',
          );

          await encryptedFile.writeAsBytes(
            <int>[1, 2, 3, 4],
          );

          expect(
            await encryptedFile.exists(),
            isTrue,
          );

          expect(
            await encryptedFile.length(),
            equals(4),
          );

          expect(
            encryptedFile.path.endsWith('.enc'),
            isTrue,
          );
        } finally {
          if (await temporaryDirectory.exists()) {
            await temporaryDirectory.delete(
              recursive: true,
            );
          }
        }
      },
    );
  });
}