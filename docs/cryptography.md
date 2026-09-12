# Spécifications Cryptographiques

- **Algorithme** : AES-256 (mode GCM pour Authenticated Encryption avec Associated Data).
- **Nonce/IV** : 96 bits (12 octets), généré via un générateur cryptographique aléatoire sécurisé.
- **KDF** : PBKDF2 avec HMAC-SHA256 (sel de 256 bits, 100 000 itérations).
- **Tag d'authentification** : 128 bits (16 octets) garantissant l'intégrité du fichier chiffré.
