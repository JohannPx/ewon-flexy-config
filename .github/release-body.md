# 📦 Ewon Flexy SD Preparator {{VERSION}}

**Date de release** : {{DATE}}
**Commit** : `{{COMMIT_SHA}}`

---

## 🎯 À propos de cette version

Cette release contient la dernière version du script de préparation de cartes SD pour Ewon Flexy avec **interface graphique WPF** (wizard 8 étapes) et génération dynamique de configuration.

### 📝 Dernier changement
```
{{COMMIT_MSG}}
```

---

## 📥 Téléchargement

Téléchargez le fichier **`PrepareEwonSD_latest.ps1`** ci-dessous.

> **Fichier unique auto-contenu** : les 8 modules sont intégrés dans le script lors du build. Aucune dépendance externe, PowerShell 5.1 natif Windows suffit.

### 🚀 Installation rapide

1. **Télécharger** le script `PrepareEwonSD_latest.ps1`
2. **Clic-droit** → **Exécuter avec PowerShell**
3. **Suivre** le wizard graphique (8 étapes)

### Probleme de politique d'execution ?

Si vous obtenez l'erreur **"l'execution de scripts est desactivee sur ce systeme"**, utilisez cette commande dans PowerShell :

```powershell
powershell -ExecutionPolicy Bypass -File ".\PrepareEwonSD_latest.ps1"
```

Cette commande execute le script en contournant temporairement la restriction, sans modifier les parametres systeme.

---

## ✨ Fonctionnalités principales

### 🖥️ Interface graphique WPF
- ✅ Wizard 8 étapes avec navigation Précédent/Suivant
- ✅ Validation temps réel avec indicateurs visuels (✔/✘)
- ✅ Champs conditionnels dynamiques (DHCP masque les champs IP, proxy conditionnel...)
- ✅ Barre de progression et log de génération en temps réel

### 🔄 Génération dynamique
- ✅ Configuration créée à la volée selon vos paramètres
- ✅ Suppression automatique des paramètres inutilisés (4G vs Ethernet vs Datalogger)
- ✅ Procédure détaillée générée automatiquement

### 💾 Modes disponibles
- **ONLINE** : Téléchargement à la demande
- **CACHE** : Utilisation hors-ligne
- **PREPARATION** : Téléchargement complet pour usage futur

### 🔐 Sécurité
- Aucune donnée sensible stockée
- Saisie masquée des mots de passe (PasswordBox WPF)
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
- Compte et autorisation MyPortal3E

### Spécifiques Ethernet
- Mode DHCP ou IP statique
- Configuration WAN (si IP statique)
- Serveurs DNS
- Proxy HTTP (optionnel : sans auth, basic auth, NTLM)

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
3. Ouvrez une [issue](../../issues) avec une capture d'écran de l'erreur

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
