# Cloud Space Freeing - Quick Start Guide

## What Was Added?

Your backup tool now **automatically frees up space on your OneDrive** after backups complete and when your computer starts up. No files are deleted - they just get moved to "online-only" status to free up local storage.

## When Does It Happen?

### 1. When Your Computer Starts/Logs In
- Windows automatically runs the backup service
- Tool immediately marks backed-up files as online-only
- Frees local storage while keeping files in cloud

### 2. After Each Backup Completes
- Creates daily archive
- Automatically marks archive files as online-only
- Further optimizes cloud storage usage

## How to Verify It's Working

### Check the Log File
```
Path: C:\Users\armaa\OneDrive - The Era Corporations\Study\AI Class\Data Science Class\Back tool\BackupLog.txt
```

Look for entries like:
```
[2026-02-14 14:58:39] [INFO] Starting cloud space freeing process
[2026-02-14 14:58:39] [INFO] Cloud drive detected in Destination (OneDrive): ...
[2026-02-14 14:58:40] [INFO] OneDrive: Marked online-only: filename.xlsx
[2026-02-14 14:58:40] [INFO] Cloud space freeing completed: 25 files marked as online-only, 0 failures
```

### Check OneDrive Status
- Open **OneDrive** from system tray
- Backed-up files should show **cloud icon** (not downloaded)
- Local storage freed up

## Enable/Disable the Feature

### To Disable Cloud Space Freeing
Edit `BackupConfig.json`:
```json
"EnableCloudSpaceFreeing": false,
"FreeSpaceOnCloudDrives": false
```

### To Re-Enable It
```json
"EnableCloudSpaceFreeing": true,
"FreeSpaceOnCloudDrives": true
```

## Important Notes

✅ **Files Are Safe**
- Nothing is deleted
- Files remain in OneDrive
- Always recoverable

✅ **Works Only on OneDrive**
- Local backups unaffected
- Detects cloud drive automatically
- Safe for any backup location

✅ **Requires Windows 10/11**
- OneDrive attribute command needs modern Windows
- Should work on almost all setups

## Troubleshooting

### Cloud Space Not Being Freed?
1. Check BackupLog.txt for errors
2. Verify OneDrive is running
3. Verify backup location is on OneDrive
4. Check if EnableCloudSpaceFreeing is true in config

### Can't Find Log File?
Look in: 
```
Data Science Class\Back tool\BackupLog.txt
```

### Want to Run It Now?
Simply restart your backup service or reboot computer.

## File Locations

| File | Purpose |
|------|---------|
| `AdvancedFolderBackup_v2.ps1` | Main backup script (updated) |
| `BackupConfig.json` | Configuration with cloud freeing settings |
| `BackupLog.txt` | Detailed log of all operations |
| `CLOUD_SPACE_FREEING_FEATURE.md` | Full technical documentation |
| `IMPLEMENTATION_SUMMARY.md` | Implementation details |

## Next Steps

1. **Check the logs** to verify cloud space freeing is running
2. **Monitor OneDrive** to see files marked as online-only
3. **Verify local storage** is being freed up
4. **Enable/disable** the feature as needed in config

---

**Questions?** Refer to [CLOUD_SPACE_FREEING_FEATURE.md](CLOUD_SPACE_FREEING_FEATURE.md) for detailed documentation.
