# Ewon Flexy Config

## Pour les utilisateurs finaux
Téléchargez `PrepareEwonSD.exe` depuis le partage réseau interne ou demandez-le à l'IT.

## Pour les développeurs

### Setup initial
1. Clonez ce repository
2. Créez un dossier `Build` local
3. Copiez `build.ps1` depuis la documentation
4. Modifiez les informations de configuration
5. Exécutez `.\build.ps1`

### Mise à jour du manifest
Éditez `manifest.json` pour ajouter de nouveaux firmwares :
```json
{
  "version": "1.1.0",
  "firmwares": [
    {
      "version": "15.0s2",
      "hasEbu": true
    }
  ]
}
