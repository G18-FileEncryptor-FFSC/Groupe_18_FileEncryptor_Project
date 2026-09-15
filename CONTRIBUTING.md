# CONTRIBUTING

Merci de votre intérêt pour le projet **FileEncryptor**.

Ce document explique comment contribuer au projet et quelles règles suivre pour faciliter le travail de l'équipe.

## 1. Préparer l'environnement

Avant de commencer, assurez-vous d'avoir :

* Git installé ;
* le projet FileEncryptor cloné localement ;
* les dépendances nécessaires installées ;
* un environnement de développement fonctionnel.

## 2. Créer une branche

Avant de modifier le projet, créez une branche dédiée à votre travail :

```bash
git switch -c nom-de-la-branche
```

Utilisez un nom clair qui décrit la fonctionnalité ou la correction réalisée.

Exemple :

```bash
git switch -c ajout-encryption
```

## 3. Effectuer les modifications

Développez votre fonctionnalité ou corrigez le problème identifié.

Respectez :

* la structure existante du projet ;
* les conventions de programmation utilisées ;
* les règles de sécurité ;
* les principes décrits dans la documentation technique.

## 4. Tester les modifications

Avant de proposer vos changements, vérifiez que le projet fonctionne correctement.

Les fonctionnalités modifiées doivent être testées afin d'éviter d'introduire de nouvelles erreurs.

## 5. Enregistrer les modifications

Vérifiez d'abord l'état du projet :

```bash
git status
```

Ajoutez ensuite les fichiers modifiés :

```bash
git add .
```

Créez un commit avec un message clair :

```bash
git commit -m "Description des modifications"
```

Exemple :

```bash
git commit -m "Ajout du chiffrement des fichiers"
```

## 6. Envoyer les modifications

Envoyez votre branche vers le dépôt distant :

```bash
git push origin nom-de-la-branche
```

## 7. Créer une Pull Request

Après avoir envoyé votre branche, créez une **Pull Request** vers la branche principale du projet.

La Pull Request doit expliquer :

* ce qui a été modifié ;
* pourquoi la modification a été réalisée ;
* les tests effectués ;
* les éventuelles mises à jour de documentation nécessaires.

## 8. Documentation

Toute nouvelle fonctionnalité ou modification importante doit être accompagnée d'une mise à jour de la documentation lorsque cela est nécessaire.

Les exemples et les commandes présentés dans la documentation doivent rester cohérents avec le comportement réel du projet.

## 9. Bonnes pratiques

Les contributions doivent respecter les principes suivants :

* écrire un code clair et compréhensible ;
* éviter les modifications inutiles ;
* respecter l'architecture du projet ;
* tester les fonctionnalités modifiées ;
* documenter les changements importants ;
* ne jamais introduire volontairement de failles de sécurité.

## 10. Definition of Done

Une contribution est considérée comme terminée lorsque :

* le code fonctionne correctement ;
* les tests nécessaires sont réalisés ;
* la documentation concernée est mise à jour ;
* les exemples sont cohérents ;
* les liens concernés fonctionnent ;
* la Pull Request est prête à être examinée.
