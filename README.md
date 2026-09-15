# FileEncryptor

FileEncryptor est un outil de chiffrement et de déchiffrement de fichiers.

Le projet a pour objectif de permettre à un utilisateur de sélectionner un fichier, de le chiffrer localement à l'aide d'un secret ou d'un mot de passe, puis de le déchiffrer ultérieurement avec le bon secret.

## Fonctionnalités principales

Le projet prévoit deux interfaces :

* **Application mobile Flutter** : interface graphique simple, moderne et intuitive.
* **CLI Dart** : interface en ligne de commande permettant d'effectuer les principales opérations de chiffrement et de déchiffrement.

Le cœur fonctionnel est principalement développé en Dart pur afin de pouvoir être réutilisé par les différentes interfaces.

## Architecture

Le projet suit une architecture simple basée sur trois couches :

```text
Presentation
     ↓
Domain
     ↓
Data
```

La logique de chiffrement et de gestion des fichiers est séparée de l'interface Flutter.

Cette organisation permet notamment de préparer la réutilisation du cœur fonctionnel par la future CLI Dart.

Pour plus de détails, consulter :

`docs/architecture/architecture.md`

## Structure du projet

```text
FileEncryptor/
├── apps/
│   ├── mobile/
│   └── cli/
│
├── packages/
│   └── core/
│
├── docs/
│   └── architecture/
│
├── README.md
├── CONTRIBUTING.md
└── SECURITY.md
```

## État du projet

Le projet est actuellement en cours de développement.

L'application mobile Flutter constitue la première interface développée. La CLI Dart sera intégrée progressivement après la mise en place du cœur fonctionnel.

### 2. Lancer la CLI
Sans argument, la CLI affiche un menu interactif :

```bash
cd apps/cli
dart run bin/main.dart
```

Menu proposé :

```text
FileEncryptor
Que souhaitez-vous faire ?

1) Chiffrer un fichier
2) Déchiffrer un fichier
3) Voir l’historique
4) Quitter
```

Vous pouvez aussi utiliser les commandes directement :

```bash
dart run bin/main.dart --help
dart run bin/main.dart encrypt ./mon_fichier.txt --password "secret123"
dart run bin/main.dart decrypt ./mon_fichier.txt.enc --password "secret123"
dart run bin/main.dart history
```

Le mot de passe est saisi masqué lors des interactions terminal.

### 3. Lancer l'Application Mobile
```bash
cd apps/mobile
flutter run
```
## Documentation

La documentation du projet est disponible dans le dossier `docs/`.

Elle couvre notamment :

* l'architecture du projet ;
* le fonctionnement du Core ;
* l'application mobile ;
* la future CLI ;
* la sécurité ;
* la contribution au projet ;
* les exemples d'utilisation.

## Contribution

Les développeurs souhaitant contribuer au projet doivent consulter :

`CONTRIBUTING.md`

## Sécurité

Pour les informations relatives à la sécurité du projet, consulter :

`SECURITY.md`
