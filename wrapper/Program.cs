using System.Diagnostics;
using System.Reflection;
using System.Text;
using System.Text.Json;

namespace EwonFlexySdPrep;

static class Program
{
    const string AppName = "Ewon Flexy SD Preparator";
    const string ExeName = "EwonFlexySdPrep.exe";
    const string GitHubApiUrl = "https://api.github.com/repos/JohannPx/ewon-flexy-config/releases/latest";

    static readonly string InstallDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "EwonFlexySdPrep");
    static readonly string VersionFile = Path.Combine(InstallDir, "version.json");

    // Argument passé à l'ancien exe relancé après un remplacement raté
    const string SkipUpdateArg = "--skip-update";
    const int UpdateCopyMaxAttempts = 15;
    const int UpdateCopyRetryDelaySeconds = 2;
    static readonly TimeSpan ReleaseCheckTimeout = TimeSpan.FromSeconds(10);
    static readonly TimeSpan ExeDownloadTimeout = TimeSpan.FromMinutes(5);
    const int DownloadBufferSize = 81920;

    [STAThread]
    static async Task<int> Main(string[] args)
    {
        try
        {
            if (InstallIfNeeded()) return 0;
            if (!args.Contains(SkipUpdateArg)) await UpdateSilently();
            LaunchScript();
        }
        catch
        {
            // Fallback: just launch the script regardless of errors
            try { LaunchScript(); } catch { }
        }
        return 0;
    }

    /// <summary>
    /// First launch: copy exe to AppData, create shortcuts, relaunch from there.
    /// </summary>
    static bool InstallIfNeeded()
    {
        var currentExe = Environment.ProcessPath ?? Process.GetCurrentProcess().MainModule?.FileName;
        if (currentExe == null || !currentExe.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
            return false;

        var installedExe = Path.Combine(InstallDir, ExeName);

        // Already running from install dir
        if (string.Equals(Path.GetFullPath(currentExe), Path.GetFullPath(installedExe), StringComparison.OrdinalIgnoreCase))
            return false;

        Directory.CreateDirectory(InstallDir);
        File.Copy(currentExe, installedExe, true);

        // Create shortcuts via PowerShell (avoids COM interop / trimming issues)
        var desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
        CreateShortcut(Path.Combine(desktop, $"{AppName}.lnk"), installedExe);

        var startMenu = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), "Programs");
        Directory.CreateDirectory(startMenu);
        CreateShortcut(Path.Combine(startMenu, $"{AppName}.lnk"), installedExe);

        // Initialize version.json
        if (!File.Exists(VersionFile))
            File.WriteAllText(VersionFile, """{"version":"0.0.0"}""");

        // Relaunch from install dir and exit
        Process.Start(new ProcessStartInfo(installedExe) { UseShellExecute = true });
        return true;
    }

    static void CreateShortcut(string lnkPath, string targetPath)
    {
        var dir = Path.GetDirectoryName(lnkPath);
        if (dir != null && !Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        var escapedLnk = lnkPath.Replace("'", "''");
        var escapedTarget = targetPath.Replace("'", "''");
        var escapedDir = Path.GetDirectoryName(targetPath)?.Replace("'", "''") ?? "";

        var ps = $"$s=(New-Object -ComObject WScript.Shell).CreateShortcut('{escapedLnk}');" +
                 $"$s.TargetPath='{escapedTarget}';" +
                 $"$s.WorkingDirectory='{escapedDir}';" +
                 $"$s.Description='{AppName}';" +
                 "$s.Save()";

        var psi = new ProcessStartInfo("powershell.exe", $"-NoProfile -Command \"{ps}\"")
        {
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden,
            UseShellExecute = false
        };
        Process.Start(psi)?.WaitForExit(5000);
    }

    /// <summary>
    /// Check GitHub Releases for a newer version; download and swap if found.
    /// </summary>
    static async Task UpdateSilently()
    {
        var currentExe = Environment.ProcessPath ?? Process.GetCurrentProcess().MainModule?.FileName;
        var installedExe = Path.Combine(InstallDir, ExeName);
        if (currentExe == null ||
            !string.Equals(Path.GetFullPath(currentExe), Path.GetFullPath(installedExe), StringComparison.OrdinalIgnoreCase))
            return;

        var localVersion = "0.0.0";
        if (File.Exists(VersionFile))
        {
            try
            {
                using var doc = JsonDocument.Parse(File.ReadAllText(VersionFile));
                localVersion = doc.RootElement.GetProperty("version").GetString() ?? "0.0.0";
            }
            catch { /* corrupted file, treat as 0.0.0 */ }
        }

        // Chaque requête porte son propre délai : court pour la consultation de la release, afin de
        // ne pas retarder le lancement hors connexion, long pour le téléchargement de l'exe (~15 Mo)
        using var http = new HttpClient { Timeout = Timeout.InfiniteTimeSpan };
        http.DefaultRequestHeaders.Add("User-Agent", "EwonFlexySdPrep");

        using var releaseCheck = new CancellationTokenSource(ReleaseCheckTimeout);
        var json = await http.GetStringAsync(GitHubApiUrl, releaseCheck.Token);
        using var release = JsonDocument.Parse(json);
        var root = release.RootElement;

        var remoteTag = root.GetProperty("tag_name").GetString() ?? "";
        var remoteVersion = remoteTag.TrimStart('v');

        if (remoteVersion == localVersion) return;

        // Find the .exe asset
        string? downloadUrl = null;
        foreach (var asset in root.GetProperty("assets").EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            if (name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
            {
                downloadUrl = asset.GetProperty("browser_download_url").GetString();
                break;
            }
        }
        if (downloadUrl == null) return;

        // Download new exe to temp, en affichant la progression
        var tempExe = Path.Combine(Path.GetTempPath(), "EwonFlexySdPrep_update.exe");
        using var downloadCancellation = new CancellationTokenSource(ExeDownloadTimeout);
        long received = 0, total = 0;
        var download = DownloadAsync(http, downloadUrl, tempExe,
            (r, t) => { Interlocked.Exchange(ref received, r); Interlocked.Exchange(ref total, t); },
            downloadCancellation.Token);
        if (!download.IsCompleted)
        {
            UpdateProgressDialog.Show(AppName, string.Format(WrapperText.Get("UpdateTitle"), remoteVersion),
                () => (Interlocked.Read(ref received), Interlocked.Read(ref total)),
                download, downloadCancellation);
        }
        await download;

        // La version n'est enregistrée qu'une fois l'exe réellement remplacé : si la copie échoue
        // (exe encore verrouillé), la mise à jour est retentée au prochain lancement au lieu
        // d'être considérée comme faite. En cas d'échec, l'ancien exe est relancé sans
        // mise à jour pour ne pas boucler.
        var versionJson = $$$"""{"version":"{{{remoteVersion}}}","date":"{{{DateTime.Now:yyyy-MM-dd}}}"}""";
        var batchPath = Path.Combine(Path.GetTempPath(), "ewon_update.cmd");
        File.WriteAllText(batchPath,
            $"""
            @echo off
            set attempts=0
            :retry
            timeout /t {UpdateCopyRetryDelaySeconds} /nobreak >nul
            copy /y "{tempExe}" "{installedExe}" >nul 2>&1 && goto copied
            set /a attempts+=1
            if %attempts% lss {UpdateCopyMaxAttempts} goto retry
            start "" "{installedExe}" {SkipUpdateArg}
            goto cleanup
            :copied
            >"{VersionFile}" echo {versionJson}
            start "" "{installedExe}"
            :cleanup
            del "{tempExe}" >nul 2>&1
            del "%~f0" >nul 2>&1
            """, Encoding.ASCII);

        Process.Start(new ProcessStartInfo("cmd.exe", $"""/c "{batchPath}" """)
        {
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden,
            UseShellExecute = false
        });

        Environment.Exit(0);
    }

    /// <summary>
    /// Télécharge <paramref name="url"/> dans <paramref name="path"/> en signalant les octets reçus
    /// et la taille totale (0 si inconnue). Un fichier partiel est supprimé en cas d'échec.
    /// </summary>
    static async Task DownloadAsync(HttpClient http, string url, string path,
        Action<long, long> onProgress, CancellationToken cancellationToken)
    {
        try
        {
            using var response = await http.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            response.EnsureSuccessStatusCode();
            var total = response.Content.Headers.ContentLength ?? 0;

            await using var source = await response.Content.ReadAsStreamAsync(cancellationToken);
            await using var target = File.Create(path);
            var buffer = new byte[DownloadBufferSize];
            long received = 0;
            int read;
            while ((read = await source.ReadAsync(buffer, cancellationToken)) > 0)
            {
                await target.WriteAsync(buffer.AsMemory(0, read), cancellationToken);
                received += read;
                onProgress(received, total);
            }
        }
        catch
        {
            File.Delete(path);
            throw;
        }
    }

    /// <summary>
    /// Extract the embedded .ps1 script and run it via powershell.exe.
    /// </summary>
    static void LaunchScript()
    {
        var scriptPath = Path.Combine(Path.GetTempPath(), $"PrepareEwonSD_{Guid.NewGuid():N}.ps1");
        var resourceName = typeof(Program).Namespace + ".PrepareEwonSD_latest.ps1";

        using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName))
        {
            if (stream == null)
                throw new InvalidOperationException($"Embedded resource '{resourceName}' not found.");
            using var fs = File.Create(scriptPath);
            stream.CopyTo(fs);
        }

        try
        {
            // CreateNoWindow suffit à masquer la console. Un style « masqué » serait appliqué par
            // .NET 8 à la première fenêtre WPF de l'application, qui n'aurait alors pas de bouton
            // dans la barre des tâches tant qu'elle n'a pas reçu le focus.
            var psi = new ProcessStartInfo("powershell.exe",
                $"""-Sta -ExecutionPolicy Bypass -File "{scriptPath}" """)
            {
                CreateNoWindow = true,
                UseShellExecute = false
            };

            var proc = Process.Start(psi);
            proc?.WaitForExit();
        }
        finally
        {
            try { File.Delete(scriptPath); } catch { }
        }
    }
}
