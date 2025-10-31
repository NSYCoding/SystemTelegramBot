param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)




$me = (whoami).Split('\')[1]
$me = $me.Substring(0, 1).ToUpper() + $me.Substring(1)
$currentHour = (Get-Date).Hour
if ($currentHour -ge 6 -and $currentHour -lt 12) {
    $greetTime = "Good morning, $me"
}
elseif ($currentHour -ge 12 -and $currentHour -lt 18) {
    $greetTime = "Good afternoon, $me"
}
elseif ($currentHour -ge 18 -and $currentHour -lt 22) {
    $greetTime = "Good evening, $me"
}
else {
    $greetTime = "Good night $me"
}
Send-TelegramMessage -chatId $chatId -message "Welcome to the System Telegram Bot! $greetTime! Type /help for available commands."
