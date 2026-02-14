@echo off
REM ============================================================================
REM Advanced Folder Backup Tool - CONTROL Menu Script
REM ============================================================================
REM This batch file opens the interactive control menu
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

REM Run PowerShell script in Control mode (interactive menu)
title Advanced Folder Backup Tool - Control Menu
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '!PS_SCRIPT!' -Mode Control"
