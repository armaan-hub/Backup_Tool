# Quick Reference Card
## Advanced Folder Backup Tool v2.0

---

## Single-Command Reference

### Basic Commands

```powershell
# First-time setup (interactive)
.\AdvancedFolderBackup_v2.ps1 -Mode Setup

# Run in background
.\AdvancedFolderBackup_v2.ps1 -Mode Background

# Auto-detect mode (setup if needed, background if configured)
.\AdvancedFolderBackup_v2.ps1

# Setup with predefined values (no prompts)
.\AdvancedFolderBackup_v2.ps1 -Mode Setup -SourcePath "C:\Data" -DestinationPath "E:\Backup" -DaysToKeep 30
```

---

## Supported Environment Variables

| Variable | Expands To | Example |
|----------|-----------|---------|
| `%TEMP%` | Temp folder | C:\Users\john\AppData\Local\Temp |
| `%USERPROFILE%` | User home | C:\Users\john |
| `%APPDATA%` | Roaming data | C:\Users\john\AppData\Roaming |
| `%PROGRAMDATA%` | System data | C:\ProgramData |
| `%COMPUTERNAME%` | Machine name | DESKTOP-ABC123 |
| `%USERNAME%` | Username | john |

---

## Deployment Examples

```powershell
# Local backup
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "C:\MyDocuments" `
    -DestinationPath "D:\Backup\MyDocuments" `
    -DaysToKeep 30

# User-profile backup (portable)
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "%USERPROFILE%\Documents" `
    -DestinationPath "E:\Backups\%USERNAME%_Documents"

# Network backup
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "C:\ProjectData" `
    -DestinationPath "\\fileserver\backups\%COMPUTERNAME%"

# Custom config location
.\AdvancedFolderBackup_v2.ps1 -Mode Background `
    -ConfigPath "\\admin\configs\backup_config.json"

# Backup from network to local
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "\\nas\shared\data" `
    -DestinationPath "D:\LocalBackup" `
    -DaysToKeep 90
```

---

## Configuration File Paths

### Automatic Search Order
1. `-ConfigPath` parameter (if provided)
2. `.\BackupConfig.json` (script directory)
3. `%APPDATA%\AdvancedFolderBackup\BackupConfig.json` (user AppData)

### Example Paths
```
C:\Scripts\AdvancedFolderBackup_v2.ps1
C:\Scripts\BackupConfig.json                          ← Checked first

%APPDATA%\AdvancedFolderBackup\BackupConfig.json      ← Checked if not found

\\admin\configs\backup_template.json                  ← Use -ConfigPath parameter
```

---

## Common Scenarios

### Scenario 1: Department Backup
```powershell
# Create shared config
$config = @{
    SourcePath = "%USERPROFILE%\Important"
    DestinationPath = "\\backup\dept\%USERNAME%"
    DaysToKeep = 60
}

# Deploy to each user
.\AdvancedFolderBackup_v2.ps1 -Mode Setup @config
```

### Scenario 2: Multi-Machine Deployment
```powershell
# Deploy using shared config to multiple computers
$computers = "COMP01", "COMP02", "COMP03"
$config = "\\admin\shared_backup_config.json"

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer {
        & "C:\Program Files\Backup\AdvancedFolderBackup_v2.ps1" `
            -Mode Background `
            -ConfigPath $args[0]
    } -ArgumentList $config
}
```

### Scenario 3: USB Portable Backup
```powershell
# Copy entire folder to USB
Copy-Item "AdvancedFolderBackup_v2.ps1" "E:\BackupTool\" -Force

# Run from USB (will work on any machine)
& "E:\BackupTool\AdvancedFolderBackup_v2.ps1" -Mode Setup `
    -SourcePath "%USERPROFILE%\Documents" `
    -DestinationPath "E:\Backups\%COMPUTERNAME%"
```

### Scenario 4: Automated Nightly Backup
```powershell
# Task Scheduler creates entry automatically

# First run triggers automatic scheduling
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "D:\Data" `
    -DestinationPath "\\nas\backups\nightly" `
    -DaysToKeep 30

# Script will ask if you want to set up automatic scheduling
# Answer: Y

# After that, runs automatically at startup and logon
```

---

## Parameters Explained

```powershell
.\AdvancedFolderBackup_v2.ps1 `
    -Mode            # 'Setup', 'Background', or 'Auto' (default)
    -ConfigPath      # Custom path to configuration file
    -SourcePath      # Folder to backup (supports env vars)
    -DestinationPath # Where to store backups (supports env vars)
    -DaysToKeep      # How many days of archives to retention (1-365)
```

---

## Windows Task Scheduler Integration

