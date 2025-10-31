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
    Send-TelegramMessage -chatId $chatId -message "Usage: /deletechat [chat_name]"
    exit
}

if ($chatName -eq $script:currentChatSession) {
    Send-TelegramMessage -chatId $chatId -message "Cannot delete the currently active chat session. Please switch to another chat or create a new one first."
    exit
}

try {
    if (Delete-ChatSession -chatName $chatName) {
        Send-TelegramMessage -chatId $chatId -message "Chat session '$chatName' deleted."
    } else {
        Send-TelegramMessage -chatId $chatId -message "Chat session '$chatName' not found."
    }
} catch {
    Send-TelegramMessage -chatId $chatId -message "Error deleting chat session: $($_.Exception.Message)"
}
