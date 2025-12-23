# 📦 Ewon Flexy SD Preparator {{VERSION}}

**Date de release** : {{DATE}}  
**Commit** : `{{COMMIT_SHA}}`

---

## 🎯 À propos de cette version

Cette release automatique contient la dernière version du script de préparation de cartes SD pour Ewon Flexy avec génération dynamique de configuration.

### 📝 Dernier changement
```
{{COMMIT_MSG}}
```

---

## 📥 Téléchargement

Téléchargez le fichier **`PrepareEwonSD_latest.ps1`** ci-dessous.

### 🚀 Installation rapide

1. **Télécharger** le script `PrepareEwonSD_latest.ps1`
2. **Clic-droit** → **Exécuter avec PowerShell**
3. **Suivre** les instructions à l'écran

### Probleme de politique d'execution ?

Si vous obtenez l'erreur **"l'execution de scripts est desactivee sur ce systeme"**, utilisez cette commande dans PowerShell :

```powershell
powershell -ExecutionPolicy Bypass -File ".\PrepareEwonSD_latest.ps1"
```

Cette commande execute le script en contournant temporairement la restriction, sans modifier les parametres systeme.

---

## ✨ Fonctionnalités principales

### 🔄 Génération dynamique
- ✅ Configuration créée à la volée selon vos paramètres
- ✅ Suppression automatique des paramètres inutilisés (4G vs Ethernet vs Datalogger)
- ✅ Validation intelligente des entrées (IP, PIN, etc.)

### 💾 Modes disponibles
- **ONLINE** : Téléchargement à la demande
- **CACHE** : Utilisation hors-ligne
- **PREPARATION** : Téléchargement complet pour usage futur

### 🔐 Sécurité
- Aucune donnée sensible stockée
- Saisie masquée des mots de passe
- Clés Talk2M demandées à chaque utilisation

---

## 📋 Configuration requise

| Composant | Minimum |
|-----------|---------|
| **Windows** | 10/11 ou Server 2016+ |
| **PowerShell** | 5.1 (inclus) |
| **Carte SD** | FAT32, max 128 Go |
| **Internet** | Pour modes ONLINE et PREPARATION |

---

## 🔧 Paramètres collectés

### Communs (toujours demandés)
- IP LAN et masque de sous-réseau
- Identification de l'Ewon
- Serveur NTP et timezone
- Mot de passe administrateur
- Compte et autorisation data

### Spécifiques Ethernet
- Mode DHCP ou IP statique
- Configuration WAN (si IP statique)
- Serveurs DNS

### Spécifiques 4G
- Code PIN de la carte SIM
- APN et identifiants

### Spécifiques Datalogger (LAN uniquement)
- Passerelle LAN (EthGW)
- Serveurs DNS (EthDns1, EthDns2)
- NTP : fr.pool.ntp.org (pas de Talk2M)

---

## 🐛 Support

En cas de problème :
1. Vérifiez que vous utilisez la dernière version
2. Consultez la [documentation](../../README.md)
3. Ouvrez une [issue](../../issues) si nécessaire

---

## 📄 Checksums

Les checksums SHA256 sont disponibles dans le fichier `SHA256SUMS.txt` joint à cette release.

Pour vérifier l'intégrité sous Windows PowerShell :
```powershell
Get-FileHash PrepareEwonSD_latest.ps1 -Algorithm SHA256
```

---

## ⚠️ Note importante

Ce script est destiné à un **usage professionnel** par les équipes Clauger et leurs clients autorisés.

---

*Release automatique générée par GitHub Actions*