
function global:ConvertTo-PlainText {
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$secureString
    )
    try {
        $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        try {
            return [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        } finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    } catch {
        Write-Host "Error in ConvertTo-PlainText: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}


Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class Audio {
    [DllImport("user32.dll")]
    public static extern int SendMessageA(int hWnd, int wMsg, int wParam, int lParam);
}
'@


$APPCOMMAND_VOLUME_MUTE = 0x80000
$WM_APPCOMMAND = 0x319


try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Write-Host "Error loading required assemblies System.Windows.Forms/System.Drawing: $($_.Exception.Message)" -ForegroundColor Red
}

function Send-TelegramMessage {
    param (
        [string]$chatId,
        [string]$message
    )
    
    if ([string]::IsNullOrWhiteSpace($script:botToken)) {
        Write-Host "Error: Telegram bot token not set in script scope for Send-TelegramMessage." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($message)) {
        Write-Host "Warning: Attempted to send empty message to Telegram" -ForegroundColor Yellow
        return
    }
    
    $telegramMaxLength = 4000
    $url = "https://api.telegram.org/bot$script:botToken/sendMessage"
    
    try {
        if ($message.Length -gt $telegramMaxLength) {
            Write-Host "Message exceeds Telegram length limit, splitting into chunks" -ForegroundColor Yellow
            
            for ($i = 0; $i -lt $message.Length; $i += $telegramMaxLength) {
                $chunk = $message.Substring($i, [Math]::Min($telegramMaxLength, $message.Length - $i))
                $body = @{
                    chat_id = $chatId
                    text    = $chunk
                }
                Invoke-RestMethod -Uri $url -Method Post -Body $body
                Start-Sleep -Milliseconds 500
            }
        } else {
            $body = @{
                chat_id = $chatId
                text    = $message
            }
            Invoke-RestMethod -Uri $url -Method Post -Body $body
        }
    } catch {
        Write-Host "Error sending Telegram message: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function global:Get-Updates {
    param (
        [int]$offset,
        [int]$limit = 100,
        [int]$timeout = 0
    )
    
    if ([string]::IsNullOrWhiteSpace($script:botToken)) {
        Write-Host "Error: Telegram bot token not set in script scope for Get-Updates." -ForegroundColor Red
        return $null
    }

    $url = "https://api.telegram.org/bot$script:botToken/getUpdates"
    $params = @{}
    if ($offset -ne $null) { $params.Add("offset", $offset) }
    if ($limit -ne $null) { $params.Add("limit", $limit) }
    if ($timeout -ne $null) { $params.Add("timeout", $timeout) }

    if ($params.Count -gt 0) {
        $queryString = ($params.Keys | ForEach-Object { "$_=" + $params[$_] }) -join "&"
        $url += "?" + $queryString
    }
    
    try {
        $result = Invoke-RestMethod -Uri $url -Method Get
        return $result.result
    } catch {
        Write-Host "Error getting Telegram updates: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}


$script:ollamaLogDir = "C:\Ollama"
if (-not (Test-Path -Path $script:ollamaLogDir)) {
    New-Item -Path $script:ollamaLogDir -ItemType Directory -Force | Out-Null
}
$script:inputFile = "$script:ollamaLogDir\input_log.txt"
$script:outputFile = "$script:ollamaLogDir\output_log.txt"
if (-not (Test-Path -Path $script:inputFile)) {
    New-Item -Path $script:inputFile -ItemType File -Force | Out-Null
}
if (-not (Test-Path -Path $script:outputFile)) {
    New-Item -Path $script:outputFile -ItemType File -Force | Out-Null
}

$script:port = 11434
$script:ollamaServer = "http://localhost:$script:port"

$script:modelPresets = @{
    "1" = "llama2"
    "2" = "llama3"
    "3" = "mistral"
    "4" = "gemma"
}

$script:modelFile = "$script:ollamaLogDir\current_model.txt"
if (Test-Path -Path $script:modelFile) {
    try {
        $env:CURRENT_OLLAMA_MODEL = Get-Content -Path $script:modelFile -Raw
        $env:CURRENT_OLLAMA_MODEL = $env:CURRENT_OLLAMA_MODEL.Trim()
        Write-Host "Loaded model preference: $env:CURRENT_OLLAMA_MODEL" -ForegroundColor Green
    } catch {
        Write-Host "Error loading model preference: $($_.Exception.Message)" -ForegroundColor Red
        $env:CURRENT_OLLAMA_MODEL = "llama2"
    }
} else {
    $env:CURRENT_OLLAMA_MODEL = "llama2"
}


$script:chatSessionsDir = Join-Path -Path $script:ollamaLogDir -ChildPath "chats"
if (-not (Test-Path -Path $script:chatSessionsDir)) {
    New-Item -Path $script:chatSessionsDir -ItemType Directory -Force | Out-Null
}
$script:currentChatSessionFile = Join-Path -Path $script:ollamaLogDir -ChildPath "current_chat.txt"
$script:currentChatSession = "default"


if (Test-Path -Path $script:currentChatSessionFile) {
    try {
        $script:currentChatSession = (Get-Content -Path $script:currentChatSessionFile -Raw | Select-Object -First 1).Trim()
        Write-Host "Loaded current chat session: $($script:currentChatSession)" -ForegroundColor Green
    } catch {
        Write-Host "Error loading current chat session: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-ChatSessionPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$chatName
    )
    return Join-Path -Path $script:chatSessionsDir -ChildPath "$chatName.json"
}

function Save-ChatSession {
    param(
        [Parameter(Mandatory=$true)]
        [string]$chatName,
        [Parameter(Mandatory=$true)]
        $chatHistory 
    )
    $chatPath = Get-ChatSessionPath -chatName $chatName
    $chatHistory | ConvertTo-Json -Depth 100 | Set-Content -Path $chatPath -Force
}

function Load-ChatSession {
    param(
        [Parameter(Mandatory=$true)]
        [string]$chatName
    )
    $chatPath = Get-ChatSessionPath -chatName $chatName
    if (Test-Path -Path $chatPath) {
        return (Get-Content -Path $chatPath | ConvertFrom-Json)
    }
    return @()
}

function List-ChatSessions {
    $chatFiles = Get-ChildItem -Path $script:chatSessionsDir -Filter "*.json" | Select-Object -ExpandProperty BaseName
    return $chatFiles | ForEach-Object { $_ -replace '\.json$', '' }
}

function Delete-ChatSession {
    param(
        [Parameter(Mandatory=$true)]
        [string]$chatName
    )
    $chatPath = Get-ChatSessionPath -chatName $chatName
    if (Test-Path -Path $chatPath) {
        Remove-Item -Path $chatPath -Force
        return $true
    }
    return $false
}

function Set-CurrentChatSession {
    param(
        [Parameter(Mandatory=$true)]
        [string]$chatName
    )
    $script:currentChatSession = $chatName
    Set-Content -Path $script:currentChatSessionFile -Value $chatName -Force
}

function Send-OllamaMessage {
    param (
        [string]$userMessage,
        [string]$modelName = $env:CURRENT_OLLAMA_MODEL,
        [array]$chatHistory = @()
    )
    
    if ([string]::IsNullOrEmpty($modelName)) {
        $modelName = "llama2"
    }
    
    $apiEndpoint = "$script:ollamaServer/api/chat"
    
    $messages = @()
    foreach ($entry in $chatHistory) {
        $messages += @{ role = $entry.role; content = $entry.content }
    }
    $messages += @{ role = "user"; content = $userMessage }

    $requestBody = @{
        model    = $modelName
        messages = $messages
        stream   = $false
    } | ConvertTo-Json -Depth 100 -Compress
    
    try {
        $response = Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $requestBody -ContentType "application/json; charset=utf-8"
        return $response.message.content
    } catch {
        $errorDetails = $_.ErrorDetails.Message
        Write-Host "Error communicating with Ollama: $($_.Exception.Message)" -ForegroundColor Red
        if ($errorDetails) {
            Write-Host "Server response: $errorDetails" -ForegroundColor Red
        }
        return "Error: Could not get a response from Ollama."
    }
}

function Initialize-Ollama {
    try {
        $healthEndpoint = "$script:ollamaServer/api/tags"
        Invoke-RestMethod -Uri $healthEndpoint -Method Get -TimeoutSec 5
        Write-Host "Successfully connected to Ollama server. $script:ollamaServer" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Cannot connect to Ollama server at $script:ollamaServer" -ForegroundColor Red
        Write-Host "Make sure Ollama is running and accessible." -ForegroundColor Red
        return $false
    }
}

function Get-OllamaModels {
    try {
        $modelsEndpoint = "$script:ollamaServer/api/tags"
        $response = Invoke-RestMethod -Uri $modelsEndpoint -Method Get -TimeoutSec 5
        return $response.models
    } catch {
        Write-Host "Error retrieving Ollama models: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Set-OllamaModelPreset {
    param (
        [string]$presetNumber,
        [string]$chatId
    )
    
    if (-not $script:modelPresets.ContainsKey($presetNumber)) {
        Send-TelegramMessage -chatId $chatId -message "Invalid preset number. Available presets: 1-4"
        return $false
    }
    
    $modelName = $script:modelPresets[$presetNumber]
    
    if (-not (Initialize-Ollama)) {
        Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
        return $false
    }
    
    $models = Get-OllamaModels
    $modelExists = $models | Where-Object { $_.name -eq $modelName }
    
    if (-not $modelExists) {
        Send-TelegramMessage -chatId $chatId -message "Model '$modelName' from preset $presetNumber is not available. Use /models to see available models or pull it with 'ollama pull $modelName'."
        return $false
    }
    
    $env:CURRENT_OLLAMA_MODEL = $modelName
    try {
        $modelFile = "$script:ollamaLogDir\current_model.txt"
        Set-Content -Path $modelFile -Value $modelName -Force
        Send-TelegramMessage -chatId $chatId -message "Model set to: $modelName (preset $presetNumber)"
        return $true
    } catch {
        Write-Host "Error saving model preference: $($_.Exception.Message)" -ForegroundColor Red
        Send-TelegramMessage -chatId $chatId -message "Model set to: $modelName (preset $presetNumber, not saved to file)"
        return $true
    }
}

function Write-UserInput {
    param (
        [string]$userInput,
        [string]$modelResponse
    )
    try {
        
        $chatPath = Get-ChatSessionPath -chatName $script:currentChatSession
        $chatHistory = Load-ChatSession -chatName $script:currentChatSession
        $chatHistory += @{ role = "user"; content = $userInput }
        $chatHistory += @{ role = "assistant"; content = $modelResponse }
        Save-ChatSession -chatName $script:currentChatSession -chatHistory $chatHistory

        Write-Host "Ollama: $modelResponse" -ForegroundColor Green
    } catch {
        Write-Host "Error writing user input to chat session: $($_.Exception.Message)" -ForegroundColor Red
    }
}

