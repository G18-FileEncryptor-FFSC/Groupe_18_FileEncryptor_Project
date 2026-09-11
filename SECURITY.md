# Security Policy

## Sécurité de FileEncryptor

FileEncryptor est un outil destiné au chiffrement et au déchiffrement local de fichiers.

La sécurité est une priorité du projet. La cryptographie et la gestion des données sensibles doivent être séparées de l'interface utilisateur.

## Règles de sécurité

* Ne jamais stocker de mots de passe ou de secrets directement dans le code source.
* Ne jamais publier de secrets ou de données sensibles sur GitHub.
* Ne pas afficher les secrets de l'utilisateur dans les messages d'erreur ou les logs.
* La logique cryptographique doit rester indépendante de l'interface Flutter.
* Les Platform Channels ne doivent pas contenir la logique de chiffrement.
* Toute modification importante concernant la sécurité doit être vérifiée avant d'être intégrée.

## Signalement d'un problème de sécurité

Si une vulnérabilité de sécurité est découverte, elle doit être signalée aux responsables du projet avant d'être rendue publique.

Les informations sensibles ne doivent pas être publiées directement dans une Issue publique.

## Évolution

Cette politique sera mise à jour lorsque de nouvelles fonctionnalités ou de nouvelles exigences de sécurité seront ajoutées au projet.
