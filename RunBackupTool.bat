@echo off
echo Advanced Folder Backup Tool - Launcher
echo =====================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo PowerShell is not available on this system.
    pause
    exit /b 1
)

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Check if the PowerShell script exists
if not exist "%SCRIPT_DIR%AdvancedFolderBackup_v2.ps1" (
    echo AdvancedFolderBackup_v2.ps1 not found in the current directory.
    pause
    exit /b 1
)

echo Starting Advanced Folder Backup Tool in background...
echo The tray icon will appear in your system tray.
echo.

REM Run PowerShell with hidden window (no console visible)
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_DIR%AdvancedFolderBackup_v2.ps1" -Mode Background

echo.
echo Script execution completed.
pause