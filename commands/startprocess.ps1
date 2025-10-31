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
        Start-Process $processName
        Send-TelegramMessage -chatId $chatId -message "Started process: $processName"
    }
    catch {
        Send-TelegramMessage -chatId $chatId -message "Error starting process '$processName': $($_.Exception.Message)"
    }
}
else {
    Send-TelegramMessage -chatId $chatId -message "Usage: /startprocess [process_name]"
}
