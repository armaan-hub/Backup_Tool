# Advanced Folder Backup Tool

A comprehensive PowerShell script that provides real-time folder backup with intelligent archiving and automatic scheduling.

## Features

### 🔧 Interactive Setup & Configuration
- First-run interactive setup mode
- Configurable backup retention (1-365 days)
- Automatic configuration persistence in JSON format
- Source and destination folder validation

### 🔄 Auto-Scheduling (Task Scheduler Integration)
- Automatic detection of existing scheduled tasks
- Self-scheduling with Windows Task Scheduler
- Runs at system startup and user logon
- Highest privilege execution
- Administrator privilege checking and auto-elevation

### 📁 Real-Time Monitoring (Background Mode)
- FileSystemWatcher for instant file change detection
- Monitors file creation, changes, deletion, and renaming
- Intelligent "File Ready" checking with retry logic
- Handles locked files gracefully
- Skips temporary files automatically

### 🗜️ Intelligent Archiving & Retention
- Daily ZIP compression of backup folder
- Compares new archives with existing ones (keeps larger)
- Automatic cleanup of archives older than configured days
- Maintains optimal storage utilization

## Usage

### First Time Setup
```powershell
# Run in Administrator PowerShell
.\AdvancedFolderBackup.ps1 -Mode Setup
```

### Manual Background Mode
```powershell
# Run the monitoring service manually
.\AdvancedFolderBackup.ps1 -Mode Background
```

### Auto Mode (Default)
```powershell
# Automatically determines mode based on configuration
.\AdvancedFolderBackup.ps1
```

## How It Works

### Setup Mode
1. **Path Configuration**: Prompts for source and destination folder paths
2. **Retention Settings**: Asks how many days of backup history to keep
3. **Directory Creation**: Automatically creates backup and archive directories
4. **Task Scheduling**: Offers to set up automatic Windows Task Scheduler entry
5. **Configuration Persistence**: Saves all settings to `BackupConfig.json`

### Background Mode
1. **Initial Sync**: Performs complete folder synchronization on startup
2. **Archive Management**: Creates daily ZIP archives with intelligent retention
3. **Real-Time Monitoring**: Continuously watches for file system changes
4. **File Safety**: Ensures files are ready before copying (handles locking)

## Files Created

- `BackupConfig.json` - Configuration storage
- `BackupLog.txt` - Detailed operation logs
- `BackupArchives/` - Directory containing daily ZIP archives
- Windows Task: "AdvancedFolderBackup" - Scheduled task entry

## Requirements

- Windows PowerShell 5.1 or higher
- Administrator privileges (for Task Scheduler integration)
- .NET Framework (for FileSystemWatcher)

## Configuration Example

```json
{
  "SourcePath": "C:\\Source\\Documents",
  "DestinationPath": "C:\\Backup\\Documents",
  "ArchivePath": "C:\\Backup\\BackupArchives",
  "DaysToKeep": 30,
  "LastBackup": "2026-02-14T10:30:00",
  "Version": "1.0"
}
```

## Key Features Explained

### File Locking Detection
The script uses a sophisticated file readiness check that:
- Attempts to open files exclusively before copying
- Retries with configurable delays
- Logs locked file warnings
- Prevents corruption from incomplete file writes

### Smart Archive Management
- Creates ZIP archives named with current date (e.g., `Backup_2026-02-14.zip`)
- Compares file sizes when same-date archives exist
- Keeps the larger archive (more complete backup)
- Automatically removes archives older than configured retention period

### Task Scheduler Integration
- Checks for existing scheduled tasks to avoid duplicates
- Creates task with SYSTEM account privileges
- Triggers on both startup and user logon
- Uses hidden window style for background operation

## Troubleshooting

### Administrator Rights
If you see "Administrator privileges required", run PowerShell as Administrator or the script will automatically restart with elevated privileges.

### Path Issues
Ensure all folder paths exist and are accessible. The script validates paths during setup.

### Task Scheduler
If automatic scheduling fails, you can manually create a scheduled task pointing to the script with `-Mode Background` parameter.

## Logging

All operations are logged to `BackupLog.txt` with timestamps and severity levels:
- **INFO**: Normal operations
- **WARN**: Warnings (locked files, missing paths)
- **ERROR**: Critical errors

## Security Considerations

- The script requires Administrator privileges for Task Scheduler integration
- All file operations respect Windows file permissions
- Configuration is stored in plain text (consider folder permissions)
- Backup destinations should be secured appropriately

## Version History

**v1.0** - Initial release with full feature set
- Interactive setup and configuration
- Real-time monitoring with FileSystemWatcher  
- Intelligent archiving and retention
- Auto-scheduling with Task Scheduler
- Comprehensive error handling and logging