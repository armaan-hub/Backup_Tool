@echo off
setlocal enabledelayedexpansion
color 0A
title Advanced Folder Backup - Location Manager

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0
set CONFIG_FILE=%SCRIPT_DIR%BackupConfig.json

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    color 0C
    echo.
    echo ERROR: BackupConfig.json not found!
    echo Expected location: %CONFIG_FILE%
    echo.
    pause
    exit /b 1
)

:menu
cls
color 0A
echo.
echo ============================================
echo   BACKUP LOCATION MANAGER
echo ============================================
echo.
echo   1. View Current Settings
echo   2. Change Source Path
echo   3. Change Destination Path
echo   4. Change Archive Path
echo   5. Reset to Default Paths
echo   6. Exit
echo.
echo ============================================
set /p choice="Select option (1-6): "

if "%choice%"=="1" goto view_settings
if "%choice%"=="2" goto change_source
if "%choice%"=="3" goto change_destination
if "%choice%"=="4" goto change_archive
if "%choice%"=="5" goto reset_to_default
if "%choice%"=="6" goto exit_program

color 0C
echo Invalid choice! Please select 1-6.
timeout /t 2 >nul
goto menu

REM ============================================================================
REM VIEW CURRENT SETTINGS
REM ============================================================================
:view_settings
cls
echo.
echo ============================================
echo   CURRENT BACKUP SETTINGS
echo ============================================
echo.

powershell -NoProfile -Command ^
  "$json = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; " ^
  "Write-Host 'Source Path:'; " ^
  "Write-Host ('  ' + $json.SourcePath) -ForegroundColor Cyan; " ^
  "Write-Host ''; " ^
  "Write-Host 'Destination Path:'; " ^
  "Write-Host ('  ' + $json.DestinationPath) -ForegroundColor Cyan; " ^
  "Write-Host ''; " ^
  "Write-Host 'Archive Path:'; " ^
  "Write-Host ('  ' + $json.ArchivePath) -ForegroundColor Cyan; " ^
  "Write-Host ''; " ^
  "Write-Host 'Cloud Space Freeing: ' -NoNewLine; " ^
  "if ($json.EnableCloudSpaceFreeing) { Write-Host 'Enabled' -ForegroundColor Green } else { Write-Host 'Disabled' -ForegroundColor Red }"

echo.
pause
goto menu

REM ============================================================================
REM CHANGE SOURCE PATH
REM ============================================================================
:change_source
cls
echo.
echo ============================================
echo   CHANGE SOURCE PATH
echo ============================================
echo.
echo This is the folder YOU WANT TO BACKUP FROM
echo.
echo Example:
echo   C:\Users\armaa\OneDrive - The Era Corporations\Study\AI Class\VBA
echo   D:\MyDocuments
echo   C:\Projects
echo.
set /p new_source="Enter new Source Path: "

if "!new_source!"=="" (
    color 0C
    echo Source path cannot be empty!
    timeout /t 2 >nul
    goto menu
)

powershell -NoProfile -Command ^
  "try { " ^
  "$json = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; " ^
  "$json.SourcePath = '!new_source!'; " ^
  "$json | ConvertTo-Json | Set-Content '%CONFIG_FILE%'; " ^
  "Write-Host 'Source path updated successfully!' -ForegroundColor Green; " ^
  "Write-Host 'New path: !new_source!' -ForegroundColor Cyan; " ^
  "} catch { " ^
  "Write-Host 'Error updating config: ' + $_.Exception.Message -ForegroundColor Red; " ^
  "}"

timeout /t 3 >nul
goto menu

REM ============================================================================
REM CHANGE DESTINATION PATH
REM ============================================================================
:change_destination
cls
echo.
echo ============================================
echo   CHANGE DESTINATION PATH
echo ============================================
echo.
echo This is the folder WHERE BACKUPS ARE SAVED
echo.
echo Example:
echo   C:\Users\armaa\OneDrive\Desktop\Back-up\VBA
echo   D:\Backups
echo   E:\ExternalDrive\Backups
echo.
set /p new_destination="Enter new Destination Path: "

