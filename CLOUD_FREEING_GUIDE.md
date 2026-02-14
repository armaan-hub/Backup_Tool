# Cloud Drive Space Freeing Feature

## Overview
The Advanced Folder Backup Tool now automatically frees up local disk space when backups are created in cloud drives (OneDrive, Google Drive, Dropbox, etc.).

## How It Works

### 1. **Cloud Drive Detection**
The tool automatically detects when backup destination is in a cloud folder:
- **OneDrive** - Detects paths containing "OneDrive"
- **Google Drive** - Detects paths containing "Google Drive" or "GoogleDrive"
- **Dropbox** - Detects paths containing "Dropbox"
- **iCloud Drive** - Detects paths containing "iCloudDrive"

### 2. **Automatic Space Freeing**

#### OneDrive (Fully Supported)
When a file is backed up to OneDrive:
1. File is copied to backup destination
2. Tool automatically runs: `attrib +U "file_path"`
3. File is marked as **"online-only"** in OneDrive
4. OneDrive removes the local copy from disk
5. File remains accessible online, freeing local space

**Result:** You save local disk space while keeping backups synced to cloud!

#### Google Drive & Dropbox
- Cloud locations are detected
- User is notified in logs
- Requires manual selective sync settings in app to optimize space

### 3. **Log Messages**

When a file is backed up to OneDrive and marked online-only, you'll see:
```
[TIMESTAMP] [INFO] OneDrive: Marked as online-only (free up space): C:\Users\...\file.txt
```

## Current Setup

Your backup configuration:
- **Source:** `C:\Users\armaa\...\VBA`
- **Destination:** `C:\Users\armaa\OneDrive\Desktop\Back-up\VBA` ← **OneDrive detected!**
- **Archives:** `C:\Users\armaa\OneDrive\Desktop\Back-up\BackupArchives` ← **OneDrive detected!**

✅ **Both individual backups and archives will automatically free up local space!**

## Technical Details

### Affected Operations
1. **Individual File Backups** - Each backed-up file marked online-only
2. **Daily Archives** - ZIP files marked online-only after creation
3. **Automatic Cleanup** - Old archives removed per retention policy

### Requirements
- Windows 10/11 with modern OneDrive client
- OneDrive sync enabled
- Administrator privileges (not required for freeing, but may be needed for scheduled tasks)

### Disk Space Savings
For a 50GB backup:
- **Without freeing:** 50GB local space consumed
- **With freeing:** ~0KB local space (file stored online only)
- **Access:** Files remain instantly accessible online

## Testing

To verify the cloud freeing is working:

```powershell
# Check if file has online-only attribute (U flag):
attrib "C:\Users\armaa\OneDrive\Desktop\Back-up\VBA\YourFile.txt"

# Look for 'U' in output - it means online-only!
# Example output: A      O      U      C:\...
```

The backup log will also show:
```
[INFO] OneDrive: Marked as online-only (free up space): ...
```

## Supported Cloud Providers

| Provider | Status | Method |
|----------|--------|--------|
| OneDrive | ✅ Fully Supported | `attrib +U` (automatic) |
| Google Drive | 🟡 Detected | Requires Drive app settings |
| Dropbox | 🟡 Detected | Requires selective sync settings |
| iCloud Drive | 🟡 Detected | Requires selective sync settings |

## Benefits

✅ **Automatic** - No manual intervention needed
✅ **Transparent** - Works silently in the background
✅ **Efficient** - Balances cloud sync with local space
✅ **Logged** - All operations recorded in backup log
✅ **Smart** - Only applies to cloud-detected paths

## Troubleshooting

**Issue:** Files not marked online-only after backup

**Solution:**
1. Verify you're running Windows 10/11 with latest OneDrive
2. Check that OneDrive sync is enabled
3. Review backup logs for any `attrib` command failures
4. Manually run: `attrib +U "file_path"` to test

**Issue:** OneDrive taking time to sync changes

**Normal:** OneDrive may take a few seconds to process the online-only flag. This is expected behavior.

---

**Version:** 2.0+ with Cloud Freeing
**Last Updated:** 2026-02-14
