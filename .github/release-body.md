# 📦 Ewon Flexy SD Preparator {{VERSION}}

**Date de release** : {{DATE}}
**Commit** : `{{COMMIT_SHA}}`

---

## 🎯 À propos de cette version

Cette release contient la dernière version du script de préparation de cartes SD pour Ewon Flexy avec **interface graphique WPF multilingue** (wizard 8 étapes, FR/EN/ES/IT) et génération dynamique de configuration.

### 📝 Dernier changement
```
{{COMMIT_MSG}}
```

---

## 📥 Téléchargement

> **Fichier unique auto-contenu** : les 9 modules sont intégrés dans le script lors du build. Aucune dépendance externe, PowerShell 5.1 natif Windows suffit.

### 🔽 Où trouver le fichier ?

Le fichier **`PrepareEwonSD_latest.ps1`** se trouve dans la section **Assets** tout en bas de cette page (cliquez sur **▶ Assets** pour déplier si nécessaire).

### 🚀 Installation rapide

1. **Télécharger** le fichier `PrepareEwonSD_latest.ps1` depuis les **Assets** ci-dessous
2. **Clic-droit** sur le fichier téléchargé → **Exécuter avec PowerShell**
3. **Suivre** le wizard graphique (8 étapes)

### 🔒 Avertissement de sécurité Windows

Au premier lancement, Windows affiche un **"Avertissement de sécurité"** car le script provient d'Internet :

```
Avertissement de sécurité
N'exécutez que des scripts que vous approuvez. [...]
Voulez-vous exécuter C:\...\PrepareEwonSD_latest.ps1 ?
[N] Ne pas exécuter  [O] Exécuter une fois  [S] Suspendre  [?] Aide
```

**➜ Tapez `O` puis Entrée** pour exécuter le script. C'est un comportement normal de Windows pour tout script téléchargé depuis Internet. Le script ne modifie aucun paramètre système et ne contient aucun code malveillant — il se contente de préparer la carte SD.

> 💡 **Astuce** : Pour ne plus voir cet avertissement, faites clic-droit sur le fichier → **Propriétés** → cochez **Débloquer** en bas de la fenêtre → **OK**.

### Problème de politique d'exécution ?

Si vous obtenez l'erreur **"l'exécution de scripts est désactivée sur ce système"** au lieu de l'avertissement ci-dessus, utilisez cette commande dans PowerShell :

```powershell
powershell -ExecutionPolicy Bypass -File ".\PrepareEwonSD_latest.ps1"
```

Cette commande exécute le script en contournant temporairement la restriction, sans modifier les paramètres système.

---

## ✨ Fonctionnalités principales

### 🌍 Multilingue (FR/EN/ES/IT)
- ✅ Sélection de la langue via drapeaux sur la première page
- ✅ Changement instantané de toute l'interface (labels, messages, procédures)
- ✅ Fallback automatique vers le français

### 🖥️ Interface graphique WPF
- ✅ Wizard 8 étapes avec navigation Précédent/Suivant
- ✅ Icône SD personnalisée (barre de titre + barre des tâches)
- ✅ Validation temps réel avec indicateurs visuels (✔/✘)
- ✅ Champs IP WAN obligatoires en mode statique Ethernet
- ✅ Champs conditionnels dynamiques (DHCP masque les champs IP, proxy conditionnel...)
- ✅ Barre de progression et log de génération en temps réel

### 📦 Cache intelligent
- ✅ Téléchargement automatique de tous les firmwares en arrière-plan
- ✅ Interface réactive pendant le cache (runspace asynchrone)
- ✅ Progression affichée dans la bannière de statut

### 🔄 Génération dynamique
- ✅ Configuration créée à la volée selon vos paramètres
- ✅ Suppression automatique des paramètres inutilisés (4G vs Ethernet vs Datalogger)
- ✅ Génération tar robuste avec fallback POSIX intégré
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
