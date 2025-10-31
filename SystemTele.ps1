Import-Module CredentialManager

Write-Host "Attempting to load utils.ps1..." -ForegroundColor Cyan
. (Join-Path -Path $PSScriptRoot -ChildPath "utils\utils.ps1")
Write-Host "Finished loading utils.ps1." -ForegroundColor Cyan

if (Get-Command -Name ConvertTo-PlainText -ErrorAction SilentlyContinue) {
    Write-Host "ConvertTo-
    PlainText function is loaded." -ForegroundColor Green
} else {
    Write-Host "ConvertTo-PlainText function IS NOT LOADED." -ForegroundColor Red
}

if (Get-Command -Name Get-Updates -ErrorAction SilentlyContinue) {
    Write-Host "Get-Updates function is loaded." -ForegroundColor Green
} else {
    Write-Host "Get-Updates function IS NOT LOADED." -ForegroundColor Red
}

$botTokenCred = Get-StoredCredential -Target "SystemTelegramBot_BOTTOKEN"
if (-not $botTokenCred) {
    Write-Host "Error: Telegram bot token not found. Please set it using Set-StoredCredential -Target SystemTelegramBot_BOTTOKEN -Credential (Get-Credential)" -ForegroundColor Red
    exit
}
$script:botToken = ConvertTo-PlainText $botTokenCred.Password

$adminIdCred = Get-StoredCredential -Target "SystemTelegramBot_ADMINID"
if (-not $adminIdCred) {
    Write-Host "Error: Admin ID not found. Please set it using Set-StoredCredential -Target SystemTelegramBot_ADMINID -Credential (Get-Credential)" -ForegroundColor Red
    exit
}
$script:adminId = ConvertTo-PlainText $adminIdCred.Password

$passwordCred = Get-StoredCredential -Target "SystemTelegramBot_PASSWORD"
if (-not $passwordCred) {
    Write-Host "Error: Password not found. Please set it using Set-StoredCredential -Target SystemTelegramBot_PASSWORD -Credential (Get-Credential)" -ForegroundColor Red
    exit
}
$script:storedPassword = ConvertTo-PlainText $passwordCred.Password

Write-Host "Bot started. Monitoring for commands..."
$lastUpdateId = 0


while ($true) {
    $updates = Get-Updates -offset $lastUpdateId

    foreach ($update in $updates) {
        $message = $update.message.text
        $chatId = $update.message.chat.id
        $lastUpdateId = $update.update_id + 1

        Write-Host "Received message: $message"

        if ($chatId -eq $script:adminId) {
            if ($message -match '^/([a-zA-Z0-9_-]+)(?:\s+(.*))?$') {
                $commandName = $Matches[1]
                $commandArgs = $Matches[2]

                $commandPath = Join-Path -Path $PSScriptRoot -ChildPath "commands\$commandName.ps1"

                if (Test-Path -Path $commandPath -PathType Leaf) {
                    try {
                        . $commandPath -chatId $chatId -message $message -commandArgs $commandArgs
                    }
                    catch {
                        Send-TelegramMessage -chatId $chatId -message "Error executing command '$commandName': $($_.Exception.Message)"
                    }
                }
                else {
                    Send-TelegramMessage -chatId $chatId -message "Command '$commandName' not found. Type /help for available commands."
                }
            }
            elseif ($message -eq '/help') {
                $commandFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "commands") -Filter "*.ps1" | Select-Object -ExpandProperty BaseName
                $helpMessage = "Available commands:`n"
                foreach ($cmd in $commandFiles | Sort-Object) {
                    $helpMessage += "    /$cmd`n"
                }
                $helpMessage += "`nType /help [command] for specific help."
                Send-TelegramMessage -chatId $chatId -message $helpMessage
            }
            else {
                Send-TelegramMessage -chatId $chatId -message "Unknown command or invalid format. Type /help for available commands."
            }
        }
        else {
            Send-TelegramMessage -chatId $chatId -message "Unauthorized. This bot only responds to its admin."
            Write-Host "Unauthorized access attempt from chat ID: $chatId"
        }
        Start-Sleep -Seconds 5
    }
}

