param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$targetPath = $commandArgs
if ([string]::IsNullOrWhiteSpace($targetPath)) {
    $targetPath = $PSScriptRoot 
}

try {
    if (-not (Test-Path -Path $targetPath)) {
        Send-TelegramMessage -chatId $chatId -message "Error: Path '$targetPath' not found."
        exit
    }

    $items = Get-ChildItem -Path $targetPath | Select-Object Name, Mode, LastWriteTime, Length
    $output = "Contents of '$targetPath':`n`n"
    $output += $items | Format-Table -AutoSize | Out-String

    Send-TelegramMessage -chatId $chatId -message $output
}
catch {
    Send-TelegramMessage -chatId $chatId -message "Error listing directory contents: $($_.Exception.Message)"
}
