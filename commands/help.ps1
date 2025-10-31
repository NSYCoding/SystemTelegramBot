param (
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)

$helpText = @{
    "start" = "Welcome message"
    "systemstatus" = "CPU load and disk space"
    "mute" = "Toggles system audio"
    "screenshot" = "Takes and sends a screenshot"
    "getprocesses" = "Lists running processes"
    "startprocess" = "Starts a process. Usage: /startprocess [process_name]"
    "stopprocess" = "Stops a process. Usage: /stopprocess [process_name]"
    "sleepmode" = "Immediately locks the workstation"
    "sleepmodetime" = "Locks the system after specified minutes. Usage: /sleepmodetime [minutes]"
    "sleeplock" = "Locks screen periodically. Usage: /sleeplock [password] [minutes]"
    "unlocksystem" = "Stops screen locking. Usage: /unlocksystem [password]"
    "ollama" = "Chat with Ollama assistant. Usage: /ollama [your_message]"
    "models" = "List available Ollama models"
    "setmodel" = "Select Ollama model to use. Usage: /setmodel [model_name]"
    "model" = "Quick model switch with presets. Usage: /model [1-4]"
    "presets" = "Show available model presets"
    "clearlogs" = "Deletes Ollama input/output logs"
    "ls" = "Lists files and folders in a directory. Usage: /ls [path]"
    "getservices" = "Lists running Windows services"
    "run-task" = "Executes a predefined PowerShell script from the 'tasks' directory. Usage: /run-task [task_name]"
    "newchat" = "Creates and switches to a new chat session. Usage: /newchat [chat_name]"
    "listchats" = "Lists all saved chat sessions"
    "loadchat" = "Loads and switches to an existing chat session. Usage: /loadchat [chat_name]"
    "deletechat" = "Deletes a specified chat session. Usage: /deletechat [chat_name]"
    "currentchat" = "Shows the name of the currently active chat session"
    "help" = "Shows this help message"
    "pokemon" = "Gets information about a specified Pokemon. Usage: /pokemon [pokemon_name]"
}

$helpMessage = "Available commands:\n"


$commandFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\commands") -Filter "*.ps1" | Select-Object -ExpandProperty BaseName | Sort-Object

foreach ($cmd in $commandFiles) {
    $cmdName = $cmd -replace '\.ps1$'
    $helpMessage += "    /$cmdName"
    if ($helpText.ContainsKey($cmdName)) {
        $helpMessage += " - $($helpText[$cmdName])"
    }
    $helpMessage += "`n"
}
$helpMessage += "`nType /help [command] for specific help."
Send-TelegramMessage -chatId $chatId -message $helpMessage