if "!new_destination!"=="" (
    color 0C
    echo Destination path cannot be empty!
    timeout /t 2 >nul
    goto menu
)

powershell -NoProfile -Command ^
  "try { " ^
  "$json = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; " ^
  "$json.DestinationPath = '!new_destination!'; " ^
  "$json | ConvertTo-Json | Set-Content '%CONFIG_FILE%'; " ^
  "Write-Host 'Destination path updated successfully!' -ForegroundColor Green; " ^
  "Write-Host 'New path: !new_destination!' -ForegroundColor Cyan; " ^
  "} catch { " ^
  "Write-Host 'Error updating config: ' + $_.Exception.Message -ForegroundColor Red; " ^
  "}"

timeout /t 3 >nul
goto menu

REM ============================================================================
REM CHANGE ARCHIVE PATH
REM ============================================================================
:change_archive
cls
echo.
echo ============================================
echo   CHANGE ARCHIVE PATH
echo ============================================
echo.
echo This is where OLD/COMPRESSED backups are stored
echo.
echo Example:
echo   C:\Users\armaa\OneDrive\Desktop\Back-up\BackupArchives
echo   D:\Backups\Archives
echo   E:\ExternalDrive\Archives
echo.
set /p new_archive="Enter new Archive Path: "

if "!new_archive!"=="" (
    color 0C
    echo Archive path cannot be empty!
    timeout /t 2 >nul
    goto menu
)

powershell -NoProfile -Command ^
  "try { " ^
  "$json = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; " ^
  "$json.ArchivePath = '!new_archive!'; " ^
  "$json | ConvertTo-Json | Set-Content '%CONFIG_FILE%'; " ^
  "Write-Host 'Archive path updated successfully!' -ForegroundColor Green; " ^
  "Write-Host 'New path: !new_archive!' -ForegroundColor Cyan; " ^
  "} catch { " ^
  "Write-Host 'Error updating config: ' + $_.Exception.Message -ForegroundColor Red; " ^
  "}"

timeout /t 3 >nul
goto menu

REM ============================================================================
REM RESET TO DEFAULT PATHS
REM ============================================================================
:reset_to_default
cls
color 0E
echo.
echo ============================================
echo   RESET TO DEFAULT PATHS
echo ============================================
echo.
echo WARNING: This will reset all paths to their original values!
echo.
echo Current default paths:
echo   Source:      C:\Users\armaa\OneDrive - The Era Corporations\Study\AI Class\VBA
echo   Destination: C:\Users\armaa\OneDrive\Desktop\Back-up\VBA
echo   Archive:     C:\Users\armaa\OneDrive\Desktop\Back-up\BackupArchives
echo.
set /p confirm="Are you sure? (yes/no): "

if /i "!confirm!"=="yes" (
    powershell -NoProfile -Command ^
      "try { " ^
      "$json = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; " ^
      "$json.SourcePath = 'C:\\Users\\armaa\\OneDrive - The Era Corporations\\Study\\AI Class\\VBA'; " ^
      "$json.DestinationPath = 'C:\\Users\\armaa\\OneDrive\\Desktop\\Back-up\\VBA'; " ^
      "$json.ArchivePath = 'C:\\Users\\armaa\\OneDrive\\Desktop\\Back-up\\BackupArchives'; " ^
      "$json | ConvertTo-Json | Set-Content '%CONFIG_FILE%'; " ^
      "Write-Host 'All paths reset to default successfully!' -ForegroundColor Green; " ^
      "} catch { " ^
      "Write-Host 'Error resetting paths: ' + $_.Exception.Message -ForegroundColor Red; " ^
      "}"
    
    timeout /t 3 >nul
) else (
    echo Cancelled.
    timeout /t 2 >nul
)
goto menu

REM ============================================================================
REM EXIT
REM ============================================================================
:exit_program
cls
color 0A
echo.
echo ============================================
echo   CONFIGURATION SAVED
echo ============================================
echo.
echo Your backup location settings have been updated.
echo The changes will take effect on the next backup run.
echo.
echo To start a backup with these new locations, run:
echo   StartBackup.bat
echo.
pause
exit /b 0
