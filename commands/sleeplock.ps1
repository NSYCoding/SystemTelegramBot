param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$parts = $commandArgs -split '\s+', 2
if ($parts.Count -lt 1) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /sleeplock [password] [minutes]"
    exit
}
$password = $parts[0]
if ($password -ne $script:storedPassword) {
    Send-TelegramMessage -chatId $chatId -message "Incorrect password."
    exit
}

$totalDuration = 10
if ($parts.Count -gt 1 -and [int]::TryParse($parts[1], [ref]$null)) {
    $totalDuration = [int]$parts[1]
}

if (Get-Job -Name "LockScreenJob" -ErrorAction SilentlyContinue) {
    Stop-Job -Name "LockScreenJob"
    Remove-Job -Name "LockScreenJob" -Force
}

Start-Job -Name "LockScreenJob" -ScriptBlock {
    param($totalMinutes)
    
    $endTime = (Get-Date).AddMinutes($totalMinutes)
    
    rundll32.exe user32.dll, LockWorkStation
    
    while ((Get-Date) -lt $endTime) {
        Start-Sleep -Seconds 1
        rundll32.exe user32.dll, LockWorkStation
    }
} -ArgumentList $totalDuration

Send-TelegramMessage -chatId $chatId -message "Security lock activated. Screen will be locked every minute for the next $totalDuration minutes or until unlocked with /unlocksystem [password]."

rundll32.exe user32.dll, LockWorkStation
