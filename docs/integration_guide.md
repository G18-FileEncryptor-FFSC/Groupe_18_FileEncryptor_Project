# Guide d'Intégration de `file_encryptor_core`

Ce guide détaille la procédure pour consommer et orchestrer le package partagé **`file_encryptor_core`** au sein des deux applications clientes du monorepo :
1. **L'application Terminal en Dart pur** : [`apps/cli`](file:///c:/Users/TOUMAINI/Desktop/Groupe_18_FileEncryptor_Project/apps/cli)
2. **L'application Mobile Flutter** : [`apps/mobile`](file:///c:/Users/TOUMAINI/Desktop/Groupe_18_FileEncryptor_Project/apps/mobile)

---

## 1. Déclaration de la dépendance dans les `pubspec.yaml`

Grâce aux **Workspaces Dart (SDK ≥ 3.5.0)**, aucune dépendance par chemin relatif (`path: ../../packages/...`) n'est requise. La résolution s'effectue automatiquement au niveau de l'espace de travail racine.

### Pour l'application CLI : [`apps/cli/pubspec.yaml`](file:///c:/Users/TOUMAINI/Desktop/Groupe_18_FileEncryptor_Project/apps/cli/pubspec.yaml)
```yaml
dependencies:
  file_encryptor_core: any
  path: ^1.9.0
  args: ^2.5.0 # Recommandé pour parser les arguments CLI
```

### Pour l'application Mobile : [`apps/mobile/pubspec.yaml`](file:///c:/Users/TOUMAINI/Desktop/Groupe_18_FileEncryptor_Project/apps/mobile/pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  file_encryptor_core: any
  path_provider: ^2.1.2 # Pour obtenir les dossiers sécurisés sur iOS/Android
```

Après avoir ajouté la dépendance, synchronisez l'espace de travail depuis la racine :
```bash
flutter pub get
```

---

## 2. Architecture des briques et instanciation

Toutes les interfaces et cas d'utilisation s'importent via le point d'entrée unique :

```dart
import 'package:file_encryptor_core/file_encryptor_core.dart';
```

### Initialisation des Repositories et Use Cases
```dart
// 1. Couche Data (implémentations prêtes à l'emploi)
final cryptoRepo = CryptoRepositoryImpl();
final fileRepo = FileRepositoryImpl();
final historyRepo = HistoryRepositoryImpl(
  dataSource: HistoryLocalDataSource(
    // Sur Mobile, passer un chemin absolu via path_provider (voir section Mobile)
    customStoragePath: '.file_encryptor_history.json',
  ),
);

// 2. Couche Domain (Cas d'utilisation)
final encryptFileUseCase = EncryptFileUseCase(
  cryptoRepository: cryptoRepo,
  fileRepository: fileRepo,
  historyRepository: historyRepo,
);

final decryptFileUseCase = DecryptFileUseCase(
  cryptoRepository: cryptoRepo,
  fileRepository: fileRepo,
  historyRepository: historyRepo,
);

final getHistoryUseCase = GetHistoryUseCase(repository: historyRepo);
final saveHistoryUseCase = SaveHistoryUseCase(repository: historyRepo);
```

---

## 3. Intégration dans le module CLI (`apps/cli`)

L'application terminal orchestre les use cases avec des flux I/O console et des codes de sortie système (`exit(0)` / `exit(1)`).

### Exemple de commande `encrypt`
```dart
import 'dart:io';
import 'package:file_encryptor_core/file_encryptor_core.dart';

