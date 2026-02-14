# Cloud Space Freeing Feature - Enhanced Backup Tool

## Overview

The Advanced Folder Backup Tool now includes **automatic cloud storage space freeing** functionality. This feature optimizes cloud storage by freeing up local disk space on cloud drives (OneDrive, Google Drive, Dropbox, etc.) after backups are completed and at system startup.

## How It Works

### 1. **Cloud Drive Detection**
The tool automatically detects if backup destinations are located on cloud storage services:
- **OneDrive** (Microsoft)
- **Google Drive**
- **Dropbox**
- **iCloudDrive**

### 2. **Automatic Space Freeing - Two Triggers**

#### **Trigger 1: On System Startup / Logon**
When the backup service starts (Windows Task Scheduler triggers):
- Runs immediately after ensuring destination folders exist
- Marks all existing backed-up files as "online-only"
- Frees up local storage for cloud-stored backup files
- Logs all actions to `BackupLog.txt`

#### **Trigger 2: After Backup Completion**
When backups finish and archives are created:
- Automatically marks archive files as online-only
- Frees up local disk space
- Marks backup destination files as online-only
- Optimizes cloud storage usage

### 3. **Cloud Provider Specific Behavior**

#### **OneDrive (Recommended)**
- Uses Windows attribute: `attrib +U` 
- Marks files as "online-only"
- Frees up local storage immediately
- **Supported on:** Windows 10/11 with modern OneDrive

#### **Google Drive**
- Requires manual selective sync configuration in Google Drive app
- Tool provides notifications for manual action

#### **Dropbox**
- Requires manual selective sync configuration in Dropbox app
- Tool provides notifications for manual action

## Configuration

### Enable/Disable Cloud Space Freeing

Edit `BackupConfig.json`:

```json
{
    "EnableCloudSpaceFreeing": true,        // Master enable/disable
    "FreeSpaceOnCloudDrives": true,         // Cloud space freeing flag
    "DestinationPath": "C:\\Users\\..\\OneDrive\\...",
    "ArchivePath": "C:\\Users\\..\\OneDrive\\...\\"
}
```

### Default Settings
- **EnableCloudSpaceFreeing**: `true` (enabled by default)
- **FreeSpaceOnCloudDrives**: `true` (enabled by default)

## Benefits

✅ **Automatic Storage Optimization**
- No manual intervention needed
- Runs automatically at startup and after backups

✅ **Works Only on Cloud Drives**
- Local backup destinations are unaffected
- Detects cloud paths automatically
- Safe for both cloud and local configurations

✅ **No File Deletion**
- Files remain in cloud storage
- Only local copies are removed
- Full recovery available from cloud

✅ **Logging & Monitoring**
- All actions logged to `BackupLog.txt`
- Track which files were optimized
- Troubleshooting information available

## Log Output Examples

### Startup Cloud Freeing
```
[2026-02-14 14:58:38] [INFO] Free up cloud storage space at startup...
[2026-02-14 14:58:38] [INFO] Starting cloud space freeing process
[2026-02-14 14:58:39] [INFO] Cloud drive detected in Destination (OneDrive): C:\Users\armaa\OneDrive\Desktop\Back-up\VBA
[2026-02-14 14:58:40] [INFO] OneDrive: Marked online-only: Document1.xlsx
[2026-02-14 14:58:40] [INFO] OneDrive: Marked online-only: Document2.docx
[2026-02-14 14:58:40] [INFO] Cloud space freeing completed: 25 files marked as online-only, 0 failures
```

### Post-Backup Cloud Freeing
```
[2026-02-14 15:07:41] [INFO] Archive management completed successfully
[2026-02-14 15:07:41] [INFO] Starting cloud space freeing process
[2026-02-14 15:07:42] [INFO] Cloud drive detected in Destination (OneDrive): C:\Users\armaa\OneDrive\Desktop\Back-up\VBA
[2026-02-14 15:07:42] [INFO] Cloud drive detected in Archive (OneDrive): C:\Users\armaa\OneDrive\Desktop\Back-up\BackupArchives
[2026-02-14 15:07:43] [INFO] OneDrive: Marked online-only: Backup_2026-02-14.zip
[2026-02-14 15:07:43] [INFO] Cloud space freeing completed: 28 files marked as online-only, 0 failures
```

## Technical Details

### Functions Involved

1. **`Invoke-CloudSpaceFreeup`**
   - Main orchestrator function
   - Processes destination and archive paths
   - Calls recursive markup function for each file

2. **`Invoke-RecursiveCloudMarkup`**
   - Marks individual files as online-only
   - Handles cloud provider-specific commands
   - Error handling and logging

3. **`Detect-CloudDrive`**
   - Identifies if path is on cloud storage
   - Returns cloud provider name

4. **`Free-CloudDriveSpace`**
   - Original helper function for single files
   - Enhanced in new version

### Execution Flow

```
Startup/Backup Complete
    ↓
Start-BackgroundMode
    ↓
Invoke-CloudSpaceFreeup (Startup)
    ↓
Invoke-ArchiveManagement
    ↓
Invoke-CloudSpaceFreeup (Post-Backup)
    ↓
Start-FileSystemWatcher
```

## Troubleshooting

### Files Not Marked as Online-Only

**Issue:** Cloud space not being freed

**Solutions:**
1. Verify Windows 10/11 is installed (required for `attrib +U`)
2. Check OneDrive is running and initialized
3. Ensure backup paths are on OneDrive root structure
4. Review `BackupLog.txt` for specific errors

### Permissions Error

**Issue:** "The cloud file provider is not running"

**Solution:**
1. Restart OneDrive: `taskkill /F /IM OneDrive.exe`
2. Wait 5 seconds
3. Reopen OneDrive
4. Run backup tool again

### Google Drive / Dropbox Files Not Optimized

**Expected Behavior:** Tool logs that manual configuration is needed

**Solution:**
1. Open Google Drive/Dropbox app
2. Configure selective sync manually
3. Choose which folders to keep offline vs. online-only

## Performance Impact

- **Minimal:** Cloud space freeing is lightweight process
- **Duration:** ~2 seconds per 100 backed-up files
- **No blocking:** File watcher continues monitoring during freeing
- **Logged:** All operations tracked for audit

## Safety Notes

🔒 **Data Safety**
- No files are deleted
- All files remain in cloud storage
- Only local copies removed to save space
- Always restorable from cloud

🔒 **Automatic Operation**
- Respects configuration settings
- Safe to enable/disable anytime
- Can be tested with single backup run

🔒 **Backup Integrity**
- Archives remain intact
- Backup functionality unchanged
- File recovery unaffected

## FAQ

**Q: Will my files be deleted?**
A: No. Files remain in cloud storage; only local copies are removed.

**Q: What if OneDrive is not running?**
A: Tool logs the error and continues. Files remain as-is until next sync.

**Q: Can I disable this feature?**
A: Yes, set `EnableCloudSpaceFreeing` to `false` in BackupConfig.json

**Q: Does this affect local backup destinations?**
A: No. Cloud drive detection automatically skips local paths.

**Q: How much space does this free?**
A: Depends on backup size. Typically frees the same amount of space as your backup files take.

---

**Version:** 2.0+ with Cloud Space Freeing
**Last Updated:** February 14, 2026
