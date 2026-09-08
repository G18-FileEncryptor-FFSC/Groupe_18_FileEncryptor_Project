# FileEncryptor — Groupe 18

Monorepo pour l'application **FileEncryptor** (CLI Dart & Mobile Flutter) articulée autour d'un package métier commun en Clean Architecture (**FileEncryptor Core**).

---

## Structure du Monorepo

```
file_encryptor/
├── .github/workflows/          # CI/CD (tests unitaires, builds)
├── apps/
│   ├── cli/                    # Application Terminal en Dart pur
│   └── mobile/                 # Application Mobile Flutter (Android / iOS)
├── packages/
│   └── file_encryptor_core/    # Cœur métier Clean Architecture (Domain / Data)
├── docs/                       # Spécifications et documentation d'architecture
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml                # Workspace racine
└── README.md
```

---

## Démarrage Rapide

### 1. Installation des dépendances
À la racine du projet :
```bash
dart pub get
```

### 2. Lancer la CLI
```bash
cd apps/cli
dart run bin/main.dart --help
```

### 3. Lancer l'Application Mobile
```bash
cd apps/mobile
flutter run
```

### 4. Lancer les Tests
```bash
# Tests du core
cd packages/file_encryptor_core && dart test

# Tests de la CLI
cd apps/cli && dart test

# Tests de l'app mobile
cd apps/mobile && flutter test
```

---

## Documentation
Consultez le dossier [`docs/`](docs/) pour plus de détails :
- [Architecture](docs/architecture.md)
- [Cryptographie](docs/cryptography.md)
- [Format de fichier .enc](docs/file_format.md)
- [Guide de développement](docs/development.md)