Future<void> handleEncryptCommand({
  required String filePath,
  required String password,
  String? customOutputPath,
}) async {
  final encryptUseCase = EncryptFileUseCase(
    cryptoRepository: CryptoRepositoryImpl(),
    fileRepository: FileRepositoryImpl(),
    historyRepository: HistoryRepositoryImpl(),
  );

  stdout.write('Chiffrement de $filePath en cours...\n');

  final result = await encryptUseCase(
    inputPath: filePath,
    outputPath: customOutputPath,
    password: password,
    onProgress: (progress) {
      final percent = (progress.percentage * 100).toInt();
      stdout.write('\r[PROGRESS] $percent% — ${progress.phase}');
    },
  );

  stdout.write('\n');

  if (result.isSuccess) {
    print('✅ Fichier chiffré avec succès : ${result.outputPath}');
    print('   Taille : ${result.fileSizeBytes} octets');
    print('   Durée : ${result.duration.inMilliseconds} ms');
  } else {
    stderr.writeln('❌ Échec du chiffrement : ${result.errorMessage}');
    exit(1);
  }
}
```

### Exemple de commande `decrypt`
```dart
Future<void> handleDecryptCommand({
  required String encFilePath,
  required String password,
  String? outputDirectory,
}) async {
  final decryptUseCase = DecryptFileUseCase(
    cryptoRepository: CryptoRepositoryImpl(),
    fileRepository: FileRepositoryImpl(),
    historyRepository: HistoryRepositoryImpl(),
  );

  final result = await decryptUseCase(
    inputPath: encFilePath,
    outputDirectoryOrPath: outputDirectory,
    password: password,
    onProgress: (p) => stdout.write('\r[${(p.percentage * 100).toInt()}%] ${p.phase}'),
  );

  stdout.write('\n');

  if (result.isSuccess) {
    print('✅ Fichier restauré avec succès : ${result.outputPath}');
    print('   Nom original : ${result.originalFileName}');
  } else {
    stderr.writeln('❌ Échec du déchiffrement : ${result.errorMessage}');
    exit(1);
  }
}
```

---

## 4. Intégration dans le module Flutter Mobile (`apps/mobile`)

Sur mobile, l'intégration prend en compte :
1. L'emplacement de stockage sur Android/iOS (sandbox des applications).
2. La liaison avec l'interface graphique (barre de progression, sélecteur de fichiers).
3. L'exécution asynchrone fluide (possibilité d'utiliser `compute` de Flutter pour les très gros fichiers).

### A. Initialisation du stockage dans l'application Flutter
Sur Android et iOS, l'écriture directe dans le dossier de travail courant n'est pas autorisée. Utilisez `path_provider` :

```dart
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';

Future<HistoryRepository> createMobileHistoryRepository() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final historyPath = '${appDocDir.path}/encryption_history.json';

  return HistoryRepositoryImpl(
    dataSource: HistoryLocalDataSource(customStoragePath: historyPath),
  );
}
```

### B. Exemple d'un Controller / ViewModel (State Management)
```dart
import 'package:flutter/foundation.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';

class EncryptionController extends ChangeNotifier {
  final EncryptFileUseCase _encryptUseCase;
  final DecryptFileUseCase _decryptUseCase;

  EncryptionController({
    required EncryptFileUseCase encryptUseCase,
    required DecryptFileUseCase decryptUseCase,
  })  : _encryptUseCase = encryptUseCase,
        _decryptUseCase = decryptUseCase;

  double _progress = 0.0;
  String _statusMessage = '';
  bool _isLoading = false;

  double get progress => _progress;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;

  Future<EncryptionResult> encrypt(String filePath, String password) async {
    _isLoading = true;
    _progress = 0.0;
    _statusMessage = 'Démarrage...';
    notifyListeners();

    final result = await _encryptUseCase(
      inputPath: filePath,
      password: password,
      onProgress: (p) {
        _progress = p.percentage;
        _statusMessage = p.phase;
        notifyListeners();
      },
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<EncryptionResult> decrypt(String encFilePath, String password, String targetDir) async {
    _isLoading = true;
    _progress = 0.0;
    notifyListeners();

    final result = await _decryptUseCase(
      inputPath: encFilePath,
      outputDirectoryOrPath: targetDir,
      password: password,
      onProgress: (p) {
        _progress = p.percentage;
        _statusMessage = p.phase;
        notifyListeners();
      },
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
```

### C. Gestion des erreurs dans les composants UI Flutter
```dart
void onDecryptPressed(BuildContext context, EncryptionController controller, String path, String password) async {
  final targetDir = (await getApplicationDocumentsDirectory()).path;
  final result = await controller.decrypt(path, password, targetDir);

  if (!context.mounted) return;

  if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fichier restauré : ${result.originalFileName}'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    // Affichage d'un message adapté à l'utilisateur
    final message = result.errorMessage?.contains('InvalidPasswordException') == true
        ? 'Mot de passe incorrect ou fichier altéré.'
        : 'Une erreur est survenue lors de l\'opération.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
```

---

## 5. Résumé des exceptions métier

| Exception | Cause typique | Action UI recommandée |
|---|---|---|
| `InvalidPasswordException` | Mot de passe erroné ou échec du tag d'authentification MAC GCM. | Inviter l'utilisateur à ressaisir son mot de passe. |
| `FileNotFoundException` | Le chemin du fichier spécifié n'existe pas sur le disque. | Demander une nouvelle sélection de fichier. |
| `InvalidHeaderException` | Les magic bytes (`FENC`) ou la version du fichier sont incorrects. | Alerter que le fichier n'est pas un fichier `.enc` supporté. |
| `CorruptedFileException` | Le conteneur est incomplet ou tronqué. | Signaler que le fichier est corrompu ou incomplet. |
| `StorageException` | Échec de lecture/écriture du fichier d'historique. | Loguer l'erreur sans interrompre l'opération principale. |
