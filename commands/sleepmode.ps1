param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



try {
    Send-TelegramMessage -chatId $chatId -message "Sleep mode command received. System will enter sleep mode immediately."
    rundll32.exe user32.dll, LockWorkStation
}
catch {
    Send-TelegramMessage -chatId $chatId -message "Error entering sleep mode: $($_.Exception.Message)"
}
