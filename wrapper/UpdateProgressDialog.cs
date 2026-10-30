using System.Runtime.InteropServices;

namespace EwonFlexySdPrep;

/// <summary>
/// Fenêtre de progression du téléchargement de la mise à jour, construite sur le TaskDialog
/// natif de Windows : WinForms et WPF sont incompatibles avec le trimming de l'exe.
/// Le TaskDialog exige comctl32 v6, activé par app.manifest.
/// </summary>
static class UpdateProgressDialog
{
    const int TDF_ALLOW_DIALOG_CANCELLATION = 0x0008;
    const int TDF_SHOW_PROGRESS_BAR = 0x0200;
    const int TDF_CALLBACK_TIMER = 0x0800;
    const int TDCBF_CANCEL_BUTTON = 0x0008;
    const int IDCANCEL = 2;

    const uint TDN_BUTTON_CLICKED = 2;
    const uint TDN_TIMER = 4;

    const uint WM_USER = 0x0400;
    const uint TDM_CLICK_BUTTON = WM_USER + 102;
    const uint TDM_SET_PROGRESS_BAR_POS = WM_USER + 106;
    const uint TDM_SET_ELEMENT_TEXT = WM_USER + 108;
    const int TDE_CONTENT = 0;

    const int PercentMax = 100;
    const double BytesPerMegabyte = 1024 * 1024;

    delegate int TaskDialogCallback(IntPtr hwnd, uint notification, IntPtr wParam, IntPtr lParam, IntPtr refData);

    // commctrl.h déclare cette structure sous #pragma pack(1)
    [StructLayout(LayoutKind.Sequential, Pack = 1, CharSet = CharSet.Unicode)]
    struct TaskDialogConfig
    {
        public uint cbSize;
        public IntPtr hwndParent;
        public IntPtr hInstance;
        public int dwFlags;
        public int dwCommonButtons;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszWindowTitle;
        public IntPtr hMainIcon;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszMainInstruction;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszContent;
        public uint cButtons;
        public IntPtr pButtons;
        public int nDefaultButton;
        public uint cRadioButtons;
        public IntPtr pRadioButtons;
        public int nDefaultRadioButton;
        public IntPtr pszVerificationText;
        public IntPtr pszExpandedInformation;
        public IntPtr pszExpandedControlText;
        public IntPtr pszCollapsedControlText;
        public IntPtr hFooterIcon;
        public IntPtr pszFooter;
        public IntPtr pfCallback;
        public IntPtr lpCallbackData;
        public uint cxWidth;
    }

    [DllImport("comctl32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    static extern void TaskDialogIndirect(ref TaskDialogConfig config, out int button, out int radioButton, out bool verificationChecked);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr SendMessage(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr SendMessage(IntPtr hwnd, uint msg, IntPtr wParam, string lParam);

    /// <summary>
    /// Affiche la progression jusqu'à la fin de <paramref name="download"/>.
    /// Le bouton Annuler (ou la croix) déclenche <paramref name="cancellation"/>.
    /// </summary>
    public static void Show(string title, string instruction, Func<(long Received, long Total)> progress,
        Task download, CancellationTokenSource cancellation)
    {
        var closingOnCompletion = false;

        TaskDialogCallback callback = (hwnd, notification, _, _, _) =>
        {
            if (notification == TDN_TIMER)
            {
                var (received, total) = progress();
                var percent = total > 0 ? (int)(received * PercentMax / total) : 0;
                SendMessage(hwnd, TDM_SET_PROGRESS_BAR_POS, percent, IntPtr.Zero);
                SendMessage(hwnd, TDM_SET_ELEMENT_TEXT, TDE_CONTENT, ProgressText(received, total));
                if (download.IsCompleted)
                {
                    closingOnCompletion = true;
                    SendMessage(hwnd, TDM_CLICK_BUTTON, IDCANCEL, IntPtr.Zero);
                }
            }
            else if (notification == TDN_BUTTON_CLICKED && !closingOnCompletion)
            {
                cancellation.Cancel();
            }
            return 0;
        };

        var config = new TaskDialogConfig
        {
            cbSize = (uint)Marshal.SizeOf<TaskDialogConfig>(),
            dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_SHOW_PROGRESS_BAR | TDF_CALLBACK_TIMER,
            dwCommonButtons = TDCBF_CANCEL_BUTTON,
            pszWindowTitle = title,
            pszMainInstruction = instruction,
            pszContent = ProgressText(0, 0),
            pfCallback = Marshal.GetFunctionPointerForDelegate(callback)
        };

        TaskDialogIndirect(ref config, out _, out _, out _);
        GC.KeepAlive(callback);
    }

    static string ProgressText(long received, long total) =>
        total > 0
            ? string.Format(WrapperText.Get("DownloadProgress"), received / BytesPerMegabyte, total / BytesPerMegabyte)
            : string.Format(WrapperText.Get("DownloadProgressUnknownSize"), received / BytesPerMegabyte);
}
