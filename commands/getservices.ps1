param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



try {
    $services = Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name, Status, DisplayName | Sort-Object Name
    $serviceList = "Running Windows Services:`n`n"
    $serviceList += $services | Format-Table -AutoSize | Out-String

    Send-TelegramMessage -chatId $chatId -message $serviceList
}
catch {
    Send-TelegramMessage -chatId $chatId -message "Error getting services: $($_.Exception.Message)"
}
