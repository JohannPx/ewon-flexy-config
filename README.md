# Ewon Flexy SD Preparator

Outil pour préparer une carte SD d’Ewon Flexy avec les configurations nécessaires.

## 🚀 Fonctionnalités

- Téléchargement automatique des firmwares HMS depuis les sources officielles  
- Mise en cache local pour un usage hors-ligne (mode PREPARATION)  
- Choix du profil réseau (Ethernet ou 4G)  
- Génération automatique de la procédure utilisateur (fichier texte)  
- Demande de la clé Talk2M (**T2MKey**) et de la note associée (**T2MNote**) au moment de la préparation (jamais stockées dans le repo ni en cache)

## 📦 Installation et utilisation

### Option 1 : Exécutable Windows (`.exe`)
1. Rendez-vous dans l’onglet **[Releases](../../releases)** du dépôt.  
2. Téléchargez la dernière version :  
   - `PrepareEwonSD_vX.Y.Z.exe`  
3. Double-cliquez sur l’exécutable pour lancer l’outil.

⚠️ **Note antivirus** : certains antivirus peuvent bloquer le `.exe` généré automatiquement par GitHub Actions (faux positif).  
Si c’est le cas, utilisez **l’Option 2** ci-dessous.

---

### Option 2 : Script PowerShell (`.ps1`) avec lanceur `.bat`
1. Téléchargez l’archive ZIP depuis la Release :  
   - `PrepareEwonSD_vX.Y.Z.zip`  
2. Décompressez le dossier sur votre poste.  
3. Double-cliquez sur `run.bat`.  
   - Cela ouvrira une console PowerShell et exécutera `Prepare_Ewon_SD.ps1`.  

---

## 🔑 Données Talk2M

Lors de la préparation, l’outil vous demandera :  
- **T2MKey** (exemple : `A01-40D4CD3FA58B51620E28902334F8CE00`)  
- **T2MNote** (exemple : `Auto-registered Ewons from Clauger`)  

Ces informations sont saisies par l’utilisateur au moment de la préparation et **ne sont jamais stockées sur GitHub**.

---

## 🛠️ Modes disponibles

- **Mode 1 - ONLINE** : télécharge les ressources depuis Internet  
- **Mode 2 - CACHE** : utilise les fichiers déjà téléchargés  
- **Mode 3 - PREPARATION** : télécharge **tous les firmwares** et crée un cache complet pour une utilisation future hors ligne

---

## 📝 Notes

- Script compatible **Windows PowerShell 5.1** (lancé automatiquement par l’EXE ou le batch).  
- Nécessite un accès Internet en mode ONLINE ou PREPARATION.  
- Carte SD supportée : FAT32, max 128 Go.  

---

## 🔒 Sécurité

- **Aucune donnée sensible n’est versionnée dans ce dépôt.**  
- Les identifiants Talk2M (**T2MKey**, **T2MNote**) sont demandés à l’utilisateur et jamais sauvegardés ni sur GitHub, ni dans le cache local.  
- L’EXE distribué par GitHub n’est pas signé → possibilité de faux positifs antivirus. Une signature de code est en cours d’étude avec l’IT.

---

## 📄 Licence

© 2025 Clauger. Utilisation interne et avec les clients Clauger.
