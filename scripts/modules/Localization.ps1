# Localization.ps1 - Multi-language support (FR, EN, ES, IT)

$Script:CurrentLanguage = "FR"

$Script:Strings = @{
    # ============================================================
    # FRANCAIS
    # ============================================================
    "FR" = @{
        # --- Navigation & Window ---
        WindowTitle       = "Préparation Carte SD Ewon Flexy"
        BtnCancel         = "Annuler"
        BtnPrevious       = "$([char]0x25C0) Précédent"
        BtnNext           = "Suivant $([char]0x25B6)"
        BtnGenerate       = "Générer"
        BtnClose          = "Fermer"
        StepTitleFormat   = "Étape {0} / {1} - {2}"
        LangLabel         = "Langue :"

        # --- Step Titles ---
        Step0Title = "Mode et Firmware"
        Step1Title = "Type de connexion"
        Step2Title = "Paramètres réseau WAN"
        Step3Title = "Paramètres communs"
        Step4Title = "Identifiants Talk2M"
        Step5Title = "Sélection lecteur SD"
        Step6Title = "Résumé"
        Step7Title = "Génération"

        # --- Step 0: Mode + Firmware ---
        ModeTitle         = "Mode et Firmware"
        ConnChecking      = "Vérification de la connexion Internet..."
        ConnCaching       = "Connexion Internet disponible — préparation du cache hors-ligne..."
        ConnCachingFw     = "Téléchargement firmware {0} en arrière-plan..."
        ConnOnlineOk      = "Connexion Internet disponible — mode ONLINE sélectionné."
        ConnCacheOk       = "Pas de connexion Internet. Cache disponible — mode CACHE sélectionné."
        ConnNoConnection  = "Pas de connexion Internet et aucun cache disponible. La préparation de carte SD est impossible. Connectez-vous à Internet et relancez l'application."
        FwTitle           = "Firmware"
        FwHelpText        = "Les Ewon Flexy produits depuis 2026 (n° de série >= 2601) sont livrés en firmware 15.x ou supérieur."
        FwCurrentLabel    = "Firmware actuel :"
        FwTargetLabel     = "Firmware cible :"
        FwSkipLabel       = "Configuration uniquement (pas de mise à jour firmware)"

        # --- Step 1: Connection Type ---
        ConnTypeTitle     = "Type de connexion"
        ConnTypeSubtitle  = "Choisissez le mode de communication de l'Ewon Flexy."
        Conn4G            = "Modem 4G"
        Conn4GDesc        = "Connexion cellulaire via carte SIM"
        ConnEthernet      = "Ethernet"
        ConnEthernetDesc  = "Connexion filaire (DHCP ou IP statique, proxy optionnel)"
        ConnDatalogger    = "Datalogger (LAN uniquement)"
        ConnDataloggerDesc = "Communication via LAN, pas de Talk2M"

        # --- Step 2: Network Parameters ---
        NetTitle          = "Paramètres réseau WAN"
        NetSubtitle4G     = "Paramètres du modem 4G"
        NetSubtitleEth    = "Paramètres réseau WAN Ethernet"
        NetSubtitleDL     = "Paramètres Datalogger (LAN uniquement)"
        NetSubtitleDefault = "Configurez les paramètres réseau."

        # --- Step 3: Common Parameters ---
        CommonTitle       = "Paramètres communs"
        CommonSubtitle    = "Ces paramètres sont utilisés quel que soit le type de connexion."

        # --- Step 4: Talk2M ---
        T2MTitle          = "Identifiants Talk2M"
        T2MWarning        = "Ces données ne sont JAMAIS mises en cache."
        T2MKeyLabel       = "Clé globale d'enregistrement :"
        T2MNoteLabel      = "Description Ewon Talk2M :"

        # --- Step 5: SD Drive ---
        SDTitle           = "Sélection du lecteur SD"
        SDSubtitle        = "Insérez la carte SD puis sélectionnez le lecteur ci-dessous."
        SDRefresh         = "Actualiser les lecteurs"
        SDDriveInfo       = "Seuls les lecteurs amovibles sont affichés."
        SDNoDrive         = "Aucun lecteur amovible détecté. Insérez une carte SD et cliquez Actualiser."
        SDDriveCount      = "{0} lecteur(s) amovible(s) détecté(s)."

        # --- Step 6: Summary ---
        SummaryTitle      = "Résumé de la configuration"
        SummaryCheck      = "Vérifiez tous les paramètres avant de lancer la génération."
        SumMode           = "MODE"
        SumConnType       = "TYPE DE CONNEXION"
        SumFw             = "FIRMWARE"
        SumFwSkip         = "Configuration uniquement (pas de MAJ)"
        SumSD             = "LECTEUR SD"
        SumParams         = "--- Paramètres ---"
        SumT2M            = "--- Talk2M ---"

        # --- Step 7: Generation ---
        GenTitle          = "Génération en cours..."
        GenComplete       = "Génération terminée !"
        GenSuccess        = "PRÉPARATION TERMINÉE AVEC SUCCÈS"
        GenProcTitle      = "Procédure d'utilisation de la carte SD"
        PrepTitle         = "Préparation terminée !"
        PrepSuccess       = "PRÉPARATION TERMINÉE AVEC SUCCÈS"

        # --- Validation ---
        ValRequired       = "Valeur obligatoire."
        ValInvalidIP      = "Adresse IP invalide. Format: xxx.xxx.xxx.xxx"
        ValInvalidPIN     = "Code PIN invalide. 4 chiffres requis."
        ValInteger        = "Entier requis."
        ValMaxLength      = "24 caractères maximum."

        # --- Dialogs ---
        DlgGenInProgress  = "Une génération est en cours. Voulez-vous vraiment quitter ?"
        DlgConfirm        = "Confirmation"
        DlgValidation     = "Validation"
        DlgSelectCurrentFw = "Sélectionnez le firmware actuel."
        DlgSelectTargetFw = "Sélectionnez le firmware cible (ou cochez 'Configuration uniquement')."
        DlgT2MKeyRequired = "La clé globale d'enregistrement Talk2M est obligatoire."
        DlgT2MNoteRequired = "La description Ewon Talk2M est obligatoire."
        DlgSelectSD       = "Sélectionnez un lecteur SD."
        DlgQuit           = "Voulez-vous vraiment quitter ?"
        DlgError          = "Erreur"
        DlgNavError       = "Erreur navigation : {0}"

        # --- Progress & Generation ---
        ProgOnlineDownload = "Mode ONLINE — téléchargement des ressources..."
        ProgResourcesOk   = "[OK] Ressources téléchargées"
        ProgCacheUnavail   = "Cache non disponible"
        ProgPreparation    = "Mode PRÉPARATION — téléchargement de toutes les ressources..."
        ProgManifest       = "Récupération du manifest..."
        ProgManifestOk     = "[OK] Manifest sauvegardé"
        ProgManifestFail   = "Impossible de récupérer le manifest."
        ProgManifestFailOnline = "Impossible de récupérer le manifest en ligne."
        ProgTemplates      = "Téléchargement des templates..."
        ProgTemplateFail   = "Échec du téléchargement des templates."
        ProgFirmwares      = "Téléchargement des firmwares..."
        ProgDone           = "Terminé !"

        # --- Firmware ---
        FwCached          = "Firmware {0} déjà en cache"
        FwDownloading     = "Téléchargement firmware {0}..."
        FwEbuNote         = "Note: .ebu non disponible pour {0} (OK)"
        FwDownloaded      = "[OK] Firmware {0} téléchargé"
        FwMigration       = "Migration 14.x -> {0} : ewonfwr.ebus et ewonfwr.ebu"
        FwUpdateMsg       = "Mise à jour -> {0} : ewonfwr.ebus"
        FwCopied          = "+ {0} copié"
        FwFileMissing     = "! Fichier manquant: {0}"
        FwNotFound        = "Firmware non trouvé dans le cache: {0}"

        # --- Generator ---
        GenProcessing     = "Traitement de {0}..."
        GenRemoving       = "  Suppression : {0}"
        GenTemplateMissing = "Template manquant : {0}"
        GenFwDownloadFail = "Téléchargement firmware échoué."
        GenTarFail        = "Échec de la création de backup.tar"
        GenTarOk          = "[OK] backup.tar créé"
        GenT2MCleanup     = "Nettoyage T2M..."
        GenFwCopy         = "Copie des firmwares..."
        GenT2MWrite       = "Écriture T2M.txt..."
        GenT2MOk          = "[OK] T2M.txt écrit"
        GenVerify         = "Vérification des fichiers..."
        GenFileOk         = "[OK]"
        GenFileMissing    = "[MANQUANT]"
        GenFilesMissing   = "Fichiers manquants sur la SD."
        GenProcGen        = "Génération de la procédure..."
        GenProcSaved      = "[OK] Procédure sauvegardée : {0}"
        GenAutoParams     = "Calcul des paramètres automatiques..."
        GenDone           = "Terminé !"

        # --- Parameter Descriptions ---
        Desc_EthIP        = "Adresse IP"
        Desc_EthMask      = "Masque sous-réseau"
        Desc_Identification = "Nom de l'Ewon"
        Desc_NtpServer    = "Serveur"
        Desc_NtpPort      = "Port"
        Desc_Timezone     = "Fuseau horaire"
        Desc_Password     = "Mot de passe (max 24 car.)"
        Desc_AccountName  = "Nom du compte"
        Desc_AccountAuth  = "Autorisation"
        Desc_UseBOOTP2    = "Attribution IP"
        Desc_EthIpAddr2   = "Adresse IP"
        Desc_EthIpMask2   = "Masque sous-réseau"
        Desc_EthGW        = "Passerelle"
        Desc_EthDns1      = "DNS primaire"
        Desc_EthDns2      = "DNS secondaire"
        Desc_WANPxyMode   = "Mode"
        Desc_WANPxyAddr   = "Adresse"
        Desc_WANPxyPort   = "Port"
        Desc_WANPxyUsr    = "Utilisateur"
        Desc_WANPxyPass   = "Mot de passe"
        Desc_PIN          = "Code PIN (4 chiffres)"
        Desc_PdpApn       = "Nom du point d'accès"
        Desc_PPPUser      = "Utilisateur"
        Desc_PPPPass      = "Mot de passe"

        # --- Parameter Groups ---
        Group_LAN         = "Réseau LAN"
        Group_Identification = "Identification"
        Group_NTP         = "Temps (NTP)"
        Group_Security    = "Sécurité"
        Group_MyPortal    = "MyPortal3E"
        Group_WAN         = "Configuration IP WAN"
        Group_Proxy       = "Proxy HTTP"
        Group_SIM         = "Carte SIM"
        Group_APN         = "APN"
        Group_NetConfig   = "Configuration réseau"

        # --- Choice Labels ---
        Choice_Static     = "Statique"
        Choice_DHCP       = "DHCP"
        Choice_NoProxy    = "Sans proxy"
        Choice_BasicAuth  = "Basic auth"
        Choice_NTLMAuth   = "NTLM auth"
        Choice_NoAuth     = "Sans authentification"

        # --- UIHelpers ---
        DriveNoName       = "Sans nom"

        # --- Procedure Document ---
        Proc_Title        = "PROCÉDURE DÉTAILLÉE APRÈS PRÉPARATION DE LA CARTE SD"
        Proc_Separator    = "--------------------------------------------------"
        Proc_NoFwUpdate   = "CONFIGURATION SANS MISE À JOUR FIRMWARE"
        Proc_Intro        = "Configuration générée dynamiquement avec les paramètres suivants :"
        Proc_Step1Title   = "ÉTAPE 1 : PRÉPARATION"
        Proc_Step1_1      = "1. Dans Windows : faites un clic droit sur le lecteur SD et sélectionnez `"Éjecter`""
        Proc_Step1_2      = "2. Attendez que Windows confirme que vous pouvez retirer la carte en toute sécurité"
        Proc_Step1_3      = "3. Retirez physiquement la carte SD de votre ordinateur"
        Proc_Step2NoFwTitle = "ÉTAPE 2 : INSERTION DE LA CARTE (CONFIGURATION UNIQUEMENT)"
        Proc_Step2NoFw_1  = "1. Assurez-vous que l'Ewon Flexy est SOUS TENSION et que la LED USR clignote en VERT"
        Proc_Step2NoFw_2  = "2. Insérez la carte SD dans l'emplacement prévu sur l'Ewon"
        Proc_Step2NoFw_3  = "3. ATTENDEZ que la LED USR devienne VERT FIXE (cette étape peut prendre quelques minutes)"
        Proc_Step2NoFw_4  = "4. Lorsque la LED est VERT FIXE, retirez la carte SD"
        Proc_Step2NoFw_5  = "5. La configuration est terminée lorsque la LED USR revient à un clignotement VERT régulier"
        Proc_Step2FwTitle = "ÉTAPE 2 : PREMIÈRE INSERTION (MISE À JOUR DU FIRMWARE)"
        Proc_Step2Fw_1    = "1. Assurez-vous que l'Ewon Flexy est HORS TENSION"
        Proc_Step2Fw_2    = "2. Insérez la carte SD dans l'emplacement prévu sur l'Ewon"
        Proc_Step2Fw_3    = "3. Mettez l'Ewon sous tension"
        Proc_Step2Fw_4    = "4. ATTENDEZ que la LED USR devienne VERT FIXE (cette étape peut prendre plusieurs minutes)"
        Proc_Step2Fw_5    = "5. Lorsque la LED est VERT FIXE, retirez la carte SD"
        Proc_Step3FwTitle = "ÉTAPE 3 : DEUXIÈME INSERTION (CONFIGURATION)"
        Proc_Step3Fw_1    = "1. ATTENDEZ que la LED USR clignote en VERT (alternance 500ms allumée/500ms éteinte)"
        Proc_Step3Fw_2    = "2. Une fois que la LED clignote, réinsérez la carte SD"
        Proc_Step3Fw_3    = "3. ATTENDEZ à nouveau que la LED USR devienne VERT FIXE"
        Proc_Step3Fw_4    = "4. Lorsque la LED est VERT FIXE, retirez définitivement la carte SD"
        Proc_Step3Fw_5    = "5. La configuration est terminée lorsque la LED USR revient à un clignotement VERT régulier"
        Proc_RemoteTitle  = "DEMANDE D'ACCÈS À DISTANCE"
        Proc_Remote_Intro = "Transmettez aux administrateurs/configurateurs les informations suivantes :"
        Proc_Remote_1     = "- Numéro de série de l'Ewon"
        Proc_Remote_2     = "- Information carte SIM (si 4G)"
        Proc_Remote_3     = "- Identifiant IFS du site client"
        Proc_Remote_4     = "- Nom souhaité pour l'Ewon"
        Proc_DLTitle      = "VÉRIFICATION DE LA COMMUNICATION"
        Proc_DLText       = "L'Ewon communique via son interface LAN uniquement (pas de Talk2M). Vérifiez que l'Ewon peut atteindre le serveur push.myclauger.com via le réseau local."
        Proc_Conclusion   = "CONCLUSION"
        Proc_ConclusionNoFw = "Votre Ewon Flexy est maintenant configuré."
        Proc_ConclusionFw = "Votre Ewon Flexy est maintenant configuré et à jour."

        # --- Network module ---
        NetManifestRecover = "Récupération du manifest..."
        NetManifestCache  = "Manifest indisponible en ligne. Recherche en cache..."
        NetTemplateDownload = "Téléchargement template {0}..."
        NetTemplateOk     = "  [OK] {0}"
        ErrorPrefix       = "[ERREUR]"
        SizeUnitGB        = "Go"
    }

    # ============================================================
    # ENGLISH
    # ============================================================
    "EN" = @{
        # --- Navigation & Window ---
        WindowTitle       = "Ewon Flexy SD Card Preparation"
        BtnCancel         = "Cancel"
        BtnPrevious       = "$([char]0x25C0) Previous"
        BtnNext           = "Next $([char]0x25B6)"
        BtnGenerate       = "Generate"
        BtnClose          = "Close"
        StepTitleFormat   = "Step {0} / {1} - {2}"
        LangLabel         = "Language:"

        # --- Step Titles ---
        Step0Title = "Mode and Firmware"
        Step1Title = "Connection Type"
        Step2Title = "WAN Network Parameters"
        Step3Title = "Common Parameters"
        Step4Title = "Talk2M Credentials"
        Step5Title = "SD Drive Selection"
        Step6Title = "Summary"
        Step7Title = "Generation"

        # --- Step 0: Mode + Firmware ---
        ModeTitle         = "Mode and Firmware"
        ConnChecking      = "Checking Internet connection..."
        ConnCaching       = "Internet connection available — preparing offline cache..."
        ConnCachingFw     = "Downloading firmware {0} in background..."
        ConnOnlineOk      = "Internet connection available — ONLINE mode selected."
        ConnCacheOk       = "No Internet connection. Cache available — CACHE mode selected."
        ConnNoConnection  = "No Internet connection and no cache available. SD card preparation is not possible. Connect to the Internet and restart the application."
        FwTitle           = "Firmware"
        FwHelpText        = "Ewon Flexy units produced since 2026 (serial number >= 2601) ship with firmware 15.x or higher."
        FwCurrentLabel    = "Current firmware:"
        FwTargetLabel     = "Target firmware:"
        FwSkipLabel       = "Configuration only (no firmware update)"

        # --- Step 1: Connection Type ---
        ConnTypeTitle     = "Connection Type"
        ConnTypeSubtitle  = "Choose the Ewon Flexy communication mode."
        Conn4G            = "4G Modem"
        Conn4GDesc        = "Cellular connection via SIM card"
        ConnEthernet      = "Ethernet"
        ConnEthernetDesc  = "Wired connection (DHCP or static IP, optional proxy)"
        ConnDatalogger    = "Datalogger (LAN only)"
        ConnDataloggerDesc = "LAN communication, no Talk2M"

        # --- Step 2: Network Parameters ---
        NetTitle          = "WAN Network Parameters"
        NetSubtitle4G     = "4G modem parameters"
        NetSubtitleEth    = "Ethernet WAN network parameters"
        NetSubtitleDL     = "Datalogger parameters (LAN only)"
        NetSubtitleDefault = "Configure network parameters."

        # --- Step 3: Common Parameters ---
        CommonTitle       = "Common Parameters"
        CommonSubtitle    = "These parameters are used regardless of the connection type."

        # --- Step 4: Talk2M ---
        T2MTitle          = "Talk2M Credentials"
        T2MWarning        = "This data is NEVER cached."
        T2MKeyLabel       = "Global registration key:"
        T2MNoteLabel      = "Ewon Talk2M description:"

        # --- Step 5: SD Drive ---
        SDTitle           = "SD Drive Selection"
        SDSubtitle        = "Insert the SD card then select the drive below."
        SDRefresh         = "Refresh drives"
        SDDriveInfo       = "Only removable drives are shown."
        SDNoDrive         = "No removable drive detected. Insert an SD card and click Refresh."
        SDDriveCount      = "{0} removable drive(s) detected."

        # --- Step 6: Summary ---
        SummaryTitle      = "Configuration Summary"
        SummaryCheck      = "Review all parameters before starting generation."
        SumMode           = "MODE"
        SumConnType       = "CONNECTION TYPE"
        SumFw             = "FIRMWARE"
        SumFwSkip         = "Configuration only (no update)"
        SumSD             = "SD DRIVE"
        SumParams         = "--- Parameters ---"
        SumT2M            = "--- Talk2M ---"

        # --- Step 7: Generation ---
        GenTitle          = "Generation in progress..."
        GenComplete       = "Generation complete!"
        GenSuccess        = "PREPARATION COMPLETED SUCCESSFULLY"
        GenProcTitle      = "SD card usage procedure"
        PrepTitle         = "Preparation complete!"
        PrepSuccess       = "PREPARATION COMPLETED SUCCESSFULLY"

        # --- Validation ---
        ValRequired       = "Required value."
        ValInvalidIP      = "Invalid IP address. Format: xxx.xxx.xxx.xxx"
        ValInvalidPIN     = "Invalid PIN code. 4 digits required."
        ValInteger        = "Integer required."
        ValMaxLength      = "24 characters maximum."

        # --- Dialogs ---
        DlgGenInProgress  = "A generation is in progress. Do you really want to quit?"
        DlgConfirm        = "Confirmation"
        DlgValidation     = "Validation"
        DlgSelectCurrentFw = "Select the current firmware."
        DlgSelectTargetFw = "Select the target firmware (or check 'Configuration only')."
        DlgT2MKeyRequired = "The Talk2M global registration key is required."
        DlgT2MNoteRequired = "The Ewon Talk2M description is required."
        DlgSelectSD       = "Select an SD drive."
        DlgQuit           = "Do you really want to quit?"
        DlgError          = "Error"
        DlgNavError       = "Navigation error: {0}"

        # --- Progress & Generation ---
        ProgOnlineDownload = "ONLINE mode — downloading resources..."
        ProgResourcesOk   = "[OK] Resources downloaded"
        ProgCacheUnavail   = "Cache unavailable"
        ProgPreparation    = "PREPARATION mode — downloading all resources..."
        ProgManifest       = "Retrieving manifest..."
        ProgManifestOk     = "[OK] Manifest saved"
        ProgManifestFail   = "Unable to retrieve the manifest."
        ProgManifestFailOnline = "Unable to retrieve the manifest online."
        ProgTemplates      = "Downloading templates..."
        ProgTemplateFail   = "Template download failed."
        ProgFirmwares      = "Downloading firmwares..."
        ProgDone           = "Done!"

        # --- Firmware ---
        FwCached          = "Firmware {0} already cached"
        FwDownloading     = "Downloading firmware {0}..."
        FwEbuNote         = "Note: .ebu not available for {0} (OK)"
        FwDownloaded      = "[OK] Firmware {0} downloaded"
        FwMigration       = "Migration 14.x -> {0}: ewonfwr.ebus and ewonfwr.ebu"
        FwUpdateMsg       = "Update -> {0}: ewonfwr.ebus"
        FwCopied          = "+ {0} copied"
        FwFileMissing     = "! Missing file: {0}"
        FwNotFound        = "Firmware not found in cache: {0}"

        # --- Generator ---
        GenProcessing     = "Processing {0}..."
        GenRemoving       = "  Removing: {0}"
        GenTemplateMissing = "Missing template: {0}"
        GenFwDownloadFail = "Firmware download failed."
        GenTarFail        = "Failed to create backup.tar"
        GenTarOk          = "[OK] backup.tar created"
        GenT2MCleanup     = "Cleaning up T2M..."
        GenFwCopy         = "Copying firmwares..."
        GenT2MWrite       = "Writing T2M.txt..."
        GenT2MOk          = "[OK] T2M.txt written"
        GenVerify         = "Verifying files..."
        GenFileOk         = "[OK]"
        GenFileMissing    = "[MISSING]"
        GenFilesMissing   = "Missing files on SD card."
        GenProcGen        = "Generating procedure..."
        GenProcSaved      = "[OK] Procedure saved: {0}"
        GenAutoParams     = "Computing automatic parameters..."
        GenDone           = "Done!"

        # --- Parameter Descriptions ---
        Desc_EthIP        = "IP Address"
        Desc_EthMask      = "Subnet mask"
        Desc_Identification = "Ewon name"
        Desc_NtpServer    = "Server"
        Desc_NtpPort      = "Port"
        Desc_Timezone     = "Time zone"
        Desc_Password     = "Password (max 24 char.)"
        Desc_AccountName  = "Account name"
        Desc_AccountAuth  = "Authorization"
        Desc_UseBOOTP2    = "IP assignment"
        Desc_EthIpAddr2   = "IP Address"
        Desc_EthIpMask2   = "Subnet mask"
        Desc_EthGW        = "Gateway"
        Desc_EthDns1      = "Primary DNS"
        Desc_EthDns2      = "Secondary DNS"
        Desc_WANPxyMode   = "Mode"
        Desc_WANPxyAddr   = "Address"
        Desc_WANPxyPort   = "Port"
        Desc_WANPxyUsr    = "Username"
        Desc_WANPxyPass   = "Password"
        Desc_PIN          = "PIN code (4 digits)"
        Desc_PdpApn       = "Access point name"
        Desc_PPPUser      = "Username"
        Desc_PPPPass      = "Password"

        # --- Parameter Groups ---
        Group_LAN         = "LAN Network"
        Group_Identification = "Identification"
        Group_NTP         = "Time (NTP)"
        Group_Security    = "Security"
        Group_MyPortal    = "MyPortal3E"
        Group_WAN         = "WAN IP Configuration"
        Group_Proxy       = "HTTP Proxy"
        Group_SIM         = "SIM Card"
        Group_APN         = "APN"
        Group_NetConfig   = "Network Configuration"

        # --- Choice Labels ---
        Choice_Static     = "Static"
        Choice_DHCP       = "DHCP"
        Choice_NoProxy    = "No proxy"
        Choice_BasicAuth  = "Basic auth"
        Choice_NTLMAuth   = "NTLM auth"
        Choice_NoAuth     = "No authentication"

        # --- UIHelpers ---
        DriveNoName       = "Unnamed"

        # --- Procedure Document ---
        Proc_Title        = "DETAILED PROCEDURE AFTER SD CARD PREPARATION"
        Proc_Separator    = "--------------------------------------------------"
        Proc_NoFwUpdate   = "CONFIGURATION WITHOUT FIRMWARE UPDATE"
        Proc_Intro        = "Configuration dynamically generated with the following parameters:"
        Proc_Step1Title   = "STEP 1: PREPARATION"
        Proc_Step1_1      = "1. In Windows: right-click the SD drive and select `"Eject`""
        Proc_Step1_2      = "2. Wait for Windows to confirm that you can safely remove the card"
        Proc_Step1_3      = "3. Physically remove the SD card from your computer"
        Proc_Step2NoFwTitle = "STEP 2: CARD INSERTION (CONFIGURATION ONLY)"
        Proc_Step2NoFw_1  = "1. Make sure the Ewon Flexy is POWERED ON and the USR LED is blinking GREEN"
        Proc_Step2NoFw_2  = "2. Insert the SD card into the Ewon's slot"
        Proc_Step2NoFw_3  = "3. WAIT for the USR LED to turn SOLID GREEN (this may take a few minutes)"
        Proc_Step2NoFw_4  = "4. When the LED is SOLID GREEN, remove the SD card"
        Proc_Step2NoFw_5  = "5. Configuration is complete when the USR LED returns to regular GREEN blinking"
        Proc_Step2FwTitle = "STEP 2: FIRST INSERTION (FIRMWARE UPDATE)"
        Proc_Step2Fw_1    = "1. Make sure the Ewon Flexy is POWERED OFF"
        Proc_Step2Fw_2    = "2. Insert the SD card into the Ewon's slot"
        Proc_Step2Fw_3    = "3. Power on the Ewon"
        Proc_Step2Fw_4    = "4. WAIT for the USR LED to turn SOLID GREEN (this may take several minutes)"
        Proc_Step2Fw_5    = "5. When the LED is SOLID GREEN, remove the SD card"
        Proc_Step3FwTitle = "STEP 3: SECOND INSERTION (CONFIGURATION)"
        Proc_Step3Fw_1    = "1. WAIT for the USR LED to blink GREEN (500ms on/500ms off)"
        Proc_Step3Fw_2    = "2. Once the LED is blinking, re-insert the SD card"
        Proc_Step3Fw_3    = "3. WAIT again for the USR LED to turn SOLID GREEN"
        Proc_Step3Fw_4    = "4. When the LED is SOLID GREEN, permanently remove the SD card"
        Proc_Step3Fw_5    = "5. Configuration is complete when the USR LED returns to regular GREEN blinking"
        Proc_RemoteTitle  = "REMOTE ACCESS REQUEST"
        Proc_Remote_Intro = "Provide the following information to the administrators/configurators:"
        Proc_Remote_1     = "- Ewon serial number"
        Proc_Remote_2     = "- SIM card information (if 4G)"
        Proc_Remote_3     = "- Client site IFS identifier"
        Proc_Remote_4     = "- Desired Ewon name"
        Proc_DLTitle      = "COMMUNICATION VERIFICATION"
        Proc_DLText       = "The Ewon communicates via its LAN interface only (no Talk2M). Verify that the Ewon can reach the push.myclauger.com server through the local network."
        Proc_Conclusion   = "CONCLUSION"
        Proc_ConclusionNoFw = "Your Ewon Flexy is now configured."
        Proc_ConclusionFw = "Your Ewon Flexy is now configured and up to date."

        # --- Network module ---
        NetManifestRecover = "Retrieving manifest..."
        NetManifestCache  = "Manifest unavailable online. Searching cache..."
        NetTemplateDownload = "Downloading template {0}..."
        NetTemplateOk     = "  [OK] {0}"
        ErrorPrefix       = "[ERROR]"
        SizeUnitGB        = "GB"
    }

    # ============================================================
    # ESPANOL
    # ============================================================
    "ES" = @{
        # --- Navigation & Window ---
        WindowTitle       = "Preparación Tarjeta SD Ewon Flexy"
        BtnCancel         = "Cancelar"
        BtnPrevious       = "$([char]0x25C0) Anterior"
        BtnNext           = "Siguiente $([char]0x25B6)"
        BtnGenerate       = "Generar"
        BtnClose          = "Cerrar"
        StepTitleFormat   = "Paso {0} / {1} - {2}"
        LangLabel         = "Idioma:"

        # --- Step Titles ---
        Step0Title = "Modo y Firmware"
        Step1Title = "Tipo de conexión"
        Step2Title = "Parámetros de red WAN"
        Step3Title = "Parámetros comunes"
        Step4Title = "Credenciales Talk2M"
        Step5Title = "Selección unidad SD"
        Step6Title = "Resumen"
        Step7Title = "Generación"

        # --- Step 0: Mode + Firmware ---
        ModeTitle         = "Modo y Firmware"
        ConnChecking      = "Verificando conexión a Internet..."
        ConnCaching       = "Conexión a Internet disponible — preparando caché sin conexión..."
        ConnCachingFw     = "Descargando firmware {0} en segundo plano..."
        ConnOnlineOk      = "Conexión a Internet disponible — modo ONLINE seleccionado."
        ConnCacheOk       = "Sin conexión a Internet. Caché disponible — modo CACHE seleccionado."
        ConnNoConnection  = "Sin conexión a Internet y sin caché disponible. La preparación de la tarjeta SD es imposible. Conéctese a Internet y reinicie la aplicación."
        FwTitle           = "Firmware"
        FwHelpText        = "Los Ewon Flexy producidos desde 2026 (n° de serie >= 2601) se entregan con firmware 15.x o superior."
        FwCurrentLabel    = "Firmware actual:"
        FwTargetLabel     = "Firmware objetivo:"
        FwSkipLabel       = "Solo configuración (sin actualización de firmware)"

        # --- Step 1: Connection Type ---
        ConnTypeTitle     = "Tipo de conexión"
        ConnTypeSubtitle  = "Elija el modo de comunicación del Ewon Flexy."
        Conn4G            = "Módem 4G"
        Conn4GDesc        = "Conexión celular mediante tarjeta SIM"
        ConnEthernet      = "Ethernet"
        ConnEthernetDesc  = "Conexión por cable (DHCP o IP estática, proxy opcional)"
        ConnDatalogger    = "Datalogger (solo LAN)"
        ConnDataloggerDesc = "Comunicación por LAN, sin Talk2M"

        # --- Step 2: Network Parameters ---
        NetTitle          = "Parámetros de red WAN"
        NetSubtitle4G     = "Parámetros del módem 4G"
        NetSubtitleEth    = "Parámetros de red WAN Ethernet"
        NetSubtitleDL     = "Parámetros Datalogger (solo LAN)"
        NetSubtitleDefault = "Configure los parámetros de red."

        # --- Step 3: Common Parameters ---
        CommonTitle       = "Parámetros comunes"
        CommonSubtitle    = "Estos parámetros se utilizan independientemente del tipo de conexión."

        # --- Step 4: Talk2M ---
        T2MTitle          = "Credenciales Talk2M"
        T2MWarning        = "Estos datos NUNCA se almacenan en caché."
        T2MKeyLabel       = "Clave global de registro:"
        T2MNoteLabel      = "Descripción Ewon Talk2M:"

        # --- Step 5: SD Drive ---
        SDTitle           = "Selección de unidad SD"
        SDSubtitle        = "Inserte la tarjeta SD y seleccione la unidad a continuación."
        SDRefresh         = "Actualizar unidades"
        SDDriveInfo       = "Solo se muestran las unidades extraíbles."
        SDNoDrive         = "No se detectó ninguna unidad extraíble. Inserte una tarjeta SD y haga clic en Actualizar."
        SDDriveCount      = "{0} unidad(es) extraíble(s) detectada(s)."

        # --- Step 6: Summary ---
        SummaryTitle      = "Resumen de la configuración"
        SummaryCheck      = "Verifique todos los parámetros antes de iniciar la generación."
        SumMode           = "MODO"
        SumConnType       = "TIPO DE CONEXIÓN"
        SumFw             = "FIRMWARE"
        SumFwSkip         = "Solo configuración (sin actualización)"
        SumSD             = "UNIDAD SD"
        SumParams         = "--- Parámetros ---"
        SumT2M            = "--- Talk2M ---"

        # --- Step 7: Generation ---
        GenTitle          = "Generación en curso..."
        GenComplete       = "¡Generación completada!"
        GenSuccess        = "PREPARACIÓN COMPLETADA CON ÉXITO"
        GenProcTitle      = "Procedimiento de uso de la tarjeta SD"
        PrepTitle         = "¡Preparación completada!"
        PrepSuccess       = "PREPARACIÓN COMPLETADA CON ÉXITO"

        # --- Validation ---
        ValRequired       = "Valor obligatorio."
        ValInvalidIP      = "Dirección IP inválida. Formato: xxx.xxx.xxx.xxx"
        ValInvalidPIN     = "Código PIN inválido. Se requieren 4 dígitos."
        ValInteger        = "Se requiere un entero."
        ValMaxLength      = "Máximo 24 caracteres."

        # --- Dialogs ---
        DlgGenInProgress  = "Hay una generación en curso. ¿Realmente desea salir?"
        DlgConfirm        = "Confirmación"
        DlgValidation     = "Validación"
        DlgSelectCurrentFw = "Seleccione el firmware actual."
        DlgSelectTargetFw = "Seleccione el firmware objetivo (o marque 'Solo configuración')."
        DlgT2MKeyRequired = "La clave global de registro Talk2M es obligatoria."
        DlgT2MNoteRequired = "La descripción Ewon Talk2M es obligatoria."
        DlgSelectSD       = "Seleccione una unidad SD."
        DlgQuit           = "¿Realmente desea salir?"
        DlgError          = "Error"
        DlgNavError       = "Error de navegación: {0}"

        # --- Progress & Generation ---
        ProgOnlineDownload = "Modo ONLINE — descargando recursos..."
        ProgResourcesOk   = "[OK] Recursos descargados"
        ProgCacheUnavail   = "Caché no disponible"
        ProgPreparation    = "Modo PREPARACIÓN — descargando todos los recursos..."
        ProgManifest       = "Recuperando manifest..."
        ProgManifestOk     = "[OK] Manifest guardado"
        ProgManifestFail   = "Imposible recuperar el manifest."
        ProgManifestFailOnline = "Imposible recuperar el manifest en línea."
        ProgTemplates      = "Descargando plantillas..."
        ProgTemplateFail   = "Fallo en la descarga de plantillas."
        ProgFirmwares      = "Descargando firmwares..."
        ProgDone           = "¡Terminado!"

        # --- Firmware ---
        FwCached          = "Firmware {0} ya en caché"
        FwDownloading     = "Descargando firmware {0}..."
        FwEbuNote         = "Nota: .ebu no disponible para {0} (OK)"
        FwDownloaded      = "[OK] Firmware {0} descargado"
        FwMigration       = "Migración 14.x -> {0}: ewonfwr.ebus y ewonfwr.ebu"
        FwUpdateMsg       = "Actualización -> {0}: ewonfwr.ebus"
        FwCopied          = "+ {0} copiado"
        FwFileMissing     = "! Archivo faltante: {0}"
        FwNotFound        = "Firmware no encontrado en caché: {0}"

        # --- Generator ---
        GenProcessing     = "Procesando {0}..."
        GenRemoving       = "  Eliminando: {0}"
        GenTemplateMissing = "Plantilla faltante: {0}"
        GenFwDownloadFail = "Fallo en la descarga del firmware."
        GenTarFail        = "Fallo en la creación de backup.tar"
        GenTarOk          = "[OK] backup.tar creado"
        GenT2MCleanup     = "Limpieza T2M..."
        GenFwCopy         = "Copiando firmwares..."
        GenT2MWrite       = "Escribiendo T2M.txt..."
        GenT2MOk          = "[OK] T2M.txt escrito"
        GenVerify         = "Verificando archivos..."
        GenFileOk         = "[OK]"
        GenFileMissing    = "[FALTANTE]"
        GenFilesMissing   = "Archivos faltantes en la SD."
        GenProcGen        = "Generando procedimiento..."
        GenProcSaved      = "[OK] Procedimiento guardado: {0}"
        GenAutoParams     = "Calculando parámetros automáticos..."
        GenDone           = "¡Terminado!"

        # --- Parameter Descriptions ---
        Desc_EthIP        = "Dirección IP"
        Desc_EthMask      = "Máscara de subred"
        Desc_Identification = "Nombre del Ewon"
        Desc_NtpServer    = "Servidor"
        Desc_NtpPort      = "Puerto"
        Desc_Timezone     = "Zona horaria"
        Desc_Password     = "Contraseña (máx. 24 car.)"
        Desc_AccountName  = "Nombre de cuenta"
        Desc_AccountAuth  = "Autorización"
        Desc_UseBOOTP2    = "Asignación IP"
        Desc_EthIpAddr2   = "Dirección IP"
        Desc_EthIpMask2   = "Máscara de subred"
        Desc_EthGW        = "Puerta de enlace"
        Desc_EthDns1      = "DNS primario"
        Desc_EthDns2      = "DNS secundario"
        Desc_WANPxyMode   = "Modo"
        Desc_WANPxyAddr   = "Dirección"
        Desc_WANPxyPort   = "Puerto"
        Desc_WANPxyUsr    = "Usuario"
        Desc_WANPxyPass   = "Contraseña"
        Desc_PIN          = "Código PIN (4 dígitos)"
        Desc_PdpApn       = "Nombre del punto de acceso"
        Desc_PPPUser      = "Usuario"
        Desc_PPPPass      = "Contraseña"

        # --- Parameter Groups ---
        Group_LAN         = "Red LAN"
        Group_Identification = "Identificación"
        Group_NTP         = "Hora (NTP)"
        Group_Security    = "Seguridad"
        Group_MyPortal    = "MyPortal3E"
        Group_WAN         = "Configuración IP WAN"
        Group_Proxy       = "Proxy HTTP"
        Group_SIM         = "Tarjeta SIM"
        Group_APN         = "APN"
        Group_NetConfig   = "Configuración de red"

        # --- Choice Labels ---
        Choice_Static     = "Estática"
        Choice_DHCP       = "DHCP"
        Choice_NoProxy    = "Sin proxy"
        Choice_BasicAuth  = "Basic auth"
        Choice_NTLMAuth   = "NTLM auth"
        Choice_NoAuth     = "Sin autenticación"

        # --- UIHelpers ---
        DriveNoName       = "Sin nombre"

        # --- Procedure Document ---
        Proc_Title        = "PROCEDIMIENTO DETALLADO DESPUÉS DE LA PREPARACIÓN DE LA TARJETA SD"
        Proc_Separator    = "--------------------------------------------------"
        Proc_NoFwUpdate   = "CONFIGURACIÓN SIN ACTUALIZACIÓN DE FIRMWARE"
        Proc_Intro        = "Configuración generada dinámicamente con los siguientes parámetros:"
        Proc_Step1Title   = "PASO 1: PREPARACIÓN"
        Proc_Step1_1      = "1. En Windows: haga clic derecho en la unidad SD y seleccione `"Expulsar`""
        Proc_Step1_2      = "2. Espere a que Windows confirme que puede retirar la tarjeta de forma segura"
        Proc_Step1_3      = "3. Retire físicamente la tarjeta SD de su ordenador"
        Proc_Step2NoFwTitle = "PASO 2: INSERCIÓN DE LA TARJETA (SOLO CONFIGURACIÓN)"
        Proc_Step2NoFw_1  = "1. Asegúrese de que el Ewon Flexy está ENCENDIDO y que el LED USR parpadea en VERDE"
        Proc_Step2NoFw_2  = "2. Inserte la tarjeta SD en la ranura del Ewon"
        Proc_Step2NoFw_3  = "3. ESPERE a que el LED USR se ponga en VERDE FIJO (puede tardar unos minutos)"
        Proc_Step2NoFw_4  = "4. Cuando el LED esté en VERDE FIJO, retire la tarjeta SD"
        Proc_Step2NoFw_5  = "5. La configuración está completa cuando el LED USR vuelve a parpadear en VERDE"
        Proc_Step2FwTitle = "PASO 2: PRIMERA INSERCIÓN (ACTUALIZACIÓN DE FIRMWARE)"
        Proc_Step2Fw_1    = "1. Asegúrese de que el Ewon Flexy está APAGADO"
        Proc_Step2Fw_2    = "2. Inserte la tarjeta SD en la ranura del Ewon"
        Proc_Step2Fw_3    = "3. Encienda el Ewon"
        Proc_Step2Fw_4    = "4. ESPERE a que el LED USR se ponga en VERDE FIJO (puede tardar varios minutos)"
        Proc_Step2Fw_5    = "5. Cuando el LED esté en VERDE FIJO, retire la tarjeta SD"
        Proc_Step3FwTitle = "PASO 3: SEGUNDA INSERCIÓN (CONFIGURACIÓN)"
        Proc_Step3Fw_1    = "1. ESPERE a que el LED USR parpadee en VERDE (500ms encendido/500ms apagado)"
        Proc_Step3Fw_2    = "2. Una vez que el LED parpadea, vuelva a insertar la tarjeta SD"
        Proc_Step3Fw_3    = "3. ESPERE de nuevo a que el LED USR se ponga en VERDE FIJO"
        Proc_Step3Fw_4    = "4. Cuando el LED esté en VERDE FIJO, retire definitivamente la tarjeta SD"
        Proc_Step3Fw_5    = "5. La configuración está completa cuando el LED USR vuelve a parpadear en VERDE"
        Proc_RemoteTitle  = "SOLICITUD DE ACCESO REMOTO"
        Proc_Remote_Intro = "Transmita a los administradores/configuradores la siguiente información:"
        Proc_Remote_1     = "- Número de serie del Ewon"
        Proc_Remote_2     = "- Información de la tarjeta SIM (si 4G)"
        Proc_Remote_3     = "- Identificador IFS del sitio del cliente"
        Proc_Remote_4     = "- Nombre deseado para el Ewon"
        Proc_DLTitle      = "VERIFICACIÓN DE LA COMUNICACIÓN"
        Proc_DLText       = "El Ewon se comunica solo a través de su interfaz LAN (sin Talk2M). Verifique que el Ewon puede alcanzar el servidor push.myclauger.com a través de la red local."
        Proc_Conclusion   = "CONCLUSIÓN"
        Proc_ConclusionNoFw = "Su Ewon Flexy está ahora configurado."
        Proc_ConclusionFw = "Su Ewon Flexy está ahora configurado y actualizado."

        # --- Network module ---
        NetManifestRecover = "Recuperando manifest..."
        NetManifestCache  = "Manifest no disponible en línea. Buscando en caché..."
        NetTemplateDownload = "Descargando plantilla {0}..."
        NetTemplateOk     = "  [OK] {0}"
        ErrorPrefix       = "[ERROR]"
        SizeUnitGB        = "GB"
    }

    # ============================================================
    # ITALIANO
    # ============================================================
    "IT" = @{
        # --- Navigation & Window ---
        WindowTitle       = "Preparazione Scheda SD Ewon Flexy"
        BtnCancel         = "Annulla"
        BtnPrevious       = "$([char]0x25C0) Precedente"
        BtnNext           = "Avanti $([char]0x25B6)"
        BtnGenerate       = "Genera"
        BtnClose          = "Chiudi"
        StepTitleFormat   = "Passo {0} / {1} - {2}"
        LangLabel         = "Lingua:"

        # --- Step Titles ---
        Step0Title = "Modalità e Firmware"
        Step1Title = "Tipo di connessione"
        Step2Title = "Parametri di rete WAN"
        Step3Title = "Parametri comuni"
        Step4Title = "Credenziali Talk2M"
        Step5Title = "Selezione unità SD"
        Step6Title = "Riepilogo"
        Step7Title = "Generazione"

        # --- Step 0: Mode + Firmware ---
        ModeTitle         = "Modalità e Firmware"
        ConnChecking      = "Verifica della connessione Internet..."
        ConnCaching       = "Connessione Internet disponibile — preparazione cache offline..."
        ConnCachingFw     = "Download firmware {0} in background..."
        ConnOnlineOk      = "Connessione Internet disponibile — modalità ONLINE selezionata."
        ConnCacheOk       = "Nessuna connessione Internet. Cache disponibile — modalità CACHE selezionata."
        ConnNoConnection  = "Nessuna connessione Internet e nessuna cache disponibile. La preparazione della scheda SD è impossibile. Connettersi a Internet e riavviare l'applicazione."
        FwTitle           = "Firmware"
        FwHelpText        = "Gli Ewon Flexy prodotti dal 2026 (n° di serie >= 2601) vengono forniti con firmware 15.x o superiore."
        FwCurrentLabel    = "Firmware attuale:"
        FwTargetLabel     = "Firmware obiettivo:"
        FwSkipLabel       = "Solo configurazione (nessun aggiornamento firmware)"

        # --- Step 1: Connection Type ---
        ConnTypeTitle     = "Tipo di connessione"
        ConnTypeSubtitle  = "Scegliere la modalità di comunicazione dell'Ewon Flexy."
        Conn4G            = "Modem 4G"
        Conn4GDesc        = "Connessione cellulare tramite scheda SIM"
        ConnEthernet      = "Ethernet"
        ConnEthernetDesc  = "Connessione cablata (DHCP o IP statico, proxy opzionale)"
        ConnDatalogger    = "Datalogger (solo LAN)"
        ConnDataloggerDesc = "Comunicazione via LAN, senza Talk2M"

        # --- Step 2: Network Parameters ---
        NetTitle          = "Parametri di rete WAN"
        NetSubtitle4G     = "Parametri del modem 4G"
        NetSubtitleEth    = "Parametri di rete WAN Ethernet"
        NetSubtitleDL     = "Parametri Datalogger (solo LAN)"
        NetSubtitleDefault = "Configurare i parametri di rete."

        # --- Step 3: Common Parameters ---
        CommonTitle       = "Parametri comuni"
        CommonSubtitle    = "Questi parametri vengono utilizzati indipendentemente dal tipo di connessione."

        # --- Step 4: Talk2M ---
        T2MTitle          = "Credenziali Talk2M"
        T2MWarning        = "Questi dati non vengono MAI memorizzati nella cache."
        T2MKeyLabel       = "Chiave di registrazione globale:"
        T2MNoteLabel      = "Descrizione Ewon Talk2M:"

        # --- Step 5: SD Drive ---
        SDTitle           = "Selezione unità SD"
        SDSubtitle        = "Inserire la scheda SD e selezionare l'unità qui sotto."
        SDRefresh         = "Aggiorna unità"
        SDDriveInfo       = "Vengono mostrate solo le unità rimovibili."
        SDNoDrive         = "Nessuna unità rimovibile rilevata. Inserire una scheda SD e fare clic su Aggiorna."
        SDDriveCount      = "{0} unità rimovibile/i rilevata/e."

        # --- Step 6: Summary ---
        SummaryTitle      = "Riepilogo della configurazione"
        SummaryCheck      = "Verificare tutti i parametri prima di avviare la generazione."
        SumMode           = "MODALITÀ"
        SumConnType       = "TIPO DI CONNESSIONE"
        SumFw             = "FIRMWARE"
        SumFwSkip         = "Solo configurazione (nessun aggiornamento)"
        SumSD             = "UNITÀ SD"
        SumParams         = "--- Parametri ---"
        SumT2M            = "--- Talk2M ---"

        # --- Step 7: Generation ---
        GenTitle          = "Generazione in corso..."
        GenComplete       = "Generazione completata!"
        GenSuccess        = "PREPARAZIONE COMPLETATA CON SUCCESSO"
        GenProcTitle      = "Procedura di utilizzo della scheda SD"
        PrepTitle         = "Preparazione completata!"
        PrepSuccess       = "PREPARAZIONE COMPLETATA CON SUCCESSO"

        # --- Validation ---
        ValRequired       = "Valore obbligatorio."
        ValInvalidIP      = "Indirizzo IP non valido. Formato: xxx.xxx.xxx.xxx"
        ValInvalidPIN     = "Codice PIN non valido. 4 cifre richieste."
        ValInteger        = "Numero intero richiesto."
        ValMaxLength      = "Massimo 24 caratteri."

        # --- Dialogs ---
        DlgGenInProgress  = "Una generazione è in corso. Si desidera veramente uscire?"
        DlgConfirm        = "Conferma"
        DlgValidation     = "Validazione"
        DlgSelectCurrentFw = "Selezionare il firmware attuale."
        DlgSelectTargetFw = "Selezionare il firmware obiettivo (o selezionare 'Solo configurazione')."
        DlgT2MKeyRequired = "La chiave di registrazione globale Talk2M è obbligatoria."
        DlgT2MNoteRequired = "La descrizione Ewon Talk2M è obbligatoria."
        DlgSelectSD       = "Selezionare un'unità SD."
        DlgQuit           = "Si desidera veramente uscire?"
        DlgError          = "Errore"
        DlgNavError       = "Errore di navigazione: {0}"

        # --- Progress & Generation ---
        ProgOnlineDownload = "Modalità ONLINE — download delle risorse..."
        ProgResourcesOk   = "[OK] Risorse scaricate"
        ProgCacheUnavail   = "Cache non disponibile"
        ProgPreparation    = "Modalità PREPARAZIONE — download di tutte le risorse..."
        ProgManifest       = "Recupero del manifest..."
        ProgManifestOk     = "[OK] Manifest salvato"
        ProgManifestFail   = "Impossibile recuperare il manifest."
        ProgManifestFailOnline = "Impossibile recuperare il manifest online."
        ProgTemplates      = "Download dei template..."
        ProgTemplateFail   = "Download dei template fallito."
        ProgFirmwares      = "Download dei firmware..."
        ProgDone           = "Completato!"

        # --- Firmware ---
        FwCached          = "Firmware {0} già nella cache"
        FwDownloading     = "Download firmware {0}..."
        FwEbuNote         = "Nota: .ebu non disponibile per {0} (OK)"
        FwDownloaded      = "[OK] Firmware {0} scaricato"
        FwMigration       = "Migrazione 14.x -> {0}: ewonfwr.ebus e ewonfwr.ebu"
        FwUpdateMsg       = "Aggiornamento -> {0}: ewonfwr.ebus"
        FwCopied          = "+ {0} copiato"
        FwFileMissing     = "! File mancante: {0}"
        FwNotFound        = "Firmware non trovato nella cache: {0}"

        # --- Generator ---
        GenProcessing     = "Elaborazione di {0}..."
        GenRemoving       = "  Rimozione: {0}"
        GenTemplateMissing = "Template mancante: {0}"
        GenFwDownloadFail = "Download del firmware fallito."
        GenTarFail        = "Creazione di backup.tar fallita"
        GenTarOk          = "[OK] backup.tar creato"
        GenT2MCleanup     = "Pulizia T2M..."
        GenFwCopy         = "Copia dei firmware..."
        GenT2MWrite       = "Scrittura T2M.txt..."
        GenT2MOk          = "[OK] T2M.txt scritto"
        GenVerify         = "Verifica dei file..."
        GenFileOk         = "[OK]"
        GenFileMissing    = "[MANCANTE]"
        GenFilesMissing   = "File mancanti sulla SD."
        GenProcGen        = "Generazione della procedura..."
        GenProcSaved      = "[OK] Procedura salvata: {0}"
        GenAutoParams     = "Calcolo dei parametri automatici..."
        GenDone           = "Completato!"

        # --- Parameter Descriptions ---
        Desc_EthIP        = "Indirizzo IP"
        Desc_EthMask      = "Maschera di sottorete"
        Desc_Identification = "Nome dell'Ewon"
        Desc_NtpServer    = "Server"
        Desc_NtpPort      = "Porta"
        Desc_Timezone     = "Fuso orario"
        Desc_Password     = "Password (max 24 car.)"
        Desc_AccountName  = "Nome account"
        Desc_AccountAuth  = "Autorizzazione"
        Desc_UseBOOTP2    = "Assegnazione IP"
        Desc_EthIpAddr2   = "Indirizzo IP"
        Desc_EthIpMask2   = "Maschera di sottorete"
        Desc_EthGW        = "Gateway"
        Desc_EthDns1      = "DNS primario"
        Desc_EthDns2      = "DNS secondario"
        Desc_WANPxyMode   = "Modalità"
        Desc_WANPxyAddr   = "Indirizzo"
        Desc_WANPxyPort   = "Porta"
        Desc_WANPxyUsr    = "Utente"
        Desc_WANPxyPass   = "Password"
        Desc_PIN          = "Codice PIN (4 cifre)"
        Desc_PdpApn       = "Nome punto di accesso"
        Desc_PPPUser      = "Utente"
        Desc_PPPPass      = "Password"

        # --- Parameter Groups ---
        Group_LAN         = "Rete LAN"
        Group_Identification = "Identificazione"
        Group_NTP         = "Ora (NTP)"
        Group_Security    = "Sicurezza"
        Group_MyPortal    = "MyPortal3E"
        Group_WAN         = "Configurazione IP WAN"
        Group_Proxy       = "Proxy HTTP"
        Group_SIM         = "Scheda SIM"
        Group_APN         = "APN"
        Group_NetConfig   = "Configurazione di rete"

        # --- Choice Labels ---
        Choice_Static     = "Statico"
        Choice_DHCP       = "DHCP"
        Choice_NoProxy    = "Senza proxy"
        Choice_BasicAuth  = "Basic auth"
        Choice_NTLMAuth   = "NTLM auth"
        Choice_NoAuth     = "Senza autenticazione"

        # --- UIHelpers ---
        DriveNoName       = "Senza nome"

        # --- Procedure Document ---
        Proc_Title        = "PROCEDURA DETTAGLIATA DOPO LA PREPARAZIONE DELLA SCHEDA SD"
        Proc_Separator    = "--------------------------------------------------"
        Proc_NoFwUpdate   = "CONFIGURAZIONE SENZA AGGIORNAMENTO FIRMWARE"
        Proc_Intro        = "Configurazione generata dinamicamente con i seguenti parametri:"
        Proc_Step1Title   = "FASE 1: PREPARAZIONE"
        Proc_Step1_1      = "1. In Windows: fare clic destro sull'unità SD e selezionare `"Espelli`""
        Proc_Step1_2      = "2. Attendere che Windows confermi che è possibile rimuovere la scheda in sicurezza"
        Proc_Step1_3      = "3. Rimuovere fisicamente la scheda SD dal computer"
        Proc_Step2NoFwTitle = "FASE 2: INSERIMENTO DELLA SCHEDA (SOLO CONFIGURAZIONE)"
        Proc_Step2NoFw_1  = "1. Assicurarsi che l'Ewon Flexy sia ACCESO e che il LED USR lampeggi in VERDE"
        Proc_Step2NoFw_2  = "2. Inserire la scheda SD nello slot dell'Ewon"
        Proc_Step2NoFw_3  = "3. ATTENDERE che il LED USR diventi VERDE FISSO (può richiedere alcuni minuti)"
        Proc_Step2NoFw_4  = "4. Quando il LED è VERDE FISSO, rimuovere la scheda SD"
        Proc_Step2NoFw_5  = "5. La configurazione è completa quando il LED USR torna a lampeggiare regolarmente in VERDE"
        Proc_Step2FwTitle = "FASE 2: PRIMO INSERIMENTO (AGGIORNAMENTO FIRMWARE)"
        Proc_Step2Fw_1    = "1. Assicurarsi che l'Ewon Flexy sia SPENTO"
        Proc_Step2Fw_2    = "2. Inserire la scheda SD nello slot dell'Ewon"
        Proc_Step2Fw_3    = "3. Accendere l'Ewon"
        Proc_Step2Fw_4    = "4. ATTENDERE che il LED USR diventi VERDE FISSO (può richiedere diversi minuti)"
        Proc_Step2Fw_5    = "5. Quando il LED è VERDE FISSO, rimuovere la scheda SD"
        Proc_Step3FwTitle = "FASE 3: SECONDO INSERIMENTO (CONFIGURAZIONE)"
        Proc_Step3Fw_1    = "1. ATTENDERE che il LED USR lampeggi in VERDE (500ms acceso/500ms spento)"
        Proc_Step3Fw_2    = "2. Una volta che il LED lampeggia, reinserire la scheda SD"
        Proc_Step3Fw_3    = "3. ATTENDERE nuovamente che il LED USR diventi VERDE FISSO"
        Proc_Step3Fw_4    = "4. Quando il LED è VERDE FISSO, rimuovere definitivamente la scheda SD"
        Proc_Step3Fw_5    = "5. La configurazione è completa quando il LED USR torna a lampeggiare regolarmente in VERDE"
        Proc_RemoteTitle  = "RICHIESTA DI ACCESSO REMOTO"
        Proc_Remote_Intro = "Trasmettere agli amministratori/configuratori le seguenti informazioni:"
        Proc_Remote_1     = "- Numero di serie dell'Ewon"
        Proc_Remote_2     = "- Informazioni sulla scheda SIM (se 4G)"
        Proc_Remote_3     = "- Identificativo IFS del sito del cliente"
        Proc_Remote_4     = "- Nome desiderato per l'Ewon"
        Proc_DLTitle      = "VERIFICA DELLA COMUNICAZIONE"
        Proc_DLText       = "L'Ewon comunica solo tramite la sua interfaccia LAN (senza Talk2M). Verificare che l'Ewon possa raggiungere il server push.myclauger.com attraverso la rete locale."
        Proc_Conclusion   = "CONCLUSIONE"
        Proc_ConclusionNoFw = "Il vostro Ewon Flexy è ora configurato."
        Proc_ConclusionFw = "Il vostro Ewon Flexy è ora configurato e aggiornato."

        # --- Network module ---
        NetManifestRecover = "Recupero del manifest..."
        NetManifestCache  = "Manifest non disponibile online. Ricerca nella cache..."
        NetTemplateDownload = "Download template {0}..."
        NetTemplateOk     = "  [OK] {0}"
        ErrorPrefix       = "[ERRORE]"
        SizeUnitGB        = "GB"
    }
}

function T([string]$Key) {
    $s = $Script:Strings[$Script:CurrentLanguage]
    if ($s -and $s.ContainsKey($Key)) { return $s[$Key] }
    # Fallback to French
    $fr = $Script:Strings["FR"]
    if ($fr -and $fr.ContainsKey($Key)) { return $fr[$Key] }
    return "[$Key]"
}

function Set-Language([string]$Lang) {
    if ($Script:Strings.ContainsKey($Lang)) {
        $Script:CurrentLanguage = $Lang
    }
}

function Get-Language { return $Script:CurrentLanguage }
