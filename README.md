# Backup Manager - Minimal Edition ✓

## ✓ Quick Start

1. **Run the Backup Manager**
   ```
   Right-click PowerShell → "Run as Administrator"
   cd "C:\...\Back tool"
   .\BackupManager.ps1
   ```

2. **First Time Setup**
   - Select `[1] Initial Setup`
   - Enter source folder path to backup
   - Enter destination folder path
   - Set retention days (0=no zips, 1-365=daily archives)
   - Create scheduled task when prompted

## ✓ Main Menu Options

**Setup & Config:**
- `[1]` Initial Setup - Configure source, destination, backup days
- `[2]` View Configuration - See current settings
- `[3]` Edit Configuration - Change any setting anytime

**Service Management:**
- `[4]` Create/Update Task - Set up automatic scheduling
- `[5]` Start Service - Start backup monitoring
- `[6]` Stop Service - Pause backups
- `[7]` Delete Task - Remove scheduled task

**Status:**
- `[8]` View Service Status - Check if running, see recent logs

## ✓ Files in This Folder

| File | Size | Purpose |
|------|------|---------|
| BackupManager.ps1 | ~20KB | Techy CMD-style UI (black + green) |
| AdvancedFolderBackup_v2.ps1 | ~85KB | Real-time backup engine |
| BackupConfig.json | ~1KB | Configuration (source, destination, days) |
| BackupLog.txt | Variable | Operation logs |
| README.md | This file | Documentation |

## ✓ Features

✓ Real-time folder monitoring  
✓ ZIP archiving with configurable retention  
✓ Automatic scheduled startup  
✓ Full admin permission handling  
✓ Elegant techy UI (CMD-style: black background + green text)  
✓ Easy configuration changes anytime  
✓ Runs as SYSTEM (highest privileges)  
✓ Minimal, clean interface

## ✓ Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator rights
- Read/write access to backup destinations
Archives:      D:\BackupArchives
Keep Archives: 30 days

##  Common Tasks

Check backup status:  StatusBackup.bat
Start backup:         StartBackup.bat
Stop backup:          StopBackup.bat
View logs:            Open BackupLog.txt
Change settings:      BackupControl.bat

##  Troubleshooting

Status shows STOPPED?
   Run: StartBackup.bat then StatusBackup.bat

Files not backing up?
   Check BackupLog.txt for errors
   Verify source folder path is correct

Can't create task?
   Make sure to right-click and "Run as Administrator"
   Try CreateTask_AdminVersion.ps1 instead

---

Version: 2.0 | Last Updated: 2026-02-18
