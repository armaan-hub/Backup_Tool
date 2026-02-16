# Enhanced Cloud Space Freeing - Complete Documentation

## Overview

The backup tool now includes **comprehensive cloud space freeing** that automatically optimizes both **source** and **destination** paths whenever they are on cloud drives (OneDrive, Google Drive, Dropbox, iCloud). This happens at **multiple strategic points** to minimize load and maximize performance.

## How It Works

### 1. **Pre-Backup Cloud Space Freeing** (`Invoke-ProactiveCloudSpaceFreeup`)
**When:** Before any backup operation starts
**What:** Marks files as "online-only" on BOTH source and destination cloud drives
**Why:** Frees up local disk space and reduces system load before large backup operations

**Processes:**
- Scans source path (if on cloud drive)
- Scans destination path (if on cloud drive)
- Marks all files as online-only: `attrib +U <file>`
- Skips temporary files (.tmp, .temp, .lock, ~$*)

### 2. **Post-Backup Cloud Space Cleanup** (`Invoke-CloudSpaceFreeup`)
**When:** After backup completes
**What:** Marks already-backed-up files as "online-only" on destination and archive
**Why:** Further reduces storage usage of backed-up data

**Processes:**
- Cleans destination path
- Cleans archive path
- Marks all backup files as online-only

### 3. **Per-Operation Space Optimization**
**When:** Every 10 file backup operations
**What:** Runs both pre-backup and post-backup freeing during active backups
**Why:** Maintains optimal performance throughout long backup sessions

## Execution Timeline

```
BACKUP STARTUP
    ↓
Pre-Backup Optimization (Invoke-ProactiveCloudSpaceFreeup)
    ├─ Free source cloud drive
    └─ Free destination cloud drive
    ↓
Post-Backup Cleanup (Invoke-CloudSpaceFreeup)
    ├─ Clean destination
    └─ Clean archive
    ↓
FILE MONITORING BEGINS
    ↓
[File Change Detected] → [Every 10 Operations]
    ├─ Pre-Backup: Invoke-ProactiveCloudSpaceFreeup (free source + destination)
    ├─ Backup file
    ├─ Post-Backup: Invoke-CloudSpaceFreeup (clean destination + archive)
    ↓
[Continue Monitoring...]
```

## Configuration

### Enable/Disable Cloud Space Freeing

In `BackupConfig.json`:
```json
{
  "EnableCloudSpaceFreeing": true,        // Master switch
  "FreeSpaceOnCloudDrives": true          // Enable cloud drive optimization
}
```

**Both must be `true` for cloud space freeing to work.**

## Supported Cloud Drives

| Provider | Status | Method |
|----------|--------|--------|
| **OneDrive** | ✅ Fully Supported | `attrib +U` command |
| **Google Drive** | ⚠️ Manual | Use Drive app selective sync |
| **Dropbox** | ⚠️ Manual | Use Dropbox app selective sync |
| **iCloud Drive** | ⚠️ Manual | Use System Preferences |

## Example Flow

### Scenario: Backing up 50 files from OneDrive to OneDrive

```
1. STARTUP (1 operation)
   → Pre-backup freeing: OneDrive source files marked online-only
   → Post-backup freeing: OneDrive destination cleaned
   
2. FILE MONITOR ACTIVE
   → File 1 changed: Operations = 1 (no freeing)
   → File 2 changed: Operations = 2 (no freeing)
   → ...
   → File 10 changed: Operations = 10 ✓
     • Pre-freeing: Both source + destination freed
     • File backed up
     • Post-freeing: Destination cleaned
   → ...
   → File 20 changed: Operations = 20 ✓
     • Cloud space freed again
   → File 30, 40, 50: Same pattern
```

## Performance Benefits

✅ **Reduced local disk pressure** - Files marked online-only free up storage
✅ **Better backup performance** - More free disk space = faster backups
✅ **Automatic optimization** - Happens without user intervention
✅ **Low overhead** - Throttled to every 10 operations to prevent slowdown
✅ **Smart caching** - Only marks files that already exist as online-only

## Logs

All cloud space freeing operations are logged:

```
[2026-02-16 19:30:15] [INFO] Pre-backup cloud space optimization starting...
[2026-02-16 19:30:15] [INFO] Cloud drive detected in Source (OneDrive): Freeing up space...
[2026-02-16 19:30:16] [INFO] OneDrive: Marked online-only: document.docx
[2026-02-16 19:30:16] [INFO] OneDrive: Marked online-only: spreadsheet.xlsx
[2026-02-16 19:30:16] [INFO] Source path cleanup: 2 files marked as online-only
[2026-02-16 19:30:16] [INFO] Pre-backup optimization completed: 2 files optimized
```

## Throttling Strategy

- **Per-operation throttle:** Every 10 backup operations (files created/changed)
- **Prevents:** Excessive disk access, system load spike
- **Ensures:** Consistent performance during active backup sessions
- **Balances:** Optimization frequency vs. system resource usage

## Troubleshooting

### Cloud space freeing not working?

1. **Check configuration:**
   ```powershell
   Get-Content BackupConfig.json | Select-String "CloudSpaceFreeing"
   ```
   Both should be `true`

2. **Check if cloud drive detected:**
   - Look in logs for: `Cloud drive detected in Source`
   - Verify source/destination are actually on cloud drives

3. **OneDrive-specific:**
   - Ensure OneDrive is syncing (not paused)
   - Files must not be actively open/locked
   - Some system files cannot be marked online-only

4. **Check permissions:**
   - Must have write access to the cloud folder
   - Cloud app must be running (OneDrive, Dropbox, etc.)

### Performance degradation?

- Throttling is set to every 10 operations - adjust if needed
- Consider moving source/destination off cloud if data is very large
- Check system disk space availability

## What About Non-Cloud Drives?

✅ **Non-cloud drives are skipped** - Only cloud drives (OneDrive, Google Drive, Dropbox, iCloud) are processed
✅ **Local backups unaffected** - Local hard drives operate normally
✅ **Mixed scenarios supported** - Source on cloud, destination local (or vice versa)

## Advanced: Disabling for Specific Operations

To disable cloud space freeing for a backup session:

```powershell
# Using command line
& '.\AdvancedFolderBackup_v2.ps1' -Mode Background
# Then manually disable in config before starting

# Or modify BackupConfig.json temporarily:
"EnableCloudSpaceFreeing": false
"FreeSpaceOnCloudDrives": false
```

## Summary of Functions

| Function | Purpose | When |
|----------|---------|------|
| `Invoke-ProactiveCloudSpaceFreeup` | Free source + destination | At startup + every 10 ops |
| `Invoke-CloudSpaceFreeup` | Clean destination + archive | At startup + every 10 ops |
| `Invoke-RecursiveCloudMarkup` | Mark single file online-only | Called by above functions |
| `Detect-CloudDrive` | Detect cloud provider | Used by all freeing functions |

## Results You'll See

✅ **Immediate benefits:**
- Local disk space freed (files marked online-only)
- Faster backup operations (less disk contention)
- Reduced system load during backups

✅ **Over time:**
- Consistent backup performance
- Lower local storage usage
- Cloud storage optimized

---

**Configuration:** `BackupConfig.json`  
**Enabled by default:** ✅ Yes  
**User action required:** ❌ No (automatic)  
