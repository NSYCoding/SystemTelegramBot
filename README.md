# SystemTelegramBot

A powerful Telegram bot that provides remote system control and AI assistant capabilities using Ollama models.

## Features
- 🚀 **Modular & Extensible**: Easily add new commands due to a modular architecture.
- 🔒 **System Security**: Lock workstation remotely and set timed locks.
- 💻 **System Monitoring**: Check CPU load, disk space, running processes, and list Windows services.
- 📁 **File System Interaction**: List directory contents remotely.
- ⚙️ **Process & Service Management**: Get, Start, and Stop processes; list Windows services.
- 🎙️ **Audio Control**: Toggle system audio mute status remotely.
- 🤖 **AI Assistant**: Chat with multiple AI models via Ollama integration, with full chat session management (create, load, list, delete, switch chats).
- 📷 **Screenshot**: Take and receive screenshots of the system.
- 🛠️ **Task Automation**: Run predefined PowerShell scripts remotely.

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
- `/systemstatus` - CPU load and disk space
- `/sleepmode` - Lock workstation immediately
- `/sleepmodetime [minutes]` - Lock after specified time
- `/sleeplock [password] [minutes]` - Lock periodically
- `/unlocksystem [password]` - Stop periodic locking

### Process & Service Management
- `/getprocesses` - List running processes
- `/startprocess [name]` - Start a process
- `/stopprocess [name]` - Stop a process
- `/getservices` - List running Windows services

### File System Interaction
- `/ls [path]` - Lists files and folders in a directory

### Task Automation
- `/run-task [task_name]` - Executes a predefined PowerShell script from the 'tasks' directory

### Media and Input
- `/mute` - Toggle audio mute
- `/screenshot` - Take and send a screenshot

### AI Assistant (Ollama)
- `/ollama [message]` - Chat with Ollama AI
- `/models` - List available Ollama models
- `/setmodel [model_name]` - Select an Ollama model
- `/model [1-4]` - Quick model switch using presets
- `/presets` - Show model presets
- `/newchat [name]` - Creates and switches to a new chat session
- `/listchats` - Lists all saved chat sessions
- `/loadchat [name]` - Loads and switches to an existing chat session
- `/deletechat [name]` - Deletes a specified chat session
- `/currentchat` - Shows the name of the currently active chat session
- `/clearlogs` - Deletes Ollama input/output logs

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