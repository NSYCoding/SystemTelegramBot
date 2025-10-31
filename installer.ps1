Param (
    [string]$InstallPath = "$env:ProgramFiles\"
)

Write-Host "Installatie gestart..."

if (!(Test-Path -Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

Copy-Item -Path ".\SystemTelegramBot.exe" -Destination $InstallPath -Force

if (Test-Path -Path "$InstallPath\SystemTelegramBot.exe") {
    Write-Host "Bestand gekopieerd naar $InstallPath"
} else {
    Write-Host "Fout bij het kopiëren van het bestand."
    Copy-Item -Path ".\LICENSE.txt" -Destination $InstallPath -Force
}

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut("$env:USERPROFILE\Desktop\SystemTelegramBot.lnk")
$Shortcut.TargetPath = "$InstallPath\SystemTelegramBot.exe"
$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.Save()

Write-Host "Installatie voltooid. SystemTelegramBot is geïnstalleerd in $InstallPath"
