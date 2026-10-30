using System.Globalization;

namespace EwonFlexySdPrep;

/// <summary>
/// Textes affichés par le wrapper, dans la langue de Windows (FR/EN/ES/IT), le français
/// par défaut comme dans l'application.
/// </summary>
static class WrapperText
{
    const string DefaultLanguage = "fr";

    static readonly Dictionary<string, Dictionary<string, string>> Strings = new()
    {
        ["fr"] = new()
        {
            ["CheckingTitle"] = "Recherche de mise à jour…",
            ["CheckingDetail"] = "Connexion au serveur de mises à jour",
            ["UpdateTitle"] = "Mise à jour vers la version {0}",
            ["DownloadProgress"] = "Téléchargement : {0:F1} Mo sur {1:F1} Mo",
            ["DownloadProgressUnknownSize"] = "Téléchargement : {0:F1} Mo",
        },
        ["en"] = new()
        {
            ["CheckingTitle"] = "Checking for updates…",
            ["CheckingDetail"] = "Connecting to the update server",
            ["UpdateTitle"] = "Updating to version {0}",
            ["DownloadProgress"] = "Downloading: {0:F1} MB of {1:F1} MB",
            ["DownloadProgressUnknownSize"] = "Downloading: {0:F1} MB",
        },
        ["es"] = new()
        {
            ["CheckingTitle"] = "Buscando actualizaciones…",
            ["CheckingDetail"] = "Conectando con el servidor de actualizaciones",
            ["UpdateTitle"] = "Actualización a la versión {0}",
            ["DownloadProgress"] = "Descargando: {0:F1} MB de {1:F1} MB",
            ["DownloadProgressUnknownSize"] = "Descargando: {0:F1} MB",
        },
        ["it"] = new()
        {
            ["CheckingTitle"] = "Ricerca aggiornamenti…",
            ["CheckingDetail"] = "Connessione al server degli aggiornamenti",
            ["UpdateTitle"] = "Aggiornamento alla versione {0}",
            ["DownloadProgress"] = "Download: {0:F1} MB di {1:F1} MB",
            ["DownloadProgressUnknownSize"] = "Download: {0:F1} MB",
        },
    };

    public static string Get(string key)
    {
        var language = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
        var strings = Strings.TryGetValue(language, out var found) ? found : Strings[DefaultLanguage];
        return strings[key];
    }
}
