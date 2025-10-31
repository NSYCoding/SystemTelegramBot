param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$modelName = $commandArgs
if ([string]::IsNullOrWhiteSpace($modelName)) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /setmodel [model_name]"
    exit
}

if (-not (Initialize-Ollama)) {
    Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
    exit
}

$models = Get-OllamaModels
$modelExists = $models | Where-Object { $_.name -eq $modelName }

if ($modelExists) {
    $env:CURRENT_OLLAMA_MODEL = $modelName
    try {
        
        $modelFile = "$script:ollamaLogDir\current_model.txt"
        Set-Content -Path $modelFile -Value $modelName -Force
        Send-TelegramMessage -chatId $chatId -message "Model set to: $modelName"
    }
    catch {
        Write-Host "Error saving model preference: $($_.Exception.Message)" -ForegroundColor Red
        Send-TelegramMessage -chatId $chatId -message "Model set to: $modelName (not saved to file)"
    }
}
else {
    Send-TelegramMessage -chatId $chatId -message "Model '$modelName' not found. Use /models to see available models."
}
