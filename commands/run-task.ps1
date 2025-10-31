param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$taskName = $commandArgs
if ([string]::IsNullOrWhiteSpace($taskName)) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /run-task [task_name]"
    exit
}

$taskPath = Join-Path -Path $PSScriptRoot -ChildPath "..\tasks\$taskName.ps1"

if (Test-Path -Path $taskPath -PathType Leaf) {
    try {
        Send-TelegramMessage -chatId $chatId -message "Running task '$taskName'…"
        
        $taskOutput = & $taskPath 2>&1 | Out-String
        Send-TelegramMessage -chatId $chatId -message "Task '$taskName' completed. Output:`n$taskOutput"
    }
    catch {
        Send-TelegramMessage -chatId $chatId -message "Error executing task '$taskName': $($_.Exception.Message)"
    }
}
else {
    Send-TelegramMessage -chatId $chatId -message "Task '$taskName' not found. Make sure the task script exists in the 'tasks' directory."
}
