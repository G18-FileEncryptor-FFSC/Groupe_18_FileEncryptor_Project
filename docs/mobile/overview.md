# Application Mobile

## 1. Présentation

FileEncryptor dispose d'une application mobile développée avec Flutter.

L'application fournit une interface graphique permettant à l'utilisateur d'effectuer les principales opérations de chiffrement et de déchiffrement des fichiers.

## 2. Fonctionnalités

L'application mobile est organisée autour des fonctionnalités suivantes :

* Home
* Encryption
* Decryption
* History
* Settings

## 3. Couche Presentation

La partie mobile correspond principalement à la couche Presentation de l'architecture.

Elle contient :

* les pages et écrans ;
* les widgets ;
* la gestion de l'état ;
* la navigation.

Cette couche est responsable de l'affichage et des interactions avec l'utilisateur.

## 4. Gestion d'état

La gestion d'état permet de maintenir et de mettre à jour les informations nécessaires à l'interface.

La solution de gestion d'état utilisée par l'équipe sera documentée ici lorsqu'elle sera définitivement choisie.

## 5. Interaction avec le Core

L'application Flutter ne contient pas directement la logique cryptographique.

Elle utilise le Core Dart pour effectuer les opérations métier.

Le principe est :

```text
Interface Flutter
       ↓
     Core
       ↓
Chiffrement / Déchiffrement
```

## 6. Navigation

La navigation entre les différentes fonctionnalités de l'application est gérée par la couche Presentation.

Les routes et les écrans seront documentés plus précisément lorsque la navigation sera implémentée.

## 7. Platform Channels

Les Platform Channels pourront être utilisés pour certaines interactions spécifiques avec les APIs natives Android ou iOS.

Ils doivent rester isolés de la logique métier.

La cryptographie ne doit pas être placée dans les Platform Channels.

## 8. Évolution

La documentation de cette partie sera mise à jour au fur et à mesure de l'évolution de l'application mobile.

Toute nouvelle fonctionnalité importante doit être accompagnée de sa documentation.
