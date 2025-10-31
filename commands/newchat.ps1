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
    Send-TelegramMessage -chatId $chatId -message "Usage: /newchat [chat_name]"
    exit
}

$chatPath = Get-ChatSessionPath -chatName $chatName
if (Test-Path -Path $chatPath) {
    Send-TelegramMessage -chatId $chatId -message "Chat session '$chatName' already exists. Loading it instead. Use /loadchat to explicitly load an existing chat."
    Set-CurrentChatSession -chatName $chatName
    Send-TelegramMessage -chatId $chatId -message "Switched to chat session: '$chatName'."
    exit
}

try {
    
    Save-ChatSession -chatName $chatName -chatHistory @()
    Set-CurrentChatSession -chatName $chatName
    Send-TelegramMessage -chatId $chatId -message "New chat session '$chatName' created and activated."
} catch {
    Send-TelegramMessage -chatId $chatId -message "Error creating new chat session: $($_.Exception.Message)"
}
