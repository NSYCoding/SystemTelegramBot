Import-Module CredentialManager

function ConvertTo-PlainText {
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$secureString
    )
    $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}
#endregion

#region Setup and Configuration
$ollamaLogDir = "C:\Ollama"
if (-not (Test-Path -Path $ollamaLogDir)) {
    New-Item -Path $ollamaLogDir -ItemType Directory -Force | Out-Null
}
$inputFile = "$ollamaLogDir\input_log.txt"
$outputFile = "$ollamaLogDir\output_log.txt"
if (-not (Test-Path -Path $inputFile)) {
    New-Item -Path $inputFile -ItemType File -Force | Out-Null
}
if (-not (Test-Path -Path $outputFile)) {
    New-Item -Path $outputFile -ItemType File -Force | Out-Null
}

$botTokenCred = Get-StoredCredential -Target "SystemTelegramBot_BOTTOKEN"
$botToken = ConvertTo-PlainText $botTokenCred.Password

$adminIdCred = Get-StoredCredential -Target "SystemTelegramBot_ADMINID"
$adminId = ConvertTo-PlainText $adminIdCred.Password

$passwordCred = Get-StoredCredential -Target "SystemTelegramBot_PASSWORD"
$storedPassword = ConvertTo-PlainText $passwordCred.Password

Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class Audio {
    [DllImport("user32.dll")]
    public static extern int SendMessageA(int hWnd, int wMsg, int wParam, int lParam);
}
'@

$APPCOMMAND_VOLUME_MUTE = 0x80000
$WM_APPCOMMAND = 0x319

$port = 11434
$ollamaServer = "http://localhost:$port"

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Host "Error loading required assemblies: $($_.Exception.Message)" -ForegroundColor Red
}

$modelPresets = @{
    "1" = "llama2"
    "2" = "llama3"
    "3" = "mistral"
    "4" = "gemma"
}

$modelFile = "$ollamaLogDir\current_model.txt"
if (Test-Path -Path $modelFile) {
    try {
        $env:CURRENT_OLLAMA_MODEL = Get-Content -Path $modelFile -Raw
        $env:CURRENT_OLLAMA_MODEL = $env:CURRENT_OLLAMA_MODEL.Trim()
        Write-Host "Loaded model preference: $env:CURRENT_OLLAMA_MODEL" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading model preference: $($_.Exception.Message)" -ForegroundColor Red
        $env:CURRENT_OLLAMA_MODEL = "llama2"
    }
}
else {
    $env:CURRENT_OLLAMA_MODEL = "llama2"
}
#endregion

#region Ollama Functions
function Send-OllamaMessage {
    param (
        [string]$userMessage,
        [string]$modelName = $env:CURRENT_OLLAMA_MODEL
    )
    
    if ([string]::IsNullOrEmpty($modelName)) {
        $modelName = "llama2"
    }
    
    $apiEndpoint = "$ollamaServer/api/generate"
    $promptText = "You are an assistant for User message: $userMessage"
    
    $requestBody = @{
        model  = $modelName
        prompt = $promptText
        stream = $false
    } | ConvertTo-Json -Depth 10 -Compress
    
    try {
        $response = Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $requestBody -ContentType "application/json; charset=utf-8"
        return $response.response
    }
    catch {
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
        $healthEndpoint = "$ollamaServer/api/tags"
        Invoke-RestMethod -Uri $healthEndpoint -Method Get -TimeoutSec 5
        Write-Host "Successfully connected to Ollama server. $ollamaServer" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Cannot connect to Ollama server at $ollamaServer" -ForegroundColor Red
        Write-Host "Make sure Ollama is running and accessible." -ForegroundColor Red
        return $false
    }
}

