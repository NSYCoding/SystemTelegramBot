param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




if (-not (Initialize-Ollama)) {
    Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
    exit
}

$models = Get-OllamaModels
if ($models -and $models.Count -gt 0) {
    $modelList = $models | ForEach-Object { $_.name } | Sort-Object
    $modelMessage = "Available models:`n" + ($modelList -join "`n")
    $modelMessage += "`n`nCurrent model: $(if ([string]::IsNullOrEmpty($env:CURRENT_OLLAMA_MODEL)) { 'llama2 (default)' } else { $env:CURRENT_OLLAMA_MODEL })"
    Send-TelegramMessage -chatId $chatId -message $modelMessage
}
else {
    Send-TelegramMessage -chatId $chatId -message "No models found or error retrieving models."
}
