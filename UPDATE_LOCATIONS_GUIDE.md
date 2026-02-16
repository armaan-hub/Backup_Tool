# UpdateBackupLocations.bat - Quick Usage Guide

## What is This?

`UpdateBackupLocations.bat` is an **interactive menu-driven tool** that lets you easily change your backup locations without editing JSON files.

## How to Use

### Step 1: Open the Tool
Simply **double-click** this file:
```
UpdateBackupLocations.bat
```

A green menu will appear with 6 options.

### Step 2: Choose an Option

```
============================================
   BACKUP LOCATION MANAGER
============================================

   1. View Current Settings      ← See what's configured
   2. Change Source Path         ← Change WHERE TO BACKUP FROM
   3. Change Destination Path    ← Change WHERE BACKUPS ARE SAVED
   4. Change Archive Path        ← Change WHERE OLD BACKUPS ARE STORED
   5. Reset to Default Paths     ← Restore original settings
   6. Exit                       ← Quit the tool
```

### Step 3: Follow Prompts

When you select an option, the tool will:
- **Show current settings** (Option 1)
- **Prompt you for new path** (Options 2-4)
- **Update the config automatically** (Options 2-5)
- **Confirm the change** with color feedback

---

## Common Tasks

### Change Source Path (Where files are backed up FROM)
```
1. Run UpdateBackupLocations.bat
2. Select option: 2
3. Enter path: C:\Users\armaa\Documents\MyFiles
4. Press Enter
5. Select: 6 to Exit
```

### Change Destination Path (Where backups are SAVED)
```
1. Run UpdateBackupLocations.bat
2. Select option: 3
3. Enter path: C:\Users\armaa\OneDrive\Backups
4. Press Enter
5. Select: 6 to Exit
```

### View All Current Settings
```
1. Run UpdateBackupLocations.bat
2. Select option: 1
3. View all paths displayed
4. Select: 6 to Exit
```

### Reset to Original Defaults
```
1. Run UpdateBackupLocations.bat
2. Select option: 5
3. Type: yes
4. Press Enter
5. All paths reset to original values
```

---

## Path Examples

| Scenario | Source Path | Destination Path |
|----------|-------------|------------------|
| **OneDrive Local** | `C:\Users\armaa\OneDrive\Documents` | `C:\Users\armaa\OneDrive\Backups` |
| **External Drive** | `D:\MyFiles` | `E:\Backups` |
| **Network Drive** | `\\Server\SharedFolder` | `C:\LocalBackups` |
| **Class Files** | `C:\Users\armaa\Study` | `C:\Users\armaa\Backups\Study` |

---

## Important Notes

✅ **Paths must be absolute** (full path from C:\ or D:\)
✅ **Don't use relative paths** (like `\Backups` - won't work)
✅ **Folders don't need to exist** (they'll be created automatically)
✅ **Use backslashes** `\` in paths (the tool handles JSON formatting)
✅ **Changes take effect immediately** on next backup run

---

## For New Computers

When setting up on a completely new computer:

1. Copy the entire backup tool folder to the new computer
2. Run `UpdateBackupLocations.bat`
3. Update all three paths for the new computer:
   - Different username
   - Different drive letters
   - Different folder structure
4. Save and exit
5. Run `StartBackup.bat` to begin backups with new locations

---

## Troubleshooting

**Menu doesn't appear?**
- Make sure PowerShell is installed and enabled
- Try running as Administrator
- Check Windows execution policy

**Path update fails?**
- Ensure you have write permission to the config file
- Check that the path has no special characters
- Make sure BackupConfig.json exists in the same folder

**Path not saving?**
- Close all backup processes first
- Run UpdateBackupLocations.bat again
- Verify the new path in Option 1 (View Settings)

---

## Related Files

- `BackupConfig.json` - Configuration file (edited by this tool)
- `StartBackup.bat` - Run backups with current settings
- `AdvancedFolderBackup_v2.ps1` - Main backup script

---

**Status:** ✅ Ready to use - No technical knowledge needed!
