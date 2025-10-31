param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$presetNumber = $commandArgs
if ([string]::IsNullOrWhiteSpace($presetNumber)) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /model [1-4]"
    exit
}

Set-OllamaModelPreset -presetNumber $presetNumber -chatId $chatId
