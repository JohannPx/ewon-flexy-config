# 🛠️ Ewon Flexy SD Preparator

Outil PowerShell pour préparer une carte SD d’Ewon Flexy avec les configurations nécessaires.

---

## 🚀 Fonctionnalités

- 📥 Téléchargement automatique des firmwares HMS depuis les sources officielles  
- 💾 Mise en cache local pour un usage hors-ligne (mode PREPARATION)  
- 🌐 Choix du profil réseau (Ethernet ou 4G)  
- 📝 Génération automatique de la procédure utilisateur (fichier texte)  
- 🔑 Demande de la clé Talk2M (**T2MKey**) et de la note associée (**T2MNote**) au moment de la préparation  
  (jamais stockées dans le repo ni en cache)

---

## 📦 Installation et utilisation

1. Rendez-vous dans l’onglet **[Releases](../../releases)** du dépôt.  
2. Téléchargez la dernière version du script :  
   - `PrepareEwonSD_vX.Y.Z.ps1`  
3. Dans l’Explorateur Windows :  
   - Faites un **clic-droit** sur le fichier  
   - Sélectionnez **Exécuter avec PowerShell**

---

## 🔑 Données Talk2M

Lors de la préparation, l’outil vous demandera :  

- **T2MKey** (exemple : `A01-40D4CD3FA58B51620E28902334F8CE00`)  
- **T2MNote** (exemple : `Auto-registered Ewons from Clauger`)  

Ces données sont saisies par l’utilisateur et **ne sont jamais stockées** sur GitHub ni dans le cache local.

---

## 🛠️ Modes disponibles

- **Mode 1 – ONLINE** : télécharge les ressources depuis Internet  
- **Mode 2 – CACHE** : utilise les fichiers déjà téléchargés  
- **Mode 3 – PREPARATION** : télécharge **tous les firmwares** pour un usage hors ligne

---

## 📝 Notes

- ✅ Compatible **Windows PowerShell 5.1** (installé par défaut sur Windows)  
- 💽 Carte SD supportée : **FAT32**, capacité maximale **128 Go**  
- 🌍 Internet requis pour les modes ONLINE et PREPARATION

---

## 🔒 Sécurité

- 🔐 Aucune donnée sensible n’est versionnée dans ce dépôt  
- 🔑 Les identifiants Talk2M (**T2MKey**, **T2MNote**) sont demandés à l’utilisateur uniquement  
- 📜 Distribution en **`.ps1`** → pas de faux positifs antivirus liés aux `.exe`

---

## 📄 Licence

© 2025 Clauger – Usage interne et auprès des clients Clauger
