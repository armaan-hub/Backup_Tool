@echo off
REM ============================================================================
REM Advanced Folder Backup Tool - CHECK Status Script
REM ============================================================================
REM This batch file checks the backup service status
REM 

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%AdvancedFolderBackup_v2.ps1"

REM Check if PowerShell script exists
if not exist "!PS_SCRIPT!" (
    echo Error: AdvancedFolderBackup_v2.ps1 not found in !SCRIPT_DIR!
    timeout /t 5
    exit /b 1
)

REM Run PowerShell script with Status control
title Advanced Folder Backup Tool - Service Status
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '!PS_SCRIPT!' -Control Status"

pause
