param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$chatName = $commandArgs
if ([string]::IsNullOrWhiteSpace($chatName)) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /loadchat [chat_name]"
    exit
}

$chatPath = Get-ChatSessionPath -chatName $chatName
if (-not (Test-Path -Path $chatPath)) {
    Send-TelegramMessage -chatId $chatId -message "Chat session '$chatName' not found. Use /listchats to see available sessions."
    exit
}

try {
    Set-CurrentChatSession -chatName $chatName
    Send-TelegramMessage -chatId $chatId -message "Switched to chat session: '$chatName'."
} catch {
    Send-TelegramMessage -chatId $chatId -message "Error loading chat session: $($_.Exception.Message)"
}
