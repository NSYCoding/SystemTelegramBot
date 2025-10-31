param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$sleepTime = $commandArgs
$maxSleepMinutes = 1440 

if ([int]::TryParse($sleepTime, [ref]$null) -and [int]$sleepTime -gt 0) {
    if ([int]$sleepTime -gt $maxSleepMinutes) {
        Send-TelegramMessage -chatId $chatId -message "Sleep time too long. Maximum is $maxSleepMinutes minutes (24 hours)."
        exit
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
