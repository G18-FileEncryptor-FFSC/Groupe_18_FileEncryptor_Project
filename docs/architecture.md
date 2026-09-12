# Spécifications de l'Architecture

## Clean Architecture & Monorepo

```
┌─────────────────────────┐          ┌─────────────────────────┐
│     Flutter Mobile      │          │        CLI Dart         │
│  (apps/mobile: Présent.)│          │   (apps/cli: Présent.)  │
└────────────┬────────────┘          └────────────┬────────────┘
             │                                    │
             └─────────────────┬──────────────────┘
                               │
                               ▼
             ┌────────────────────────────────────┐
             │       Use Cases (Domain)           │
             └─────────────────┬──────────────────┘
                               │
                               ▼
             ┌────────────────────────────────────┐
             │    Repositories (Abstractions)     │
             └─────────────────┬──────────────────┘
                               │
                               ▼
             ┌────────────────────────────────────┐
             │    Data Sources (Implémentation)   │
             └─────────────────┬──────────────────┘
                               │
                               ▼
             ┌────────────────────────────────────┐
             │    Crypto / File I/O / Storage     │
             └────────────────────────────────────┘
```

### Modules
1. **`packages/file_encryptor_core`** : Code Dart pur contenant les entités, contrats, cas d'utilisation, moteur AES, etc.
2. **`apps/cli`** : Interface terminal.
3. **`apps/mobile`** : Application Flutter multiplateforme découpée par features.
