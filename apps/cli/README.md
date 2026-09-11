# File Encryptor CLI

CLI Dart permettant d'utiliser le même domaine de chiffrement que l'application mobile, sans dupliquer la logique cryptographique.

## Commandes

```bash
dart run bin/file_encryptor.dart --help
dart run bin/file_encryptor.dart encrypt ./document.pdf
dart run bin/file_encryptor.dart encrypt ./document.pdf --output ./document.pdf.enc
dart run bin/file_encryptor.dart encrypt ./document.pdf --password 'mot-de-passe'
dart run bin/file_encryptor.dart decrypt ./document.pdf.enc
dart run bin/file_encryptor.dart decrypt ./document.pdf.enc --output ./restored/
dart run bin/file_encryptor.dart decrypt ./document.pdf.enc --password 'mot-de-passe'
dart run bin/file_encryptor.dart history
dart run bin/file_encryptor.dart history --clear
```

Le mot de passe n'est jamais affiché par la CLI. Pour une meilleure sécurité, préférez la saisie interactive plutôt que `--password`, car les arguments d'un processus peuvent être visibles dans l'historique du shell ou dans certains outils système.

## Codes de sortie

- `0` : opération réussie.
- `1` : erreur d'argument, fichier, mot de passe, conteneur ou autre échec.

## Architecture

La CLI dépend uniquement de `file_encryptor_core` pour les opérations de chiffrement, déchiffrement et historique. Les commandes ne réimplémentent pas AES-GCM, PBKDF2 ni le format `.enc`.

## Développement

Depuis la racine du workspace :

```bash
dart pub get
dart analyze apps/cli
cd apps/cli
dart test
```
