#Requires -Version 5.1

param()

# CONFIGURATION & GLOBALS
$script:ScriptPath = $MyInvocation.MyCommand.Path
$script:ScriptDir = Split-Path -Parent $script:ScriptPath
$script:ConfigFile = Join-Path $script:ScriptDir "BackupConfig.json"
$script:TaskName = "AdvancedFolderBackup"
$script:BackupScript = Join-Path $script:ScriptDir "AdvancedFolderBackup_v2.ps1"
$script:LogFile = Join-Path $script:ScriptDir "BackupLog.txt"

# UI FUNCTIONS
function Clear-Screen {
    Clear-Host
}

function Write-Header {
    param([string]$Title)
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  $Title" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $colors = @{ "INFO" = "Green"; "SUCCESS" = "Green"; "ERROR" = "Red"; "WARNING" = "Yellow" }
    Write-Host "[>] $Message" -ForegroundColor $colors[$Status]
}

function Write-Input {
    param([string]$Prompt = "Enter")
    Write-Host "[>] $Prompt : " -ForegroundColor Green -NoNewline
    Read-Host
}

function Pause-Screen {
    Write-Host ""
    Write-Host "[>] Press Enter to continue..." -ForegroundColor Green
    Read-Host | Out-Null
}

# ADMIN CHECK
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Administrator {
    if (-not (Test-Administrator)) {
        Clear-Screen
        Write-Host "ADMIN REQUIRED"  -ForegroundColor Red
        Write-Host "Requesting elevation..." -ForegroundColor Yellow
        $params = "-NoExit -ExecutionPolicy Bypass -File `"$script:ScriptPath`""
        Start-Process PowerShell -Verb RunAs -ArgumentList $params
        exit
    }
}

# CONFIG FUNCTIONS
function Load-Config {
    if (Test-Path $script:ConfigFile) {
        try {
            return Get-Content $script:ConfigFile -Raw | ConvertFrom-Json
        }
        catch {
            return $null
        }
    }
    return $null
}

function Save-Config {
    param($Config)
    $Config | ConvertTo-Json -Depth 2 | Out-File $script:ConfigFile -Encoding UTF8 -Force
    Write-Status "Configuration saved" "SUCCESS"
}

function Show-Config {
    param($Config)
    Clear-Screen
    Write-Header "CURRENT CONFIGURATION"
    if ($Config) {
        Write-Host "Source Path: $($Config.SourcePath)" -ForegroundColor Green
        Write-Host "Destination Path: $($Config.DestinationPath)" -ForegroundColor Green
        Write-Host "Archive Path: $($Config.ArchivePath)" -ForegroundColor Green
        Write-Host "Retention (Days): $($Config.DaysToKeep)" -ForegroundColor Green
    }
    else {
        Write-Status "No configuration found" "WARNING"
    }
    Pause-Screen
}

# SETUP FUNCTION
function Invoke-Setup {
    Clear-Screen
    Write-Header "SETUP WIZARD"
    $config = New-Object PSObject
    
    # Source
    Write-Host "[1/4] SOURCE FOLDER" -ForegroundColor Green
    do {
        $source = Write-Input "Source Path"
        if (-not (Test-Path $source -PathType Container)) {
            Write-Status "Invalid path - folder not found" "ERROR"
            $source = $null
        }
    } while (-not $source)
    
    # Destination
    Write-Host "`n[2/4] DESTINATION FOLDER" -ForegroundColor Green
    do {
        $dest = Write-Input "Destination Path"
        $parent = Split-Path -Parent $dest
        if ($parent -and -not (Test-Path $parent)) {
            Write-Status "Parent directory does not exist" "ERROR"
            $dest = $null
        }
    } while (-not $dest)
    
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }
    
    # Retention Days
    Write-Host "`n[3/4] RETENTION POLICY (0-365 days)" -ForegroundColor Green
    do {
        $days = Write-Input "Retention Days"
        $days = [int]$days
        if ($days -lt 0 -or $days -gt 365) {
            Write-Status "Invalid - enter 0-365" "ERROR"
            $days = -1
        }
    } while ($days -lt 0)
    
    # Archive
    $archive = Join-Path (Split-Path -Parent $dest) "BackupArchives"
    if (-not (Test-Path $archive)) {
        New-Item -ItemType Directory -Path $archive -Force | Out-Null
    }
    
    # Save
    Write-Host "`n[4/4] SAVING CONFIGURATION" -ForegroundColor Green
    $config | Add-Member -NotePropertyName "SourcePath" -NotePropertyValue $source
    $config | Add-Member -NotePropertyName "DestinationPath" -NotePropertyValue $dest
    $config | Add-Member -NotePropertyName "ArchivePath" -NotePropertyValue $archive
    $config | Add-Member -NotePropertyName "DaysToKeep" -NotePropertyValue $days
    $config | Add-Member -NotePropertyName "CreatedDate" -NotePropertyValue (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    Save-Config $config
    Write-Status "Setup completed!" "SUCCESS"
    
    Write-Host "`nCreate scheduled task? (yes/no)" -ForegroundColor Green
    $resp = Read-Host
    if ($resp -eq "yes" -or $resp -eq "y") {
        Invoke-CreateTask
    }
    
    Pause-Screen
    return $config
}

# TASK FUNCTIONS
function Test-TaskExists {
    $task = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
    return $null -ne $task
}

function Get-TaskStatus {
    $task = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
    if ($task) {
        return @{ Exists = $true; Enabled = $task.Enabled; State = $task.State }
    }
    return @{ Exists = $false }
}

function Invoke-CreateTask {
    Clear-Screen
    Write-Header "CREATE SCHEDULED TASK"
    
    if (Test-TaskExists) {
        Write-Status "Task already exists" "WARNING"
        Pause-Screen
        return
    }
    
    Write-Status "Creating scheduled task..." "INFO"
    Write-Host "Task Name: $script:TaskName" -ForegroundColor Green
    Write-Host "Trigger: At System Startup and User Login" -ForegroundColor Green
    Write-Host "Principal: SYSTEM" -ForegroundColor Green
    Write-Host ""
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
            -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script:BackupScript`" -ConfigPath `"$script:ConfigFile`" -Mode Background"
        
        $trigger1 = New-ScheduledTaskTrigger -AtStartup
        $trigger2 = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
        
        Register-ScheduledTask -TaskName $script:TaskName `
            -Action $action `
            -Trigger @($trigger1, $trigger2) `
            -Principal $principal `
            -Settings $settings `
            -Description "Advanced Folder Backup" `
            -Force | Out-Null
        
        Write-Status "Task created successfully!" "SUCCESS"
        
        Start-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Write-Status "Task started" "SUCCESS"
    }
    catch {
        Write-Status "Error: $($_.Exception.Message)" "ERROR"
    }
    
    Pause-Screen
}

