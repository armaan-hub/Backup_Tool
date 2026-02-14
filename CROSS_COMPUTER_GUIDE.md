# Cross-Computer Compatibility Guide

## Advanced Folder Backup Tool v2.0

## Overview

This guide explains how the Enhanced Version 2.0 of the Advanced Folder Backup Tool achieves full cross-computer compatibility and how to deploy it across different machines.

---

## Key Cross-Computer Features

### 1. **Dynamic Path Resolution**

- **Environment Variable Support**: Automatically expands variables like `%TEMP%`, `%USERPROFILE%`, `%APPDATA%`, `%COMPUTERNAME%`, `%USERNAME%`
- **Flexible Path Input**: Accepts local drives, UNC network paths (\\server\share), and environment variables
- **Automatic Path Discovery**: Configuration file searched in multiple locations:
  1. Custom ConfigPath parameter
  2. Script directory
  3. AppData\AdvancedFolderBackup\

### 2. **System Information Tracking**

```text
Configuration stores:
- Computer Name (deployment machine)
- OS Version (Windows compatibility)
- Created Date/Time
- PowerShell Version
- .NET Version
- Architecture (x64/x86)
```

### 3. **Parameterized Configuration**
Script supports multiple execution modes for automation:

```powershell
# Mode 1: Interactive Setup (computer-specific)
.\AdvancedFolderBackup_v2.ps1 -Mode Setup

# Mode 2: Background with custom config location
.\AdvancedFolderBackup_v2.ps1 -Mode Background -ConfigPath "\\server\config\backup.json"

# Mode 3: Fully automated deployment
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "%USERPROFILE%\Documents" `
    -DestinationPath "D:\Backup\Documents" `
    -DaysToKeep 30

# Mode 4: Network share backup
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "\\fileserver\shared\data" `
    -DestinationPath "\\backupserver\backups\fileserver_data" `
    -DaysToKeep 90
```

---

## Deployment Scenarios

### Scenario 1: Same Computer, Different Users

```powershell
# Each user can have their own configuration
# Config file location: %APPDATA%\AdvancedFolderBackup\BackupConfig.json

# User A
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "%USERPROFILE%\Documents" `
    -DestinationPath "D:\Backups\%USERNAME%_Documents"

# User B (same computer)
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "%USERPROFILE%\Documents" `
    -DestinationPath "D:\Backups\%USERNAME%_Documents"
```

### Scenario 2: Multiple Computers with Centralized Config

```powershell
# Admin creates shared master configuration
# Deploy to multiple computers with custom config location

# Computer 1
.\AdvancedFolderBackup_v2.ps1 -Mode Background `
    -ConfigPath "\\admin-server\shared\configs\backup_template.json" `
    -SourcePath "D:\WorkData" `
    -DestinationPath "\\backup-server\backups\computer1"

# Computer 2
.\AdvancedFolderBackup_v2.ps1 -Mode Background `
    -ConfigPath "\\admin-server\shared\configs\backup_template.json" `
    -SourcePath "E:\ProjectData" `
    -DestinationPath "\\backup-server\backups\computer2"
```

### Scenario 3: Network-Based Backup

```powershell
# Backup from local machine to network share
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "C:\Important_Data" `
    -DestinationPath "\\nas\department\backups\%COMPUTERNAME%" `
    -DaysToKeep 60
```

### Scenario 4: Portable USB Backup

```powershell
# Deploy on USB with relative references
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "C:\Users\%USERNAME%\Documents" `
    -DestinationPath "E:\BackupDrive\%COMPUTERNAME%_Documents" `
    -DaysToKeep 14
```

---

## Configuration File Structure (v2.0 Enhanced)

```json
{
  "SourcePath": "C:\\Users\\john\\Documents",
  "DestinationPath": "D:\\Backups\\Documents",
  "ArchivePath": "D:\\Backups\\BackupArchives",
  "DaysToKeep": 30,
  "LastBackup": "2026-02-14T10:30:00",
  "Version": "2.0",
  "ComputerName": "DESKTOP-ABC123",
  "CreatedDateTime": "2026-02-14 10:15:22",
  "OSVersion": "Microsoft Windows 10.0.19045",
  "UseRelativePaths": false
}
```

