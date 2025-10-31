param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



try {
    $chatSessions = List-ChatSessions
    if ($chatSessions.Count -gt 0) {
        $chatListMessage = "Available chat sessions:`n"
        foreach ($session in $chatSessions | Sort-Object) {
            $chatListMessage += "- $session"
            if ($session -eq $script:currentChatSession) {
                $chatListMessage += " (current)"
            }
            $chatListMessage += "`n"
        }
        Send-TelegramMessage -chatId $chatId -message $chatListMessage
    } else {
        Send-TelegramMessage -chatId $chatId -message "No chat sessions found. Use /newchat [name] to create one."
    }
} catch {
    Send-TelegramMessage -chatId $chatId -message "Error listing chat sessions: $($_.Exception.Message)"
}