function Get-OllamaModels {
    try {
        $modelsEndpoint = "$ollamaServer/api/tags"
        $response = Invoke-RestMethod -Uri $modelsEndpoint -Method Get -TimeoutSec 5
        return $response.models
    }
    catch {
        Write-Host "Error retrieving Ollama models: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Set-OllamaModelPreset {
    param (
        [string]$presetNumber,
        [string]$chatId
    )
    
    if (-not $modelPresets.ContainsKey($presetNumber)) {
        Send-TelegramMessage -chatId $chatId -message "Invalid preset number. Available presets: 1-4"
        return $false
    }
    
    $modelName = $modelPresets[$presetNumber]
    
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
        $modelFile = "$ollamaLogDir\current_model.txt"
        Set-Content -Path $modelFile -Value $modelName -Force
        Send-TelegramMessage -chatId $chatId -message "Model set to: $modelName (preset $presetNumber)"
        return $true
    }
    catch {
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
        Write-Host "Ollama: $modelResponse" -ForegroundColor Green
    }
    catch {
        Write-Host "Error writing user input." -ForegroundColor Red
    }
}
#endregion

#region Telegram Functions
function Send-TelegramMessage {
    param (
        [string]$chatId,
        [string]$message
    )
    
    if ([string]::IsNullOrWhiteSpace($message)) {
        Write-Host "Warning: Attempted to send empty message to Telegram" -ForegroundColor Yellow
        return
    }
    
    $telegramMaxLength = 4000
    $url = "https://api.telegram.org/bot$botToken/sendMessage"
    
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
        }
        else {
            $body = @{
                chat_id = $chatId
                text    = $message
            }
            Invoke-RestMethod -Uri $url -Method Post -Body $body
        }
    }
    catch {
        Write-Host "Error sending Telegram message: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-Updates {
    param ([int]$offset)
    $url = "https://api.telegram.org/bot$botToken/getUpdates"
    if ($offset -ne $null) {
        $url += "?offset=$offset"
    }
    $result = Invoke-RestMethod -Uri $url -Method Get
    return $result.result
}
#endregion

Write-Host "Bot started. Monitoring for commands..."
$lastUpdateId = 0

