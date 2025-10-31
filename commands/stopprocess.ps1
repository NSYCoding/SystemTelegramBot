param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$processName = $commandArgs
if ($processName) {
    try {
        Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
        Send-TelegramMessage -chatId $chatId -message "Stopped process: $processName"
    }
    catch {
        Send-TelegramMessage -chatId $chatId -message "Error stopping process '$processName': $($_.Exception.Message)"
    }
}
else {
    Send-TelegramMessage -chatId $chatId -message "Usage: /stopprocess [process_name]"
}
