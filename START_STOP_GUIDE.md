# Backup Service Control - Start/Stop Guide

## Overview

The Advanced Folder Backup Tool now includes **full service control capabilities**. You can easily stop and start the backup service at any time, and it will automatically run in background mode when restarted.

## Quick Control Methods

### Method 1: Using Batch Files (Easiest)

Located in the Back tool folder:

#### **StartBackup.bat** - Start the service
- Double-click to start the backup service
- Service runs in background after starting
- Automatically enabled in Windows Task Scheduler

#### **StopBackup.bat** - Stop the service
- Double-click to stop the backup service
- Scheduled task is disabled
- No backups will run until restarted

#### **RestartBackup.bat** - Restart the service
- Double-click to restart the backup service
- Stops and then immediately restarts
- Useful for reloading configuration changes

#### **StatusBackup.bat** - Check service status
- Double-click to see current service status
- Shows if service is RUNNING or STOPPED

#### **BackupControl.bat** - Open control menu
- Double-click for interactive control menu
- Full management options in one place

### Method 2: PowerShell Commands

Open PowerShell and run:

**Start service:**
```powershell
cd "C:\Users\armaa\OneDrive - The Era Corporations\Study\AI Class\Data Science Class\Back tool"
.\AdvancedFolderBackup_v2.ps1 -Control Start
```

**Stop service:**
```powershell
.\AdvancedFolderBackup_v2.ps1 -Control Stop
```

**Restart service:**
```powershell
.\AdvancedFolderBackup_v2.ps1 -Control Restart
```

**Check status:**
```powershell
.\AdvancedFolderBackup_v2.ps1 -Control Status
```

### Method 3: Interactive Control Menu

Open PowerShell and run:

```powershell
cd "C:\Users\armaa\OneDrive - The Era Corporations\Study\AI Class\Data Science Class\Back tool"
.\AdvancedFolderBackup_v2.ps1 -Mode Control
```

Or simply double-click `BackupControl.bat`

This opens a full menu with options to:
- Start/Stop/Restart the service
- View current status
- View recent logs
- Adjust settings
- Return to main menu

## Service States

### RUNNING (✓)
- Backup service is active
- Scheduled task is enabled
- Backups occur at startup/logon
- File monitoring is active
- Cloud space freeing enabled

### STOPPED (✗)
- Backup service is inactive
- Scheduled task is disabled
- No automatic backups will occur
- No file monitoring
- Service can be restarted anytime

## Workflow: Stop and Restart

### Stop the Service
```
User runs: StopBackup.bat
↓
Service stops gracefully
↓
File watchers disabled
↓
Scheduled task disabled
↓
Service Status: STOPPED
```

### Restart the Service
```
User runs: StartBackup.bat
↓
Scheduled task enabled
↓
Background mode initiated
↓
Cloud space freeing runs
↓
File watcher activated
↓
Service Status: RUNNING
```

## Important Notes

### ✅ When to Stop
- Temporary pause of backups needed
- Troubleshooting issues
- Maintenance work on source folders
- Reducing system resource usage
- Temporarily freeing cloud storage space

### ✅ When to Restart
- Configuration changes made
- Need to resume backups
- Testing backup functionality
- Performance optimization

### ✅ Safe Operations
- Stopping doesn't delete any files
- All backed-up files remain safe
- Service can be restarted immediately
- No data loss risk

## Interactive Control Menu

When you run the Control menu, you'll see:

```
============================================================
SERVICE CONTROL MENU
============================================================

Service Status: ✓ RUNNING

Options:
  (1) Start Backup Service
  (2) Stop Backup Service
  (3) Restart Backup Service
  (4) View Service Log
  (5) Back to Main Menu
```

### Menu Options

**(1) Start Backup Service**
- Enables the scheduled task
- Runs backup immediately in background
- Shows confirmation when started

**(2) Stop Backup Service**
- Asks for confirmation before stopping
- Disables the scheduled task
- Shows confirmation when stopped

**(3) Restart Backup Service**
- Stops then restarts automatically
- Useful after config changes
- Shows progress

**(4) View Service Log**
- Shows last 20 log entries
- Displays what the service is doing
- Useful for troubleshooting

**(5) Back to Main Menu**
- Returns to main control menu
- Access settings, view logs

## Troubleshooting

### Service won't start?
1. Check that admin rights are used
2. Verify configuration file exists: `BackupConfig.json`
3. Check BackupLog.txt for error messages

### Service won't stop?
1. Try running StopBackup.bat as Administrator
2. Check BackupLog.txt for errors
3. Force close via Task Manager if needed

### Status shows STOPPED but files backed up?
1. Service may be running in legacy mode
2. Check Windows Task Scheduler for "AdvancedFolderBackup" task
3. Manually disable task if already running

### Can I close the script and have it keep running?
1. **YES!** Once started, service runs in **background**
2. You can close the PowerShell window
3. Service continues running automatically
4. Logs are updated in BackupLog.txt

## File Locations

| File | Purpose |
|------|---------|
| `StartBackup.bat` | Quick start button |
| `StopBackup.bat` | Quick stop button |
| `RestartBackup.bat` | Quick restart button |
| `StatusBackup.bat` | Quick status check |
| `BackupControl.bat` | Full control menu |
| `AdvancedFolderBackup_v2.ps1` | Main script |
| `BackupLog.txt` | Service logs |

## Tips

💡 **Pin batch files to taskbar** for quick access:
- Right-click batch file → Pin to Quick Access
- Right-click batch file → Send to Desktop

💡 **Run as Administrator**: Recommended for reliable operation
- Right-click batch file → Run as administrator

💡 **Schedule recurring restarts**: Use Windows Task Scheduler to periodically restart service for clean operation

💡 **Monitor logs**: Check BackupLog.txt periodically
- `BackupLog.txt` location: Same folder as script

## Command Line Examples

**Start background service and exit:**
```batch
AdvancedFolderBackup_v2.ps1 -Control Start
```

**Restart and wait for completion:**
```batch
AdvancedFolderBackup_v2.ps1 -Control Restart
```

**Quick status check in automation:**
```batch
AdvancedFolderBackup_v2.ps1 -Control Status
```

## Version Information

- **Feature Added:** February 14, 2026
- **Script Version:** 2.0+
- **Status:** Production Ready

---

**Summary:** Complete control over backup service start/stop with interactive menus and quick-access batch files. Service runs reliably in background after starting.
