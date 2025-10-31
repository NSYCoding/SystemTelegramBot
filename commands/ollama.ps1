param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$ollamaInput = $commandArgs
if ([string]::IsNullOrWhiteSpace($ollamaInput)) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /ollama [your_message]"
    exit
}

if (-not (Initialize-Ollama)) {
    Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
    exit
}

$modelToUse = $env:CURRENT_OLLAMA_MODEL
if ([string]::IsNullOrEmpty($modelToUse)) {
    $modelToUse = "llama2"
}


$currentChatHistory = Load-ChatSession -chatName $script:currentChatSession

$ollamaResponse = Send-OllamaMessage -userMessage $ollamaInput -modelName $modelToUse -chatHistory $currentChatHistory
Send-TelegramMessage -chatId $chatId -message "Ollama ($modelToUse) says: $ollamaResponse"


Write-UserInput -userInput $ollamaInput -modelResponse $ollamaResponse
