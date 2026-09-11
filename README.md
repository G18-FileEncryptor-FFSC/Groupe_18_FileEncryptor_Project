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
