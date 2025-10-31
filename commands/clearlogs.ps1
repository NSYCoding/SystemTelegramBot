param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




if (Test-Path -Path $script:inputFile) {
    Remove-Item -Path $script:inputFile -Force
    Send-TelegramMessage -chatId $chatId -message "Input log deleted."
}
else {
    Send-TelegramMessage -chatId $chatId -message "Input log not found."
}
if (Test-Path -Path $script:outputFile) {
    Remove-Item -Path $script:outputFile -Force
    Send-TelegramMessage -chatId $chatId -message "Output log deleted."
}
else {
    Send-TelegramMessage -chatId $chatId -message "Output log not found."
}
