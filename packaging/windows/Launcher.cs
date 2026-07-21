using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class Launcher
{
    [STAThread]
    private static void Main()
    {
        string installDirectory = AppContext.BaseDirectory;
        string appDirectory = Path.Combine(installDirectory, "app", "game");
        string ruby = Path.Combine(installDirectory, "runtime", "bin", "rubyw.exe");
        string launcher = Path.Combine(appDirectory, "bin", "desktop");

        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = ruby,
                Arguments = $"\"{launcher}\"",
                WorkingDirectory = appDirectory,
                UseShellExecute = false,
                CreateNoWindow = true
            });
        }
        catch (Exception exception)
        {
            MessageBox.Show(
                $"Caesar's Gallic War could not start.\n\n{exception.Message}",
                "Caesar's Gallic War",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error
            );
        }
    }
}
