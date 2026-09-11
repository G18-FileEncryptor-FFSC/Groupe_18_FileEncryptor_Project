# Architecture de FileEncryptor

## 1. Vue générale

FileEncryptor est un outil de chiffrement et de déchiffrement de fichiers.

L'application mobile est développée avec Flutter et le cœur fonctionnel est développé en Dart.

L'architecture est organisée en trois couches principales :

- Presentation
- Domain
- Data

Le principe général est :

Presentation
↓
Domain
↓
Data

## 2. Couche Presentation

La couche Presentation correspond à l'interface utilisateur Flutter.

Elle contient les pages, les widgets et la gestion de l'état de l'interface.

Elle est organisée autour des fonctionnalités principales :

- Home
- Encryption
- Decryption
- History
- Settings

Cette couche ne contient pas directement la logique de chiffrement ou de déchiffrement.
## 3. Couche Domain

La couche Domain contient la logique métier principale de FileEncryptor.

Elle est indépendante de Flutter, d'Android et d'iOS.

Elle contient principalement :

* les entities ;
* les use cases ;
* les repositories ;
* les services nécessaires au fonctionnement du métier ;
* la gestion des erreurs métier.

### 3.1 Entities

Les entities représentent les objets importants du domaine.

Exemples :

* fichier à chiffrer ;
* fichier chiffré ;
* résultat d'une opération ;
* entrée de l'historique.

Les entities ne dépendent pas de Flutter.

### 3.2 Use Cases

Les use cases représentent les actions que l'utilisateur peut effectuer.

Les principaux use cases sont :

* EncryptFile : chiffrer un fichier ;
* DecryptFile : déchiffrer un fichier ;
* GetHistory : récupérer l'historique ;
* SaveHistoryEntry : enregistrer une opération.

Les use cases coordonnent les différentes opérations sans contenir les détails spécifiques à l'interface Flutter.

### 3.3 Repositories

Les repositories définissent les contrats nécessaires au Domain pour accéder aux données.

Par exemple :

* EncryptionRepository ;
* HistoryRepository.

Le Domain définit les interfaces, tandis que leur implémentation se trouve dans la couche Data.

### 3.4 Services

Les services définissent les fonctionnalités techniques nécessaires au métier.

Par exemple :

* CryptoService pour les opérations cryptographiques ;
* FileStorage pour les opérations liées aux fichiers.

Le Domain ne connaît pas les détails de leur implémentation.

## 4. Couche Data

La couche Data contient les implémentations concrètes nécessaires au fonctionnement de l'application.

Elle communique avec les systèmes externes, notamment le système de fichiers et le stockage local.

Elle contient principalement :

* les models ;
* les data sources ;
* les repositories ;
* la cryptographie ;
* le File I/O.

### 4.1 Models

Les models représentent les données utilisées pour le stockage ou les échanges avec les data sources.

### 4.2 Data Sources

Les data sources permettent d'accéder concrètement aux données.

Par exemple :

* lecture et écriture des fichiers ;
* stockage de l'historique.

### 4.3 Repositories

Les repositories de la couche Data implémentent les interfaces définies dans le Domain.

Ils font le lien entre les use cases et les sources de données.

### 4.4 Cryptographie

La cryptographie est isolée dans la couche Data/Core et ne dépend pas de Flutter.

Elle est utilisée par les use cases pour chiffrer et déchiffrer les fichiers.

Cette organisation permet de réutiliser cette logique plus tard dans la CLI Dart.

### 4.5 File I/O

Le File I/O est également indépendant de l'interface Flutter.

Il permet notamment de :

* lire les fichiers ;
* écrire les fichiers chiffrés ;
* lire les fichiers chiffrés ;
* écrire les fichiers déchiffrés.

Cette séparation facilite les tests et la future réutilisation par la CLI.
