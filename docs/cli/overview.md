# CLI Dart

## 1. Présentation

FileEncryptor prévoit une interface en ligne de commande (CLI) développée en Dart.

La CLI permettra d'effectuer les principales opérations de FileEncryptor depuis un terminal.

## 2. Objectif

L'objectif de la CLI est de fournir une interface simple permettant d'utiliser les fonctionnalités principales du projet sans passer par l'application mobile Flutter.

## 3. Relation avec le Core

La CLI doit réutiliser le Core Dart de FileEncryptor.

Le principe prévu est :

```text
CLI Dart
   ↓
Core Dart
   ↓
Chiffrement / Déchiffrement
```

La logique de chiffrement, de déchiffrement, de validation et de gestion des fichiers ne doit donc pas être réécrite dans la CLI.

## 4. Fonctionnalités prévues

La CLI devra notamment permettre :

* de chiffrer un fichier ;
* de déchiffrer un fichier ;
* de gérer les erreurs liées aux opérations ;
* d'utiliser le même cœur fonctionnel que l'application mobile.

Les commandes exactes seront documentées lorsque la CLI sera développée et testée.

## 5. Indépendance de l'interface Flutter

La CLI est indépendante de l'interface graphique Flutter.

Elle communique directement avec le Core Dart.

Cette organisation permet de partager la logique métier entre les différentes interfaces.

## 6. Évolution

La CLI sera développée après la mise en place du cœur fonctionnel.

Sa documentation sera mise à jour au fur et à mesure de l'implémentation et des fonctionnalités disponibles.
