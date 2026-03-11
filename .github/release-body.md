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

## 📥 Téléchargement et installation

### 🔽 Option recommandée : Exécutable (.exe)

1. **Télécharger** le fichier **`EwonFlexySdPrep.exe`** depuis les **Assets** ci-dessous
2. **Double-cliquer** pour lancer

Au premier lancement :
- L'application s'installe automatiquement dans votre profil utilisateur (aucun droit administrateur requis)
- Un raccourci est créé sur le **Bureau** et dans le **Menu Démarrer**
- Les lancements suivants se font via le raccourci

**Mises à jour automatiques** : à chaque démarrage, l'application vérifie si une nouvelle version est disponible sur GitHub et se met à jour silencieusement.

> **Avertissements de sécurité au premier téléchargement/lancement :**
>
> 1. **Navigateur** (Chrome/Edge) : *"EwonFlexySdPrep.exe n'est pas fréquemment téléchargé"*
>    - Chrome : cliquez sur **`^`** (flèche) → **Conserver**
>    - Edge : cliquez sur **`...`** → **Conserver** → **Conserver quand même**
>
> 2. **Windows SmartScreen** : *"Windows a protégé votre ordinateur"*
>    - Cliquez sur **Plus d'infos** → **Exécuter quand même**
>
> Ces avertissements sont normaux pour un exécutable non signé et n'apparaissent qu'au premier téléchargement.

### 🔽 Option avancée : Script PowerShell (.ps1)

Pour les utilisateurs avancés ou les environnements qui bloquent les exécutables non signés :

1. **Télécharger** le fichier `PrepareEwonSD_latest.ps1` depuis les **Assets** ci-dessous
2. **Ouvrir PowerShell** : clic-droit sur le menu Démarrer → **Terminal**
3. **Lancer** :

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\PrepareEwonSD_latest.ps1"
```

> 💡 Adaptez le chemin si vous avez déplacé le fichier.

---

## ✨ Fonctionnalités principales

### 🌍 Multilingue (FR/EN/ES/IT)
- ✅ Sélection de la langue via drapeaux sur la première page
- ✅ Changement instantané de toute l'interface

### 🖥️ Interface graphique WPF
- ✅ Wizard 8 étapes avec navigation Précédent/Suivant
- ✅ Validation temps réel avec indicateurs visuels
- ✅ Champs conditionnels dynamiques

### 📦 Cache intelligent
- ✅ Téléchargement automatique de tous les firmwares en arrière-plan
- ✅ Interface réactive pendant le cache (runspace asynchrone)

### 🔄 Génération dynamique
- ✅ Configuration créée à la volée selon vos paramètres
- ✅ Génération tar robuste avec fallback POSIX intégré

### 💾 Modes disponibles
- **ONLINE** : Téléchargement à la demande
- **CACHE** : Utilisation hors-ligne
- **PREPARATION** : Téléchargement complet pour usage futur

---

## 📋 Configuration requise

| Composant | Minimum |
|-----------|---------|
| **Windows** | 10/11 ou Server 2016+ |
| **PowerShell** | 5.1 (inclus) |
| **Carte SD** | FAT32, max 128 Go |
| **Internet** | Pour modes ONLINE et PREPARATION |

---

## 🐛 Support

En cas de problème :
1. Vérifiez que vous utilisez la dernière version
2. Consultez la [documentation](../../README.md)
3. Ouvrez une [issue](../../issues) avec une capture d'écran de l'erreur

---

## ⚠️ Note importante

Ce script est destiné à un **usage professionnel** par les équipes Clauger et leurs clients autorisés.

---

*Release automatique générée par GitHub Actions*
