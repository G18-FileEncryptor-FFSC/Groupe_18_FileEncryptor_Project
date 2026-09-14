# File Encryptor CLI

CLI Dart pour chiffrer et déchiffrer des fichiers à l’aide des Use Cases du package `file_encryptor_core`.

Cette interface ne réimplémente pas la cryptographie : elle orchestre le domaine partagé et affiche les résultats utilisateur.

## Prérequis

- Dart SDK 3.13 ou plus
- dépendances du workspace déjà résolues par `dart pub get`

## Exécution

Depuis le dossier du package CLI :

```bash
dart run bin/file_encryptor.dart --help
dart run bin/file_encryptor.dart encrypt ./mon_fichier.txt --password "secret123"
dart run bin/file_encryptor.dart decrypt ./mon_fichier.txt.enc --password "secret123"
```

Depuis la racine du monorepo :

```bash
dart run apps/cli/bin/file_encryptor.dart --help
```

## Commandes disponibles

### 1) encrypt

Chiffre un fichier source et produit un conteneur `.enc`.

Usage :

```bash
dart run bin/file_encryptor.dart encrypt <input> [options]
```

Options :

- `-o, --output <path>` : chemin du fichier chiffré de sortie
- `-p, --password <value>` : mot de passe fourni en argument
- `-h, --help` : affiche l’aide de la commande

Exemples :

```bash
dart run bin/file_encryptor.dart encrypt ./documents/rapport.txt

dart run bin/file_encryptor.dart encrypt ./documents/rapport.txt --output ./documents/rapport.txt.enc --password "secret123"
```

Si aucun mot de passe n’est fourni et que la commande est exécutée dans un terminal interactif, la CLI le demande de manière sécurisée.

### 2) decrypt

Déchiffre un fichier `.enc` et restaure le fichier original.

Usage :

```bash
dart run bin/file_encryptor.dart decrypt <input.enc> [options]
```

Options :

- `-o, --output <path>` : chemin ou dossier de sortie
- `-p, --password <value>` : mot de passe fourni en argument
- `-h, --help` : affiche l’aide de la commande

Exemples :

```bash
dart run bin/file_encryptor.dart decrypt ./documents/rapport.txt.enc

dart run bin/file_encryptor.dart decrypt ./documents/rapport.txt.enc --output ./restore/rapport.txt --password "secret123"
```

### 3) history

Affiche l’historique des opérations enregistrées.

Usage :

```bash
dart run bin/file_encryptor.dart history
```

Options :

- `--clear` : efface l’historique
- `-h, --help` : affiche l’aide de la commande

Exemples :

```bash
dart run bin/file_encryptor.dart history
dart run bin/file_encryptor.dart history --clear
```

## Aide globale

```bash
dart run bin/file_encryptor.dart --help
```

Affiche :

- `encrypt`
- `decrypt`
- `history`

## Codes de sortie

- `0` : succès
- `1` : erreur d’arguments, fichier introuvable, mot de passe invalide, fichier corrompu, etc.

## Sécurité

Le mot de passe n’est jamais affiché dans la sortie de la commande.

Pour des raisons de sécurité, il est préférable d’utiliser la saisie interactive plutôt que `--password`, car les arguments peuvent apparaître dans le shell, l’historique du système ou les journaux d’outils externes.

## Développement et validation

Depuis la racine du workspace :

```bash
dart pub get
dart analyze apps/cli
dart test apps/cli/test
```

## Exemple de workflow complet

```bash
dart run bin/file_encryptor.dart encrypt ./demo.txt --password "motdepasse123"
dart run bin/file_encryptor.dart decrypt ./demo.txt.enc --password "motdepasse123"
```

Le fichier déchiffré est restauré dans le chemin demandé, ou dans un chemin par défaut si aucun `--output` n’est fourni.
