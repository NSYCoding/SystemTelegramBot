param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



try {
    $cpu = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $drives = Get-PSDrive -PSProvider FileSystem
    $drivesInfo = foreach ($drive in $drives) {
        $freeSpace = $drive.Free / 1GB
        "$($drive.Name): {0:N2} GB free" -f $freeSpace
    }
    $drivesText = $drivesInfo -join "`n"
    $response = "CPU Load: $cpu%`nFree Disk Space:`n$drivesText"
    Send-TelegramMessage -chatId $chatId -message $response
}
catch {
    Send-TelegramMessage -chatId $chatId -message "Error getting system status: $($_.Exception.Message)"
}
