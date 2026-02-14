# Service Control - Quick Reference

## 🚀 Quick Start

### **5 Ways to Control Your Backup Service**

---

## **1. 🔵 Double-Click Batch Files (EASIEST)**

Located in: `Data Science Class\Back tool\`

```
📁 Back tool
├─ StartBackup.bat          ← Start service
├─ StopBackup.bat           ← Stop service
├─ RestartBackup.bat        ← Restart service
├─ StatusBackup.bat         ← Check status
└─ BackupControl.bat        ← Full menu
```

### Usage:
- Double-click any `.bat` file
- Service starts/stops
- Done!

---

## **2. 📋 PowerShell Commands**

Open PowerShell in the `Back tool` folder and run:

```powershell
# Start service
.\AdvancedFolderBackup_v2.ps1 -Control Start

# Stop service
.\AdvancedFolderBackup_v2.ps1 -Control Stop

# Restart service
.\AdvancedFolderBackup_v2.ps1 -Control Restart

# Check status
.\AdvancedFolderBackup_v2.ps1 -Control Status
```

---

## **3. 🎮 Interactive Control Menu**

```powershell
.\AdvancedFolderBackup_v2.ps1 -Mode Control
```

Or double-click: `BackupControl.bat`

**Menu:**
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

Select option (1-5): _
```

---

## **4. 📊 Main Control Menu**

When you start the script normally (without -Control):

```
============================================================
ADVANCED FOLDER BACKUP TOOL v2.0
============================================================

Service Status: ✓ RUNNING

Options:
  (1) Settings & Configuration
  (2) Service Control (Start/Stop)
  (3) View Service Log
  (4) Exit
```

Select option **(2)** for Service Control

---

## **5. ⚙️ Windows Task Scheduler**

Advanced users can directly manage the scheduled task:

1. Press `Win + R`, type `taskschd.msc`
2. Find: **AdvancedFolderBackup**
3. Right-click → **Enable/Disable**

---

## 📊 Service States  

| Status | Icon | Meaning | Backups |
|--------|------|---------|---------|
| Running | ✓ 🟢 | Service active | ✅ Yes |
| Stopped | ✗ 🔴 | Service inactive | ❌ No |
| Disabled | ⊗ 🟡 | Task disabled | ❌ No |

---

## 🔄 Typical Workflow

### **Scenario 1: Stop for Maintenance**
```
Double-click: StopBackup.bat
         ↓
    Service stops
         ↓
   Do maintenance
         ↓
Double-click: StartBackup.bat
         ↓
    Service resumes
```

### **Scenario 2: Restart After Config Change**
```
Double-click: RestartBackup.bat
         ↓
    Service stops
         ↓
    2 second pause
         ↓
    Service starts
         ↓
   Config reloaded
```

### **Scenario 3: Check What's Happening**
```
Double-click: BackupControl.bat
         ↓
    Control menu opens
         ↓
    Select option (4) "View Service Log"
         ↓
    See last 20 log entries
```

---

## 📝 Common Tasks

### **"How do I stop the backups?"**
→ Double-click `StopBackup.bat`

### **"How do I start backups again?"**
→ Double-click `StartBackup.bat`

### **"Is the backup running?"**
→ Double-click `StatusBackup.bat` or run `BackupControl.bat` and look at service status

### **"I changed a setting, how do I apply it?"**
→ Double-click `RestartBackup.bat`

### **"What is the backup doing right now?"**
→ Double-click `BackupControl.bat` and select option (4) to view logs

### **"I want a menu of all options"**
→ Double-click `BackupControl.bat`

---

## ✅ Key Features

✓ **Start** - Enable backup service and run in background  
✓ **Stop** - Disable backup service (can restart anytime)  
✓ **Restart** - Stop then immediately start (reload config)  
✓ **Status** - Check if service is running  
✓ **Control Menu** - Full interactive management  
✓ **Logs** - View what the service is doing  

---

## ⚠️ Important Notes

- ✅ Closing the window **doesn't stop** the service
- ✅ Service runs in **background** after starting
- ✅ You can **stop anytime** - no data loss
- ✅ **Restart** to load configuration changes
- ✅ Check **BackupLog.txt** for detailed information

---

## 📁 Files at a Glance

| File | What It Does | When To Use |
|------|--------------|-----------|
| **StartBackup.bat** | Start service | Resume backups |
| **StopBackup.bat** | Stop service | Pause backups |
| **RestartBackup.bat** | Stop then start | Apply config changes |
| **StatusBackup.bat** | Show status | Check if running |
| **BackupControl.bat** | Open menu | Full control panel |

---

## 🔗 Related Documentation

- **[START_STOP_GUIDE.md](START_STOP_GUIDE.md)** - Detailed start/stop guide
- **[QUICK_START_CLOUD_FREEING.md](QUICK_START_CLOUD_FREEING.md)** - Cloud storage info
- **[BackupLog.txt](BackupLog.txt)** - Detailed service logs

---

**Version:** 2.0+ | **Date:** February 14, 2026

**💡 Tip:** Right-click batch files → "Pin to Quick Access" for instant access!
