# Core

## 1. Présentation

Le Core de FileEncryptor contient la logique principale qui doit pouvoir fonctionner indépendamment de l'interface Flutter.

Son objectif est de centraliser les fonctionnalités communes utilisées par les différentes interfaces du projet.

## 2. Responsabilités

Le Core regroupe notamment :

* la cryptographie ;
* le chiffrement et le déchiffrement ;
* la gestion des fichiers ;
* la validation des données ;
* la gestion des erreurs.

## 3. Indépendance vis-à-vis de Flutter

La logique du Core ne doit pas dépendre directement des widgets ou des composants de l'interface Flutter.

Cette séparation permet de tester la logique indépendamment de l'interface graphique.

## 4. Cryptographie

La cryptographie doit être isolée dans une partie dédiée du Core.

Elle sera responsable des opérations de chiffrement et de déchiffrement.

La méthode cryptographique utilisée sera documentée ici lorsqu'elle aura été définie et implémentée par l'équipe.

## 5. File I/O

La gestion des fichiers doit également être séparée de l'interface utilisateur.

Elle permet notamment de lire les fichiers, d'écrire les fichiers chiffrés et de produire les fichiers déchiffrés.

## 6. Réutilisation par la CLI

Le Core est conçu pour pouvoir être utilisé par plusieurs interfaces.

L'objectif est de permettre l'évolution suivante :

Flutter
↓
Core Dart
↓
CLI Dart

La future CLI pourra ainsi réutiliser la logique métier existante sans devoir réécrire la cryptographie ou la gestion des fichiers.

## 7. Testabilité

Les fonctionnalités du Core doivent être conçues de manière à pouvoir être testées indépendamment de Flutter.

Les tests importants concerneront notamment :

* la cryptographie ;
* le chiffrement et le déchiffrement ;
* le File I/O ;
* les validations ;
* la gestion des erreurs.
