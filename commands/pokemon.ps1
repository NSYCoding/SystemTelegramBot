param(
    [Parameter(Mandatory=$true)]
    [string]$chatId,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [string]$commandArgs
)



$pokemonName = $commandArgs
if ([string]::IsNullOrWhiteSpace($pokemonName)) {
    Send-TelegramMessage -chatId $chatId -message "Usage: /pokemon [pokemon_name]"
    exit
}

try {
    $apiUrl = "https://pokeapi.co/api/v2/pokemon/$($pokemonName.ToLower())"
    $pokemonData = Invoke-RestMethod -Uri $apiUrl -Method Get

    $name = $pokemonData.name
    $id = $pokemonData.id
    $types = ($pokemonData.types | ForEach-Object { $_.type.name }) -join ", "
    $abilities = ($pokemonData.abilities | ForEach-Object { $_.ability.name }) -join ", "
    $height = $pokemonData.height / 10 
    $weight = $pokemonData.weight / 10 

    $responseMessage = "*Pokemon: $($name.ToUpper())*
"
    $responseMessage += "ID: $id
"
    $responseMessage += "Types: $types
"
    $responseMessage += "Abilities: $abilities
"
    $responseMessage += "Height: $($height) m
"
    $responseMessage += "Weight: $($weight) kg
"

    $photoUrl = $pokemonData.sprites.front_default

    if ([string]::IsNullOrWhiteSpace($photoUrl)) {
        Send-TelegramMessage -chatId $chatId -message $responseMessage
        Send-TelegramMessage -chatId $chatId -message "(No image available for $($name.ToUpper()))"
    } else {
        $telegramPhotoUrl = "https://api.telegram.org/bot$script:botToken/sendPhoto"
        $photoBody = @{
            chat_id = $chatId
            photo   = $photoUrl
            caption = $responseMessage
            parse_mode = "Markdown"
        }
        Invoke-RestMethod -Uri $telegramPhotoUrl -Method Post -Body $photoBody
    }
}
catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Send-TelegramMessage -chatId $chatId -message "Pokemon '$pokemonName' not found. Please check the spelling."
    } else {
        Send-TelegramMessage -chatId $chatId -message "Error fetching Pokemon data: $($_.Exception.Message)"
    }
}
