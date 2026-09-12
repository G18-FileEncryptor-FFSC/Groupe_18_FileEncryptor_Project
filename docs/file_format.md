# Format du Fichier Chiffré (.enc)

Structure binaire du format de conteneur `.enc` :
1. **Magic Bytes** (4 octets) : `FENC` (0x46454E43)
2. **Version** (1 octet) : 0x01
3. **Sel KDF** (32 octets)
4. **Nonce / IV** (12 octets)
5. **Longueur du nom original** (1 octet)
6. **Nom original** (UTF-8)
7. **Payload chiffré** (AES-GCM)
8. **Tag d'authentification** (16 octets)
