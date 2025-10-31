param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




try {
    [Audio]::SendMessageA([int]0xFFFF, $script:WM_APPCOMMAND, 0, $script:APPCOMMAND_VOLUME_MUTE)
    Send-TelegramMessage -chatId $chatId -message "System audio mute toggled."
}
catch {
    Send-TelegramMessage -chatId $chatId -message "Error toggling mute: $($_.Exception.Message)"
}
