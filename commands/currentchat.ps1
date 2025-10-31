param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



Send-TelegramMessage -chatId $chatId -message "Current chat session: '$script:currentChatSession'."