### Fields

- **ComputerName**: Machine where config was created (for audit trail)
- **CreatedDateTime**: When configuration was first created
- **OSVersion**: Windows version for compatibility checking
- **UseRelativePaths**: Future feature for portable configs

---

## Cross-Computer Compatibility Features

### 1. Automatic Administrator Elevation

```powershell
# Script checks for admin rights
# If not admin, automatically restarts with /Verb RunAs
# Preserves all parameters during restart
```

**Compatibility**: ✓ Windows 7 SP1+ | ✓ Windows 10/11

### 2. Environment Variable Support

Automatically resolves these everywhere:

| Variable | Example | Use Case |
| --- | --- | --- |
| `%TEMP%` | C:\Users\john\AppData\Local\Temp | Temporary backups |
| `%USERPROFILE%` | C:\Users\john | User-specific folders |
| `%APPDATA%` | C:\Users\john\AppData\Roaming | Config storage |
| `%PROGRAMDATA%` | C:\ProgramData | System-wide config |
| `%COMPUTERNAME%` | DESKTOP-ABC123 | Machine-specific naming |
| `%USERNAME%` | john | User identification |

### 3. Network Path Compatibility

```powershell
# Standard UNC paths
\\fileserver\backups\%COMPUTERNAME%

# Domain-qualified paths
\\domain.local\backup\%COMPUTERNAME%

# IP-based paths
\\192.168.1.100\backups\%COMPUTERNAME%

# Mapped drive letters (dynamic)
Z:\backups\%COMPUTERNAME%
```

### 4. Task Scheduler Cross-Platform Support

- **Windows 7**: Creates task with compatibility settings
- **Windows 10/11**: Full support with latest features
- **Domain Computers**: Automatic fallback to SYSTEM account
- **Workgroup Computers**: Direct SYSTEM account usage

### 5. File System Watcher Compatibility

Works with:

- ✓ Local NTFS drives
- ✓ exFAT USB drives
- ✓ Network shares (SMB/CIFS)
- ✓ Cloud-synced folders (with caveats)
- ✗ ReFS (requires custom handling)

---

## Deployment Best Practices

### For IT Deployment

```powershell
# Use this script to deploy to multiple computers
$computers = @("COMP01", "COMP02", "COMP03")
$sharedConfig = "\\admin\backup_configs\standard.json"

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        param($configPath, $scriptPath)
        & $scriptPath -Mode Background -ConfigPath $configPath
    } -ArgumentList $sharedConfig, "C:\Scripts\AdvancedFolderBackup_v2.ps1"
}
```

### For Individual Users

```powershell
# Simple setup with environment variables
# Run on any Windows machine with custom paths
.\AdvancedFolderBackup_v2.ps1 -Mode Setup
```

### For Silent/Automated Deployment

```powershell
# Deploy without user interaction
.\AdvancedFolderBackup_v2.ps1 -Mode Setup `
    -SourcePath "C:\Important_Files" `
    -DestinationPath "D:\Backup\$env:COMPUTERNAME" `
    -DaysToKeep 30

# Start background service immediately
& 'C:\Program Files\BackupTool\AdvancedFolderBackup_v2.ps1' -Mode Background
```

---

## Troubleshooting Cross-Computer Issues

### Issue 1: "Source path not found"

**Cause**: Environment variables not expanded on target computer

**Solution**:

```powershell
# Use explicit paths on each computer
# OR use environment variables that exist on all machines
# Check with: Get-ChildItem env:
```

### Issue 2: Permission Denied on Network Share

**Cause**: Network credentials not available in SYSTEM context

**Solution**:

```powershell
# Run as current user instead of SYSTEM
# Edit Task Scheduler: Change principal to current user
# Or use network credentials in full UNC path: \\user:pass@server\share (not recommended)
```

### Issue 3: Task Scheduler Not Created

**Cause**: Non-admin user, or domain restrictions

**Solution**:

```powershell
# Run PowerShell as Administrator
# Contact domain admin for policy changes
# Use manual scheduled task creation instead
```

### Issue 4: FileSystemWatcher Not Detecting Changes

**Cause**: Network share permissions or firewall

**Solution**:

```powershell
# Test network share accessibility:
Test-Path \\server\share
Get-ChildItem \\server\share

