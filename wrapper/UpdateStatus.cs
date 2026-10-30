namespace EwonFlexySdPrep;

/// <summary>
/// État de la mise à jour, partagé entre la tâche de fond et la fenêtre de suivi.
/// </summary>
sealed class UpdateStatus
{
    long received;
    long total;
    volatile string? targetVersion;

    /// <summary>Version en cours de téléchargement ; null tant que la vérification n'a pas abouti.</summary>
    public string? TargetVersion
    {
        get => targetVersion;
        set => targetVersion = value;
    }

    public long Received => Interlocked.Read(ref received);

    /// <summary>Taille totale en octets ; 0 si inconnue.</summary>
    public long Total => Interlocked.Read(ref total);

    public void ReportProgress(long receivedBytes, long totalBytes)
    {
        Interlocked.Exchange(ref received, receivedBytes);
        Interlocked.Exchange(ref total, totalBytes);
    }
}
