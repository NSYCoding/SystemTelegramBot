param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$providedPassword = $commandArgs
if ($providedPassword -eq $script:storedPassword) {
    if (Get-Job -Name "LockScreenJob" -ErrorAction SilentlyContinue) {
        Stop-Job -Name "LockScreenJob"
        Remove-Job -Name "LockScreenJob" -Force
        Send-TelegramMessage -chatId $chatId -message "Screen locking stopped successfully."
    }
    else {
        Send-TelegramMessage -chatId $chatId -message "No active screen locking job found."
    }
}
else {
    Send-TelegramMessage -chatId $chatId -message "Incorrect password."
}