#region Main Loop
while ($true) {
    $updates = Get-Updates -offset $lastUpdateId

    foreach ($update in $updates) {
        $message = $update.message.text
        $chatId = $update.message.chat.id
        $lastUpdateId = $update.update_id + 1

        Write-Host "Received message: $message"

        if ($chatId -eq $adminId) {
            switch -Wildcard ($message) {
                "/start" {
                    $me = (whoami).Split('\')[1]
                    $me = $me.Substring(0, 1).ToUpper() + $me.Substring(1)
                    $currentHour = (Get-Date).Hour
                    if ($currentHour -ge 6 -and $currentHour -lt 12) {
                        $greetTime = "Good morning, $me"
                    }
                    elseif ($currentHour -ge 12 -and $currentHour -lt 18) {
                        $greetTime = "Good afternoon, $me"
                    }
                    elseif ($currentHour -ge 18 -and $currentHour -lt 22) {
                        $greetTime = "Good evening, $me"
                    }
                    else {
                        $greetTime = "Good night $me"
                    }
                    Send-TelegramMessage -chatId $chatId -message "Welcome to the System Telegram Bot! $greetTime! Type /help for available commands."
                }
                "/screenshot" {
                    try {
                        $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
                        $Width = $Screen.Width
                        $Height = $Screen.Height
                        $ScreenWidth = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width
                        $ScreenHeight = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height
                        $Left = [Math]::Max(0, ($ScreenWidth - $Width) / 2)
                        $Top = [Math]::Max(0, ($ScreenHeight - $Height) / 2)
                        $Width = [Math]::Min($Width, $ScreenWidth)
                        $Height = [Math]::Min($Height, $ScreenHeight)
                        $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
                        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                        $graphics.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
                        $screenshotPath = Join-Path -Path $pwd -ChildPath "screenshot.png"
                        $bitmap.Save($screenshotPath)
                        $graphics.Dispose()
                        $bitmap.Dispose()

                        $fileUrl = "https://api.telegram.org/bot$botToken/sendPhoto"
                        $fileBinary = [System.IO.File]::ReadAllBytes($screenshotPath)
                        $boundary = [System.Guid]::NewGuid().ToString()
                        $LF = "`r`n"
                        
                        $bodyLines = @(
                            "--$boundary",
                            "Content-Disposition: form-data; name=`"chat_id`"",
                            "",
                            $chatId,
                            "--$boundary",
                            "Content-Disposition: form-data; name=`"photo`"; filename=`"screenshot.png`"",
                            "Content-Type: image/png",
                            "",
                            [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBinary),
                            "--$boundary--"
                        ) -join $LF
                        
                        $contentType = "multipart/form-data; boundary=$boundary"
                        
                        $response = Invoke-RestMethod -Uri $fileUrl -Method Post -ContentType $contentType -Body $bodyLines
                        Send-TelegramMessage -chatId $chatId -message "Screenshot taken successfully."
                        
                        Remove-Item -Path $screenshotPath -Force
                    }
                    catch {
                        Send-TelegramMessage -chatId $chatId -message "Error taking screenshot: $($_.Exception.Message)"
                        if ($_.Exception.Response) {
                            $responseBody = $_.Exception.Response.GetResponseStream()
                            $reader = New-Object System.IO.StreamReader($responseBody)
                            $responseText = $reader.ReadToEnd()
                            Write-Host "Response detail: $responseText" -ForegroundColor Red
                        }
                        continue
                    }
                }
                "/getprocesses" {
                    try {
                        $tempDir = [System.IO.Path]::GetTempPath()
                        $processFile = Join-Path -Path $tempDir -ChildPath "processes_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
                        
                        $processes = Get-Process | Select-Object -Property Name, Id, CPU, WorkingSet, StartTime | Sort-Object -Property CPU -Descending
                        $processList = "SYSTEM PROCESSES REPORT`r`n`r`nGenerated: $(Get-Date)`r`n`r`n"
                        $processList += $processes | Format-Table -AutoSize | Out-String
                        
                        Set-Content -Path $processFile -Value $processList -Force
                        
                        $fileUrl = "https://api.telegram.org/bot$botToken/sendDocument"
                        $fileBinary = [System.IO.File]::ReadAllBytes($processFile)
                        $boundary = [System.Guid]::NewGuid().ToString()
                        $LF = "`r`n"
                        
                        $bodyLines = @(
                            "--$boundary",
                            "Content-Disposition: form-data; name=`"chat_id`"",
                            "",
                            $chatId,
                            "--$boundary",
                            "Content-Disposition: form-data; name=`"document`"; filename=`"processes.txt`"",
                            "Content-Type: text/plain",
                            "",
                            [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBinary),
                            "--$boundary--"
                        ) -join $LF
                        
                        $contentType = "multipart/form-data; boundary=$boundary"
                        $response = Invoke-RestMethod -Uri $fileUrl -Method Post -ContentType $contentType -Body $bodyLines
                        
                        Send-TelegramMessage -chatId $chatId -message "Processes saved and sent as text file."
                    }
                    catch {
                        Send-TelegramMessage -chatId $chatId -message "Error getting processes: $($_.Exception.Message)"
                    }
                    finally {
                        if (Test-Path -Path $processFile) {
                            Remove-Item -Path $processFile -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                "/startprocess*" {
                    $processName = $message -replace "/startprocess ", ""
                    if ($processName) {
                        Start-Process $processName
                        Send-TelegramMessage -chatId $chatId -message "Started process: $processName"
                    }
                    else {
                        Send-TelegramMessage -chatId $chatId -message "Usage: /startprocess [process_name]"
                    }
                }
                "/stopprocess*" {
                    $processName = $message -replace "/stopprocess ", ""
                    if ($processName) {
                        Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
                        Send-TelegramMessage -chatId $chatId -message "Stopped process: $processName"
                    }
                    else {
                        Send-TelegramMessage -chatId $chatId -message "Usage: /stopprocess [process_name]"
                    }
                }
                "/systemstatus" {
                    $cpu = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
                    $drives = Get-PSDrive -PSProvider FileSystem
                    $drivesInfo = foreach ($drive in $drives) {

                        $freeSpace = $drive.Free / 1GB
                        "$($drive.Name): {0:N2} GB free" -f $freeSpace
                    }
                    $drivesText = $drivesInfo -join "`n"
                    $response = "CPU Load: $cpu%`nFree Disk Space:`n$drivesText"
                    Send-TelegramMessage -chatId $chatId -message $response
                    $response = "CPU Load: $cpu%`nFree Disk (C:): {0:N2} GB" -f $freeDisk
                    Send-TelegramMessage -chatId $chatId -message $response
                }
                "/sleepmode" {
                    Send-TelegramMessage -chatId $chatId -message "Sleep mode command received. System will enter sleep mode immediately."
                    rundll32.exe user32.dll, LockWorkStation
                }
                "/sleepmodetime*" {
                    $sleepTime = $message -replace "/sleepmodetime ", ""
                    $maxSleepMinutes = 1440
                    if ([int]::TryParse($sleepTime, [ref]$null) -and [int]$sleepTime -gt 0) {
                        if ([int]$sleepTime -gt $maxSleepMinutes) {
                            Send-TelegramMessage -chatId $chatId -message "Sleep time too long. Maximum is $maxSleepMinutes minutes (24 hours)."
                            continue
                        }
                        Send-TelegramMessage -chatId $chatId -message "Sleep mode command received. System will enter sleep mode in $sleepTime minutes."
                        if (Get-Job -Name "SleepModeJob" -ErrorAction SilentlyContinue) {
                            Stop-Job -Name "SleepModeJob"
                            Remove-Job -Name "SleepModeJob" -Force
                        }
                        Start-Job -Name "SleepModeJob" -ScriptBlock {
                            param($minutes)
                            Start-Sleep -Seconds ($minutes * 60)
                            rundll32.exe user32.dll, LockWorkStation
                        } -ArgumentList ([int]$sleepTime)
                    }
                    else {
                        Send-TelegramMessage -chatId $chatId -message "Invalid sleep time. Please provide a positive number of minutes."
                    }
                }
                "/sleeplock*" {
                    $parts = $message -replace "/sleeplock ", "" -split '\s+', 2
                    if ($parts.Count -lt 1) {
                        Send-TelegramMessage -chatId $chatId -message "Usage: /sleeplock [password] [minutes]"
                        continue
                    }
                    $password = $parts[0]
                    if ($password -ne $storedPassword) {
                        Send-TelegramMessage -chatId $chatId -message "Incorrect password."
                        continue
                    }
                    
                    $totalDuration = 10
                    if ($parts.Count -gt 1 -and [int]::TryParse($parts[1], [ref]$null)) {
                        $totalDuration = [int]$parts[1]
                    }
                    
                    if (Get-Job -Name "LockScreenJob" -ErrorAction SilentlyContinue) {
                        Stop-Job -Name "LockScreenJob"
                        Remove-Job -Name "LockScreenJob" -Force
                    }
                    
                    Start-Job -Name "LockScreenJob" -ScriptBlock {
                        param($totalMinutes)
                        
                        $endTime = (Get-Date).AddMinutes($totalMinutes)
                        
                        rundll32.exe user32.dll, LockWorkStation
                        
                        while ((Get-Date) -lt $endTime) {
                            Start-Sleep -Seconds 1
                            rundll32.exe user32.dll, LockWorkStation
                        }
                    } -ArgumentList $totalDuration
                    
                    Send-TelegramMessage -chatId $chatId -message "Security lock activated. Screen will be locked every minute for the next $totalDuration minutes or until unlocked with /unlocksystem [password]."
                    
                    rundll32.exe user32.dll, LockWorkStation
                }
                "/unlocksystem*" {
                    $providedPassword = $message -replace "/unlocksystem ", ""
                    if ($providedPassword -eq $storedPassword) {
                        if (Get-Job -Name "LockScreenJob" -ErrorAction SilentlyContinue) {
                            Stop-Job -Name "LockScreenJob"
                            Remove-Job -Name "LockScreenJob" -Force
                            Send-TelegramMessage -chatId $chatId -message "Screen locking stopped successfully."
                        }
                        else {
                            Send-TelegramMessage -chatId $chatId -message "No active screen locking job found."
                        }
                    }
                    else {
                        Send-TelegramMessage -chatId $chatId -message "Incorrect password."
                    }
                }
                "/ollama*" {
                    $ollamaInput = $message -replace "/ollama ", ""
                    if (-not (Initialize-Ollama)) {
                        Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
                        continue
                    }
                    
                    $modelToUse = $env:CURRENT_OLLAMA_MODEL
                    if ([string]::IsNullOrEmpty($modelToUse)) {
                        $modelToUse = "llama2"
                    }
                    
                    $ollamaResponse = Send-OllamaMessage -userMessage $ollamaInput -modelName $modelToUse
                    Send-TelegramMessage -chatId $chatId -message "Ollama ($modelToUse) says: $ollamaResponse"
                    
                    try {
                        Add-Content -Path $inputFile -Value $ollamaInput
                        Add-Content -Path $outputFile -Value $ollamaResponse
                    }
                    catch {
                        Write-Host "Error logging Ollama interaction: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                "/models" {
                    if (-not (Initialize-Ollama)) {
                        Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
                        continue
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
                }
                "/setmodel*" {
                    $modelName = $message -replace "/setmodel ", ""
                    if ([string]::IsNullOrWhiteSpace($modelName)) {
                        Send-TelegramMessage -chatId $chatId -message "Usage: /setmodel [model_name]"
                        continue
                    }
                    
                    if (-not (Initialize-Ollama)) {
                        Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
                        continue
                    }
                    
                    $models = Get-OllamaModels
                    $modelExists = $models | Where-Object { $_.name -eq $modelName }
                    
                    if ($modelExists) {
                        $env:CURRENT_OLLAMA_MODEL = $modelName
                        try {
                            $modelFile = "$ollamaLogDir\current_model.txt"
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
                }
                "/model*" {
                    $presetNumber = $message -replace "/model ", ""
                    if ([string]::IsNullOrWhiteSpace($presetNumber)) {
                        Send-TelegramMessage -chatId $chatId -message "Usage: /model [1-4]"
                        continue
                    }
                    
                    Set-OllamaModelPreset -presetNumber $presetNumber -chatId $chatId
                }
                "/presets" {
                    $presetMessage = "Available model presets:`n"
                    foreach ($preset in $modelPresets.GetEnumerator() | Sort-Object Name) {
                        $presetMessage += "$($preset.Key): $($preset.Value)`n"
                    }
                    $presetMessage += "`nUse /model [number] to quickly switch models."
                    Send-TelegramMessage -chatId $chatId -message $presetMessage
                }
                "/deletechat" {
                    if (Test-Path -Path $inputFile) {
                        Remove-Item -Path $inputFile -Force
                        Send-TelegramMessage -chatId $chatId -message "Input log deleted."
                    }
                    else {
                        Send-TelegramMessage -chatId $chatId -message "Input log not found."
                    }
                    if (Test-Path -Path $outputFile) {
                        Remove-Item -Path $outputFile -Force
                        Send-TelegramMessage -chatId $chatId -message "Output log deleted."
                    }
                    else {
                        Send-TelegramMessage -chatId $chatId -message "Output log not found."
                    }

                }
                "/mute" {
                    try {
                        [Audio]::SendMessageA([int]0xFFFF, $WM_APPCOMMAND, 0, $APPCOMMAND_VOLUME_MUTE)
                        Send-TelegramMessage -chatId $chatId -message "System audio mute toggled."
                    }
                    catch {
                        Send-TelegramMessage -chatId $chatId -message "Error toggling mute: $($_.Exception.Message)"
                    }
                }
                "/help" {
                    $helpMessage = "Available commands:
    /start - Welcome message
    /systemstatus - CPU load and disk space
    /mute - Toggles system audio
    /screenshot - Takes and sends a screenshot
    /getprocesses - Lists running processes
    /startprocess [process_name] - Starts a process
    /stopprocess [process_name] - Stops a process
    /sleepmode - Immediately locks the workstation
    /sleepmodetime [minutes] - Locks the system after specified minutes
    /sleeplock [password] [minutes] - Locks screen periodically
    /unlocksystem [password] - Stops screen locking
    /ollama [message] - Chat with Ollama assistant
    /models - List available Ollama models
    /setmodel [model_name] - Select Ollama model to use
    /model [1-4] - Quick model switch with presets
    /presets - Show available model presets
    /deletechat - Deletes chat logs
    /help - Shows this help message"
                    Send-TelegramMessage -chatId $chatId -message $helpMessage
                }
                default {
                    if ($message -like "/help*") {
                        $helpMessage = "Available commands:
    /start - Welcome message
    /systemstatus - CPU load and disk space
    /mute - Toggles system audio
    /screenshot - Takes and sends a screenshot
    /getprocesses - Lists running processes
    /startprocess [process_name] - Starts a process
    /stopprocess [process_name] - Stops a process
    /sleepmode - Immediately locks the workstation
    /sleepmodetime [minutes] - Locks the system after specified minutes
    /sleeplock [password] [minutes] - Locks screen periodically
    /lockscreenprocess - Checks for YouTube processes
    /unlocksystem [password] - Stops screen locking
    /ollama [message] - Chat with Ollama assistant
    /models - List available Ollama models
    /setmodel [model_name] - Select Ollama model to use
    /model [1-4] - Quick model switch with presets
    /presets - Show available model presets
    /delete - Deletes the last log entry
    /help - Shows this help message"
                        Send-TelegramMessage -chatId $chatId -message $helpMessage
                    }
                    else {
                        $command = $message -replace "/"
                        if ($command -eq "exit") {
                            Send-TelegramMessage -chatId $chatId -message "Exiting the bot."
                            exit
                        }
                        else {
                            if (-not (Initialize-Ollama)) {
                                Send-TelegramMessage -chatId $chatId -message "Error: Cannot connect to Ollama server."
                                continue
                            }
                            
                            $chatIdFile = "$ollamaLogDir\chat_id.txt"
                            if (-not (Test-Path -Path $chatIdFile)) {
                                New-Item -Path $chatIdFile -ItemType File -Force | Out-Null
                                Set-Content -Path $chatIdFile -Value $chatId
                            }
                            
                            if (-not (Get-Variable -Name context -ErrorAction SilentlyContinue)) {
                                $context = ""
                            }
                            
                            $modelToUse = $env:CURRENT_OLLAMA_MODEL
                            if ([string]::IsNullOrEmpty($modelToUse)) {
                                $modelToUse = "llama2"
                            }
                            
                            $fullPrompt = "$context User request: $command"
                            $ollamaResponse = Send-OllamaMessage -userMessage $fullPrompt -modelName $modelToUse
                            Send-TelegramMessage -chatId $chatId -message "Ollama ($modelToUse) says: $ollamaResponse"
                            Write-UserInput -userInput $command -modelResponse $ollamaResponse
                            
                            try {
                                Add-Content -Path $inputFile -Value $command
                                Add-Content -Path $outputFile -Value $ollamaResponse
                            }
                            catch {
                                Write-Host "Error logging Ollama interaction: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                    }
                }
            }
        }
        else {
            Send-TelegramMessage -chatId $chatId -message "Unauthorized. This bot only responds to its admin."
            Write-Host "Unauthorized access attempt from chat ID: $chatId"
        }
        Start-Sleep -Seconds 5
    }
}
#endregion