function Invoke-DeleteTask {
    Clear-Screen
    Write-Header "DELETE SCHEDULED TASK"
    
    if (-not (Test-TaskExists)) {
        Write-Status "Task does not exist" "WARNING"
        Pause-Screen
        return
    }
    
    try {
        Unregister-ScheduledTask -TaskName $script:TaskName -Confirm:$false -ErrorAction Stop
        Write-Status "Task deleted successfully!" "SUCCESS"
    }
    catch {
        Write-Status "Error: $($_.Exception.Message)" "ERROR"
    }
    
    Pause-Screen
}

function Invoke-StartTask {
    $status = Get-TaskStatus
    if (-not $status.Exists) {
        Write-Status "Task does not exist - create it first" "ERROR"
        return
    }
    try {
        Enable-ScheduledTask -TaskName $script:TaskName -ErrorAction Stop | Out-Null
        Start-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
        Write-Status "Backup service started" "SUCCESS"
    }
    catch {
        Write-Status "Error: $($_)" "ERROR"
    }
}

function Invoke-StopTask {
    $status = Get-TaskStatus
    if (-not $status.Exists) {
        Write-Status "Task does not exist" "ERROR"
        return
    }
    try {
        Stop-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
        Disable-ScheduledTask -TaskName $script:TaskName -ErrorAction Stop | Out-Null
        Write-Status "Backup service stopped" "SUCCESS"
    }
    catch {
        Write-Status "Error: $($_)" "ERROR"
    }
}

