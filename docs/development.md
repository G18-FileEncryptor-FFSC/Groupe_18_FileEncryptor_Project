# Guide de Développement & Conventions

- Le code partagé se trouve exclusivement dans `packages/file_encryptor_core`.
- `file_encryptor_core` ne doit avoir aucune dépendance vers Flutter.
- Suivre les conventions Clean Architecture :
  - `domain/` définit les règles et les interfaces.
  - `data/` implémente les détails techniques.
- Pour lancer les tests :
  `dart test` ou `flutter test`