# For network drives, use local cache:
# Backup to local drive, then sync to network
```

---

## Configuration Migration Between Computers

### Step 1: Export Configuration
```powershell
# From source computer, get the config
$config = Get-Content "$env:APPDATA\AdvancedFolderBackup\BackupConfig.json"
$config | Out-File "backup_config_export.json"
```

### Step 2: Adapt for New Computer
```powershell
# Edit paths for new computer context
# %COMPUTERNAME% will be auto-updated
# %USERPROFILE% will be auto-resolved
# OS Version and creation date will update
```

### Step 3: Import Configuration
```powershell
# On target computer
Copy-Item "backup_config_export.json" -Destination "$env:APPDATA\AdvancedFolderBackup\BackupConfig.json"
```

---

## Version 1.0 vs Version 2.0 Comparison

| Feature | v1.0 | v2.0 |
|---------|------|------|
| Environment Variables | ✗ | ✓ |
| Parameterized Setup | ✗ | ✓ |
| Custom Config Paths | ✗ | ✓ |
| Network Path Support | Limited | ✓ |
| System Info Storage | ✗ | ✓ |
| Cross-Computer Deployment | Limited | ✓ |
| Automated Deployment | ✗ | ✓ |
| Multi-Computer Management | ✗ | ✓ |

---

## Requirements by Scenario

### Local Backup
- Windows 7 SP1+
- PowerShell 5.1
- Admin rights (for Task Scheduler)
- Local disk space

### Network Backup
- Windows 7 SP1+
- PowerShell 5.1
- Network connectivity
- SMB/CIFS access to share
- Network credentials or domain membership

### Centralized Deployment
- Windows 7 SP1+ on all targets
- PowerShell 5.1 on all targets
- Admin rights on all targets
- Network access to share for config files
- Domain or workgroup setup

---

## Security Considerations for Deployment

### Configuration Security
```powershell
# Store configs with restricted access
icacls "$env:APPDATA\AdvancedFolderBackup\BackupConfig.json" /grant:r "%USERNAME%:F" /inheritance:r
```

### Network Share Security
```powershell
# Ensure backup locations are secured
# Use NTFS permissions or network share ACLs
# Encrypt transportation of sensitive data (use VPN if needed)
```

### Credential Management
```powershell
# NEVER hardcode passwords in config files
# Use network authentication or credential manager
# For UNC paths, use group managed service accounts (domain)
```

---

## Automation Scripts

### Multi-Computer Deployment Script
```powershell
# See deployment examples above
# Save as: Deploy-BackupTool.ps1
```

### Configuration Validation Script
```powershell
# Validate config on each computer before deployment
$config = Get-Content "BackupConfig.json" | ConvertFrom-Json

# Check paths
Test-Path $config.SourcePath        # Should be $true
Test-Path $config.DestinationPath   # Should be $true

# Check permissions
icacls $config.SourcePath            # Should have Read
icacls $config.DestinationPath       # Should have Modify

# Check Task Scheduler
Get-ScheduledTask -TaskName "AdvancedFolderBackup" | Select-Object State
```

---

## Next Steps

1. **Choose Your Scenario**: Select from deployment scenarios above
2. **Configure Parameters**: Use environment variables and placeholders
3. **Test on One Machine**: Verify before broad deployment
4. **Deploy to Multiple Machines**: Use automation scripts
5. **Monitor and Validate**: Check logs and verify backups

---

## Support Information

- **Configuration Files**: Located in `%APPDATA%\AdvancedFolderBackup\` or script directory
- **Log Files**: Same directory as configuration
- **Task Scheduler**: Check Windows Task Scheduler under Microsoft\Windows\AdvancedFolderBackup
- **Troubleshooting**: Review BackupLog.txt for detailed error messages