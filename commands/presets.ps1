param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$presetMessage = "Available model presets:`n"
foreach ($preset in $script:modelPresets.GetEnumerator() | Sort-Object Name) {
    $presetMessage += "$($preset.Key): $($preset.Value)`n"
}
$presetMessage += "`nUse /model [number] to quickly switch models."
Send-TelegramMessage -chatId $chatId -message $presetMessage