### What Gets Created
```
Task Name:       AdvancedFolderBackup
Run As:          SYSTEM
Triggers:        At Startup
                 At User Logon
Run Level:       Highest Privileges
Window Style:    Hidden
```

### View Task
```powershell
Get-ScheduledTask -TaskName "AdvancedFolderBackup"
```

### Delete Task (if needed)
```powershell
Unregister-ScheduledTask -TaskName "AdvancedFolderBackup" -Confirm:$false
```

---

## Log File Locations

### Where Logs Are Stored
```
Same directory as configuration file:
- %APPDATA%\AdvancedFolderBackup\BackupLog.txt      (if AppData used)
- .\BackupLog.txt                                    (if script dir used)
- \\admin\configs\BackupLog.txt                      (if network config used)
```

### View Recent Logs
```powershell
# On Windows
Get-Content "$env:APPDATA\AdvancedFolderBackup\BackupLog.txt" -Tail 50

# Real-time monitoring
Get-Content "$env:APPDATA\AdvancedFolderBackup\BackupLog.txt" -Wait
```

---

## Troubleshooting Quick Fixes

| Issue | Fix |
|-------|-----|
| "Not running as Administrator" | Right-click PowerShell → Run as Administrator |
| "Source path not found" | Verify path exists; check environment variables with `Get-ChildItem env:` |
| "Permission denied" | Check folder permissions; verify network access |
| "Failed to create task" | Run as Administrator; check group policy |
| "File locked" | Script retries 10 times with 500ms delay |
| Config not found | Check all three search locations above |

---

## Version Information

```
Current Version: 2.0
Previous Version: 1.0
Requirements: Windows 7 SP1+, PowerShell 5.1+
Compatibility: Cross-computer ready
```

---

## Key Features at a Glance

✓ Real-time file monitoring
✓ Automatic compression and archiving
✓ Smart retention management (keep N days)
✓ File locking detection
✓ Cross-computer deployment
✓ Environment variable support
✓ Network path support
✓ Automatic Task Scheduler setup
✓ Detailed logging
✓ Multi-user capable

---

## Example: Complete Setup Workflow

```powershell
# Step 1: Run as Administrator
# (Right-click PowerShell → Run as Administrator)

# Step 2: Navigate to script location
cd "C:\Scripts"

# Step 3: Run setup with parameters (no prompts)
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "%USERPROFILE%\Documents" `
    -DestinationPath "D:\Backup\Documents" `
    -DaysToKeep 30

# Step 4: When prompted, choose Y to set up automatic scheduling

# Step 5: Done! Backup runs automatically now

# Verify it's working
Get-ScheduledTask -TaskName "AdvancedFolderBackup" | Select-Object State

# Check logs
Get-Content "$env:APPDATA\AdvancedFolderBackup\BackupLog.txt" -Tail 20
```

---

## Getting Help

```powershell
# View help
Get-Help .\AdvancedFolderBackup_v2.ps1 -Full

# Check configuration
Get-Content "$env:APPDATA\AdvancedFolderBackup\BackupConfig.json" | ConvertFrom-Json

# Test network path
Test-Path "\\fileserver\backup"

# List scheduled tasks
Get-ScheduledTask | Where-Object Name -Like "*Backup*"
```

---

## One-Liners

```powershell
# Quick local backup
.\AdvancedFolderBackup_v2.ps1 -Mode Setup -SourcePath "C:\Data" -DestinationPath "D:\Backup" -DaysToKeep 30

# Network backup
.\AdvancedFolderBackup_v2.ps1 -Mode Setup -SourcePath "C:\Work" -DestinationPath "\\nas\backups\%COMPUTERNAME%" -DaysToKeep 60

# Use predefined config
.\AdvancedFolderBackup_v2.ps1 -Mode Background -ConfigPath "\\admin\config.json"

# Check backup status
Get-ScheduledTaskInfo -TaskName "AdvancedFolderBackup" | Select-Object LastRunTime, LastTaskResult

# View latest backups
Get-ChildItem "$env:APPDATA\AdvancedFolderBackup\..\BackupArchives\*.zip" | Sort-Object CreationTime -Descending | Select-Object -First 5
```

---

## Video Guide Summary
1. **Setup Phase**: Choose source, destination, retention days
2. **Scheduling Phase**: Optionally enable auto-scheduling
3. **Monitor Phase**: Check logs and verify backups
4. **Maintain Phase**: Script handles cleanup automatically

---

## Support Resources

- **Logs**: Check `BackupLog.txt` for detailed information
- **Config**: Edit `BackupConfig.json` to change settings
- **Task**: View `AdvancedFolderBackup` in Windows Task Scheduler
- **Docs**: Read `CROSS_COMPUTER_GUIDE.md` for enterprise use
- **Enhancement**: See `ENHANCEMENT_SUMMARY.md` for v2.0 changes