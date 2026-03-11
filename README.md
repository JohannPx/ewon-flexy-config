# 🛠️ Ewon Flexy SD Preparator

[![GitHub Release](https://img.shields.io/github/v/release/JohannPx/ewon-flexy-config?label=latest)](https://github.com/JohannPx/ewon-flexy-config/releases/latest)
[![License](https://img.shields.io/badge/license-Proprietary-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)

> Solution professionnelle pour la préparation automatisée de cartes SD Ewon Flexy avec interface graphique WPF et génération dynamique de configurations personnalisées.

---

## ✨ Nouveautés v5.2

- 📦 **Exécutable Windows** : Distribution en `.exe` auto-installable (sans droits admin) avec mises à jour automatiques depuis GitHub
- 🔄 **Auto-update silencieux** : Vérification et mise à jour automatique à chaque démarrage
- 🏷️ **Releases versionnées** : Tags semver (`v5.2.0`), pre-releases sur branche `dev` pour tests avant production
- 🌍 **Multilingue** : Interface disponible en français, anglais, espagnol et italien (sélection par drapeaux)
- 🖥️ **Interface graphique WPF** : Wizard 8 étapes avec icône SD personnalisée (titre + barre des tâches)
- 🧩 **Architecture modulaire** : Code restructuré en 9 modules spécialisés (+ Localization.ps1)
- ✅ **Validation temps réel** : Icônes de validation à côté de chaque champ, champs obligatoires en IP statique WAN
- 🔄 **Champs conditionnels** : Affichage/masquage dynamique selon les choix (DHCP/statique, proxy, etc.)
- 📦 **Cache intelligent** : Téléchargement automatique de tous les firmwares en arrière-plan (sans bloquer l'interface)
- 📄 **Archive tar robuste** : Génération fiable du backup.tar avec fallback POSIX intégré

---

## 🎯 Objectif

Automatiser la préparation des cartes SD pour configurer les passerelles **Ewon Flexy** utilisées dans les installations industrielles, avec :
- Configuration réseau (LAN/WAN)
- Mise à jour firmware
- Intégration Talk2M (accès distant)
- Paramétrage de la remontée de données

---

## 🚀 Guide de démarrage rapide

### 1️⃣ Téléchargement et installation

Rendez-vous dans **[Releases](../../releases/latest)** et téléchargez **`EwonFlexySdPrep.exe`**.

### 2️⃣ Exécution

**Double-cliquez** sur l'exécutable. Au premier lancement :
- L'application s'installe automatiquement dans votre profil utilisateur (aucun droit admin requis)
- Un raccourci est créé sur le **Bureau** et dans le **Menu Démarrer**
- Les mises à jour sont vérifiées et appliquées silencieusement à chaque démarrage

> ⚠️ **Windows SmartScreen** : au premier lancement, Windows peut afficher "Windows a protégé votre ordinateur". Cliquez sur **Plus d'infos** → **Exécuter quand même**.

<details>
<summary>🔽 Option avancée : Script PowerShell (.ps1)</summary>

Pour les environnements qui bloquent les exécutables non signés, téléchargez `PrepareEwonSD_latest.ps1` et lancez :

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\PrepareEwonSD_latest.ps1"
```
</details>

### 3️⃣ Suivre le wizard

L'assistant graphique vous guide en 8 étapes :
1. **Mode & Firmware** : Online/Cache/Préparation + sélection firmware
2. **Type de connexion** : Modem 4G / Ethernet / Datalogger
3. **Paramètres réseau** : Configuration spécifique au type de connexion
4. **Paramètres communs** : IP LAN, NTP, timezone, mots de passe...
5. **Talk2M** : Clé d'enregistrement et description (sauf Datalogger)
6. **Lecteur SD** : Sélection du lecteur amovible
7. **Résumé** : Vérification avant génération
8. **Génération** : Progression et log en temps réel

---

## 🔧 Fonctionnalités principales

### 🌍 Multilingue (FR/EN/ES/IT)

- Sélection de la langue via drapeaux en haut de la première page
- Changement instantané de tous les textes, labels, messages et procédures
- Fallback automatique vers le français si une traduction manque

### 🖥️ Interface WPF

- Fenêtre wizard avec navigation Précédent/Suivant
- Icône SD personnalisée dans la barre de titre et la barre des tâches Windows
- Barre de progression par étape
- Champs générés dynamiquement depuis les définitions de paramètres
- Validation en temps réel avec indicateurs visuels (✔/✘)
- Champs IP WAN obligatoires en mode statique Ethernet
- Visibilité conditionnelle des champs (ex: DHCP masque les champs IP statiques)

### 📦 Cache intelligent

- Détection automatique de la connectivité au lancement
- Téléchargement en arrière-plan de tous les firmwares disponibles (sans bloquer l'UI)
- Affichage de la progression du cache dans la bannière de statut
- Les firmwares déjà en cache ne sont pas retéléchargés

### 📊 Génération dynamique de configuration

Le script génère automatiquement un `backup.tar` personnalisé basé sur :

| Type | Paramètres demandés |
|------|-------------------|
| **Communs** | IP LAN, masque, identification Ewon, serveur NTP, timezone, mot de passe admin, compte MyPortal3E |
| **Ethernet** | Mode DHCP/Static, IP WAN, passerelle, DNS (si IP statique), Proxy HTTP (optionnel) |
| **4G** | Code PIN, APN, identifiants APN |
| **Datalogger** | Passerelle LAN, DNS (communication via LAN uniquement, pas de Talk2M) |

### 🧹 Optimisation automatique

- Les paramètres **Ethernet** sont automatiquement supprimés pour une config **4G**
- Les paramètres **4G** sont automatiquement supprimés pour une config **Ethernet**
- Les paramètres **4G** et **Ethernet WAN** sont automatiquement supprimés pour une config **Datalogger**
- Résultat : des fichiers de configuration propres et optimisés

### 💾 Trois modes d'utilisation

| Mode | Description | Connexion Internet |
|------|-------------|-------------------|
| **ONLINE** | Télécharge les ressources à la demande | ✅ Requise |
| **CACHE** | Utilise les ressources déjà téléchargées | ❌ Non requise |
| **PREPARATION** | Télécharge tout pour usage ultérieur offline | ✅ Requise (une fois) |

---

## 📋 Prérequis système

| Composant | Minimum requis |
|-----------|---------------|
| **OS** | Windows 10/11 ou Windows Server 2016+ |
| **PowerShell** | 5.1 (inclus dans Windows) |
| **Carte SD** | FAT32, max 128 Go |
| **Espace disque** | 500 Mo pour le cache complet |

> **Aucune dépendance externe** : WPF est inclus nativement dans .NET Framework sur Windows.

---

## 🔐 Sécurité et confidentialité

### ✅ Ce qui est sécurisé

- **Talk2M** : Les clés sont demandées à chaque exécution, jamais stockées
- **Mots de passe** : Saisie masquée (PasswordBox WPF), non affichés dans les logs
- **Cache local** : Stocké dans `%APPDATA%\EwonFlexConfig`

### ⚠️ Points d'attention

- Les templates contiennent des placeholders, pas de données sensibles
- Le manifest.json est public (aucune donnée confidentielle)
- Les firmwares sont téléchargés depuis les serveurs HMS officiels

---

## 🗂️ Structure du projet

```
ewon-flexy-config/
├── 📜 scripts/
│   ├── Prepare_Ewon_SD.ps1         # Point d'entrée PowerShell
│   ├── GenerateIcon.ps1            # Génération icône .ico (utilisé par le CI)
│   └── modules/
│       ├── AppState.ps1             # État central (hashtable partagée)
│       ├── Localization.ps1         # i18n FR/EN/ES/IT (~160 clés × 4 langues)
│       ├── Validation.ps1           # Validateurs (IPv4, PIN, entier...)
│       ├── Config.ps1               # Définitions paramètres, conditions
│       ├── Network.ps1              # Téléchargements, cache, TLS
│       ├── Firmware.ps1             # Versions firmware, compatibilité, cache async
│       ├── Generator.ps1            # Templates, tar, T2M, procédure
│       ├── UIHelpers.ps1            # Création dynamique de champs WPF
│       └── UI.ps1                   # XAML wizard, événements, drapeaux
├── 🔧 wrapper/                      # Wrapper C# .NET 8
│   ├── EwonFlexySdPrep.csproj      # Projet (self-contained, single-file)
│   └── Program.cs                   # Auto-install, auto-update, lance le .ps1
├── 📝 templates/                    # Templates de configuration
│   ├── program.bas                  # Script BASIC Ewon
│   ├── comcfg.txt                   # Configuration communication
│   └── config.txt                   # Configuration système
├── 📋 manifest.json                 # Métadonnées et versions (source de vérité)
├── 📋 CLAUDE.md                     # Configuration Claude Code
└── 📚 .github/
    ├── workflows/
    │   └── build-release.yml        # CI/CD (3 jobs : build → package → release)
    └── release-body.md              # Template notes de version
```

### 🔨 Build CI/CD

Le workflow GitHub Actions s'exécute sur push vers `main` ou `dev` en 3 jobs :

1. **Build** (Ubuntu) : Concatène les 9 modules PowerShell en un fichier unique `PrepareEwonSD_latest.ps1` avec BOM UTF-8
2. **Package** (Windows) : Génère l'icône, compile le wrapper C# via `dotnet publish` → `EwonFlexySdPrep.exe` (self-contained, single-file, trimmed)
3. **Release** : Publie une release GitHub avec les 2 assets (.exe + .ps1)

| Branche | Type de release | Tag | Auto-update |
|---------|----------------|-----|-------------|
| `main` | Stable | `v5.2.0` | Oui (utilisateurs en production) |
| `dev` | Pre-release | `v5.2.0-dev.42` | Non (ignoré par `/releases/latest`) |

En développement local, le launcher détecte le dossier `modules/` et charge les fichiers individuellement via dot-sourcing.

---

## 🔄 Workflow de configuration

```mermaid
graph TD
    A[Lancement script] --> B{Choix mode}
    B -->|Online| C[Télécharge templates]
    B -->|Cache| D[Charge cache local]
    B -->|Preparation| E[Télécharge tout]

    C --> F[Sélection connexion]
    D --> F

    F -->|Ethernet| G[Paramètres Ethernet]
    F -->|4G| H[Paramètres 4G]
    F -->|Datalogger| DL[Paramètres Datalogger]

    %% Ethernet dynamique
    G --> I{Valeur de UseBOOTP2}
    I -->|0 - Statique| J[EthIpAddr2, EthIpMask2, EthGW, EthDns1, EthDns2 utilisés]
    I -->|2 - DHCP| K[EthIpAddr2, EthIpMask2, EthGW, EthDns1, EthDns2 supprimés]

    %% 4G dynamique
    H --> L[PIN, APN, identifiants]

    %% Datalogger dynamique
    DL --> DLP[EthGW, EthDns1, EthDns2 - LAN uniquement]
    DLP --> DLN[NtpServerAddr = fr.pool.ntp.org]
    DLN --> DLT[Pas de Talk2M]

    %% Paramètre program.bas
    F --> M[Paramètres communs - LAN IP, Identification, NTP, Timezone, Password]
    M --> N[program.bas - accountName, accountAuthorization]

    %% Lien vers PrgAutorun
    N --> O{accountAuthorization vide ?}
    O -->|Non vide| P[PrgAutorun = 1]
    O -->|Vide| Q[PrgAutorun = 0]

    %% Convergence
    J --> R[Génération backup.tar]
    K --> R
    L --> R
    DLT --> R
    P --> R
    Q --> R

    R --> S[Écriture SD]
    S --> T[Procédure générée]

```

---

## 💬 Support et contribution

### 🐛 Signaler un problème

Utilisez l'onglet [Issues](../../issues) avec les informations suivantes :
- Version du script utilisée
- Mode sélectionné (Online/Cache/Preparation)
- Type de connexion (4G/Ethernet/Datalogger)
- Message d'erreur complet (capture d'écran de la boîte d'erreur)

### 🤝 Contribuer

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/AmazingFeature`)
3. Committez (`git commit -m 'feat: Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

---

## 📜 Historique des versions

| Version | Date | Changements |
|---------|------|-------------|
| **v5.2.0** | 2026-03 | Exe Windows auto-installable, auto-update GitHub, wrapper C# .NET 8, CI versionnée, pre-releases dev |
| **v5.1.0** | 2026-02 | Multilingue FR/EN/ES/IT, cache async firmware, icône app, validation obligatoire IP WAN, tar robuste |
| **v5.0.0** | 2026-02 | Interface WPF wizard, architecture modulaire 8 modules, validation temps réel |
| **v2.0.0** | 2025-01 | Génération dynamique, suppression lignes inutilisées |
| **v1.1.0** | 2025-01 | Mode preparation, cache local |
| **v1.0.0** | 2024-12 | Version initiale |

---

## 🏢 Informations légales

**© 2026 Clauger** - Tous droits réservés
Usage réservé aux équipes Clauger et clients autorisés

**Documentation Ewon** : [HMS Networks](https://www.hms-networks.com/)
