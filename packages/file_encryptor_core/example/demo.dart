import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';

void main() async {
  // 1. Initialisation des briques du Core
  final cryptoRepo = CryptoRepositoryImpl();
  final fileRepo = FileRepositoryImpl();
  final historyRepo = HistoryRepositoryImpl();

  final encryptUseCase = EncryptFileUseCase(
    cryptoRepository: cryptoRepo,
    fileRepository: fileRepo,
    historyRepository: historyRepo,
  );

  final decryptUseCase = DecryptFileUseCase(
    cryptoRepository: cryptoRepo,
    fileRepository: fileRepo,
    historyRepository: historyRepo,
  );

  print('=== DÉMONSTRATION DU CŒUR FILE_ENCRYPTOR ===\n');

  // 2. Création d'un fichier source
  final originalFile = File('mon_document.txt');
  await originalFile.writeAsString('Message ultra-confidentiel du Groupe 18 !');
  print('✅ 1. Fichier source créé : ${originalFile.path}');
  print('   Contenu : "${await originalFile.readAsString()}"\n');

  // 3. Chiffrement
  print('🔒 2. Chiffrement en cours avec le mot de passe "ClefSecrete2026"...');
  final encResult = await encryptUseCase(
    inputPath: 'mon_document.txt',
    outputPath: 'mon_document.txt.enc',
    password: 'ClefSecrete2026',
    onProgress: (p) =>
        print('   [${(p.percentage * 100).toInt()}%] ${p.phase}'),
  );

  print('✅ Fichier chiffré créé : ${encResult.outputPath}');
  final encBytes = await File(encResult.outputPath).readAsBytes();
  print(
    '   En-tête Magic Bytes : ${String.fromCharCodes(encBytes.sublist(0, 4))}',
  );
  print('   Taille totale du conteneur : ${encBytes.length} octets\n');

  // 4. Déchiffrement avec le BON mot de passe
  print('🔓 3. Déchiffrement avec le BON mot de passe...');
  final decResult = await decryptUseCase(
    inputPath: 'mon_document.txt.enc',
    outputDirectoryOrPath: 'mon_document_restaure.txt',
    password: 'ClefSecrete2026',
    onProgress: (p) =>
        print('   [${(p.percentage * 100).toInt()}%] ${p.phase}'),
  );

  print('✅ Fichier restauré : ${decResult.outputPath}');
  print(
    '   Contenu restauré : "${await File(decResult.outputPath).readAsString()}"\n',
  );

  // 5. Test de sécurité avec un MAUVAIS mot de passe
  print('🛡️ 4. Test de sécurité (Tentative avec un MAUVAIS mot de passe)...');
  final failResult = await decryptUseCase(
    inputPath: 'mon_document.txt.enc',
    outputDirectoryOrPath: 'mon_document_fail.txt',
    password: 'MauvaisMotDePasse',
  );

  if (!failResult.isSuccess) {
    print(
      '✅ Sécurité confirmée ! Rejet immédiat : ${failResult.errorMessage}\n',
    );
  }

  // 6. Affichage de l'historique
  final history = await historyRepo.getHistory();
  print(
    '📜 5. Historique des opérations enregistrées : ${history.length} entrée(s)',
  );
  for (final item in history) {
    print(
      '   - ${item.operation.name.toUpperCase()} : ${item.fileName} -> Succès: ${item.isSuccess}',
    );
  }
}
