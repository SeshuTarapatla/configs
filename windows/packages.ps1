$packages = @(
    "9MZ1SNWT0N5D"
    "9NKSQGP7F2NH"
    "astral-sh.uv"
    "DEVCOM.JetBrainsMonoNerdFont"
    "Git.Git"
    "Google.Antigravity"
    "Microsoft.PowerToys"
    "Microsoft.VisualStudioCode"
    "PostgreSQL.pgAdmin"
    "Python.Python.3.14"
    "qBittorrent.qBittorrent"
    "Spotify.Spotify"
    "SUSE.RancherDesktop"
    "Syncplay.Syncplay"
    "Telegram.TelegramDesktop"
    "VideoLAN.VLC"
    "Zen-Team.Zen-Browser"
)

$packages | ForEach-Object { winget install $_ }
