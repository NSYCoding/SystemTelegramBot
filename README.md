# SystemTelegramBot

A powerful Telegram bot that provides remote system control and AI assistant capabilities using Ollama models.

## Features
- 🔒 **System Security**: Lock workstation remotely and set timed locks
- 💻 **System Monitoring**: Check CPU load, disk space, running processes
- 🎙️ **Audio Control**: Toggle system audio mute status remotely
- 🤖 **AI Assistant**: Chat with multiple AI models via Ollama integration. Also capable of deleting the chat.
- 📷 **Screenshot**: Take and receive screenshots of the system
- ⚙️ **Process Management**: Get, Start and Stop processes remotely

## Installation

1. Download the first release of SystemTelegramBot
2. Run `installer.ps1` to install the application:
   ```powershell
   .\installer.ps1
   ```
   Or specify a custom install path:
   ```powershell
   .\installer.ps1 -InstallPath "C:\CustomPath\"
   ```
3. A desktop shortcut will be created automatically

## Configuration

Before using the bot, you need to store your credentials in Windows Credential Manager:

1. **Bot Token**: Create a credential with target name `SystemTelegramBot_BOTTOKEN`
2. **Admin ID**: Create a credential with target name `SystemTelegramBot_ADMINID` 
3. **Password**: Create a credential with target name `SystemTelegramBot_PASSWORD`

You can use the following PowerShell commands to create these credentials:

```powershell
cmdkey /generic:SystemTelegramBot_BOTTOKEN /user:"BotToken" /pass:"YOUR_BOT_TOKEN"
cmdkey /generic:SystemTelegramBot_ADMINID /user:"AdminId" /pass:"YOUR_TELEGRAM_ID"
cmdkey /generic:SystemTelegramBot_PASSWORD /user:"Password" /pass:"YOUR_ACCESS_PASSWORD"
```

## AI Integration (Ollama)

This bot integrates with [Ollama](https://ollama.ai/) to provide AI assistance:

1. Install Ollama on your system
2. Pull your preferred AI models:
   ```
   ollama pull llama2
   ollama pull llama3
   ollama pull mistral
   ollama pull gemma
   ```
3. Ensure Ollama is running when using AI features

## Available Commands

### System Control
- `/cpu` - CPU load and disk space
- `/sleepmode` - Lock workstation immediately
- `/sleepmodetime [minutes]` - Lock after specified time
- `/sleeplock [password] [minutes]` - Lock periodically
- `/unlocksystem [password]` - Stop periodic locking

### Process Management
- `/getprocesses` - List running processes
- `/startprocess [name]` - Start a process
- `/stopprocess [name]` - Stop a process

### Media and Input
- `/mute` - Toggle audio mute
- `/screenshot` - Take and send a screenshot

### AI Assistant
- `/ollama [message]` - Chat with Ollama AI
- `/models` - List available Ollama models
- `/setmodel [model_name]` - Select an Ollama model
- `/model [1-4]` - Quick model switch using presets
- `/presets` - Show model presets

### General
- `/start` - Welcome message
- `/help` - Show all commands

## Requirements

- Windows 11 (comes with PowerShell 5.1 preinstalled)
- Telegram account
- Ollama (for AI features)

## Security

This bot uses secure credential storage and only responds to the configured admin ID.
Unauthorized access attempts are logged but not allowed to execute commands.

## Author

© 2025 (Nour)NSYCoding