# STATUS DISPLAY
function Show-TaskStatus {
    Clear-Screen
    Write-Header "SERVICE STATUS"
    $status = Get-TaskStatus
    
    if ($status.Exists) {
        if ($status.Enabled) {
            Write-Host "Status: RUNNING" -ForegroundColor Green
        }
        else {
            Write-Host "Status: STOPPED" -ForegroundColor Red
        }
        Write-Host "State: $($status.State)" -ForegroundColor Green
    }
    else {
        Write-Host "Status: NOT CONFIGURED" -ForegroundColor Yellow
    }
    
    if (Test-Path $script:LogFile) {
        Write-Host "`nLast Log Entries:" -ForegroundColor Green
        Get-Content $script:LogFile -Tail 5 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    
    Pause-Screen
}

# EDIT CONFIG
function Invoke-EditConfig {
    param($Config)
    
    if (-not $Config) {
        Write-Status "No configuration found" "ERROR"
        Pause-Screen
        return
    }
    
    Clear-Screen
    Write-Header "EDIT CONFIGURATION"
    Write-Host "[1] Source Path" -ForegroundColor Green
    Write-Host "[2] Destination Path" -ForegroundColor Green
    Write-Host "[3] Retention Days" -ForegroundColor Green
    Write-Host "[4] Back to Menu" -ForegroundColor Green
    Write-Host ""
    
    $choice = Write-Input "Select"
    
    switch ($choice) {
        "1" {
            do {
                $source = Write-Input "New Source Path"
                if (-not (Test-Path $source -PathType Container)) {
                    Write-Status "Invalid path" "ERROR"
                    $source = $null
                }
            } while (-not $source)
            $Config.SourcePath = $source
            Save-Config $Config
            Write-Status "Source path updated" "SUCCESS"
        }
        "2" {
            $dest = Write-Input "New Destination Path"
            if (-not (Test-Path $dest)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
            $Config.DestinationPath = $dest
            Save-Config $Config
            Write-Status "Destination path updated" "SUCCESS"
        }
        "3" {
            do {
                $days = Write-Input "New Retention Days (0-365)"
                $days = [int]$days
                if ($days -lt 0 -or $days -gt 365) {
                    Write-Status "Invalid" "ERROR"
                    $days = -1
                }
            } while ($days -lt 0)
            $Config.DaysToKeep = $days
            Save-Config $Config
            Write-Status "Retention days updated" "SUCCESS"
        }
    }
    
    Pause-Screen
}

# MAIN MENU
function Show-MainMenu {
    param($Config)
    
    $status = Get-TaskStatus
    
    Clear-Screen
    Write-Header "BACKUP MANAGER"
    
    Write-Host "Service: " -ForegroundColor Green -NoNewline
    if ($status.Exists -and $status.Enabled) {
        Write-Host "RUNNING" -ForegroundColor Green
    }
    elseif ($status.Exists) {
        Write-Host "STOPPED" -ForegroundColor Red
    }
    else {
        Write-Host "NOT CONFIGURED" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Setup and Config:" -ForegroundColor Green
    Write-Host "  [1] Initial Setup" -ForegroundColor Cyan
    Write-Host "  [2] View Configuration" -ForegroundColor Cyan
    Write-Host "  [3] Edit Configuration" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Service Management:" -ForegroundColor Green
    Write-Host "  [4] Create/Update Task" -ForegroundColor Cyan
    Write-Host "  [5] Start Service" -ForegroundColor Cyan
    Write-Host "  [6] Stop Service" -ForegroundColor Cyan
    Write-Host "  [7] Delete Task" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Status:" -ForegroundColor Green
    Write-Host "  [8] View Service Status" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Write-Input "Select option"
    return $choice
}

# MAIN LOOP
function Main {
    Ensure-Administrator
    $host.ui.RawUI.BackgroundColor = "Black"
    $host.ui.RawUI.ForegroundColor = "Green"
    Clear-Screen
    
    while ($true) {
        $config = Load-Config
        $choice = Show-MainMenu $config
        
        switch ($choice) {
            "1" { $config = Invoke-Setup }
            "2" { Show-Config $config }
            "3" { Invoke-EditConfig $config }
            "4" { Invoke-CreateTask }
            "5" { Invoke-StartTask; Pause-Screen }
            "6" { Invoke-StopTask; Pause-Screen }
            "7" { Invoke-DeleteTask }
            "8" { Show-TaskStatus }
            "0" { Clear-Screen; Write-Status "Exiting..." "INFO"; Start-Sleep -Milliseconds 500; exit 0 }
            default { Write-Status "Invalid option" "ERROR"; Start-Sleep -Milliseconds 500 }
        }
    }
}

Main
