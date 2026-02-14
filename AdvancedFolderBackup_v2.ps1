#Requires -Version 5.1
<#
.SYNOPSIS
    Advanced Real-Time Folder Backup Tool with Cross-Computer Compatibility

.DESCRIPTION
    A self-configuring PowerShell script that provides real-time folder backup with:
    - Interactive setup and configuration
    - Automatic Task Scheduler integration
    - Real-time file monitoring with FileSystemWatcher
    - Intelligent archiving and retention management
    - File locking detection and handling
    - Full cross-computer compatibility

.PARAMETER Mode
    Operation mode: 'Setup' for interactive configuration, 'Background' for scheduled operation, or 'Auto' (default)

.PARAMETER ConfigPath
    Optional: Path to configuration file. If not specified, looks for BackupConfig.json in script directory.
    Supports environment variables like %TEMP%, %USERPROFILE%, %APPDATA%

.PARAMETER SourcePath
    Optional: Override source path from command line (for automation)

.PARAMETER DestinationPath
    Optional: Override destination path from command line (for automation)

.PARAMETER DaysToKeep
    Optional: Override retention days from command line (1-365)

.EXAMPLE
    .\AdvancedFolderBackup.ps1 -Mode Setup
    Run interactive setup

.EXAMPLE
    .\AdvancedFolderBackup.ps1 -Mode Background -ConfigPath "C:\Config\BackupConfig.json"
    Run in background mode with custom config file location

.EXAMPLE
    .\AdvancedFolderBackup.ps1 -Mode Setup -SourcePath "D:\Documents" -DestinationPath "E:\Backup\Documents" -DaysToKeep 30
    Setup with predefined parameters

.AUTHOR
    Created for Advanced Backup Management

.VERSION
    2.0 - Enhanced with cross-computer compatibility
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Setup", "Background", "Auto")]
    [string]$Mode = "Auto",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = $null,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$DaysToKeep = $null
)

# ============================================================================
# GLOBAL CONFIGURATION - DYNAMIC AND CROSS-COMPUTER COMPATIBLE
# ============================================================================

$script:ScriptPath = $MyInvocation.MyCommand.Path
$script:ScriptDirectory = Split-Path -Parent $script:ScriptPath
$script:TaskName = "AdvancedFolderBackup"

# Function to expand environment variables in paths
function Expand-EnvironmentPath {
    param([string]$Path)
    
    if (-not $Path) {
        return $null
    }
    
    # Replace common environment variables
    $Path = $Path -replace '%TEMP%', $env:TEMP
    $Path = $Path -replace '%USERPROFILE%', $env:USERPROFILE
    $Path = $Path -replace '%APPDATA%', $env:APPDATA
    $Path = $Path -replace '%PROGRAMDATA%', $env:PROGRAMDATA
    $Path = $Path -replace '%COMPUTERNAME%', $env:COMPUTERNAME
    $Path = $Path -replace '%USERNAME%', $env:USERNAME
    
    # Support both \ and / as path separators
    $Path = $Path -replace '/', '\'
    
    return [System.Environment]::ExpandEnvironmentVariables($Path)
}

# Determine configuration file path with dynamic fallbacks
$script:ConfigFile = $ConfigPath
if (-not $script:ConfigFile) {
    # Try script directory first
    $script:ConfigFile = Join-Path $script:ScriptDirectory "BackupConfig.json"
    
    # If not found, try AppData
    if (-not (Test-Path $script:ConfigFile)) {
        $appDataFolder = Join-Path $env:APPDATA "AdvancedFolderBackup"
        $appDataConfig = Join-Path $appDataFolder "BackupConfig.json"
        if (Test-Path $appDataConfig) {
            $script:ConfigFile = $appDataConfig
        }
    }
}

$script:ConfigFile = Expand-EnvironmentPath $script:ConfigFile

# Log file in same directory as config
$script:LogFile = $null

# Configuration Class - ENHANCED
class BackupConfig {
    [string]$SourcePath
    [string]$DestinationPath
    [string]$ArchivePath
    [int]$DaysToKeep
    [datetime]$LastBackup
    [string]$Version = "2.0"
    [string]$ComputerName = ""
    [string]$CreatedDateTime = ""
    [string]$OSVersion = ""
    [bool]$UseRelativePaths = $false
    
    [void] ExpandPaths() {
        $this.SourcePath = Expand-EnvironmentPath $this.SourcePath
        $this.DestinationPath = Expand-EnvironmentPath $this.DestinationPath
        if ($this.ArchivePath) {
            $this.ArchivePath = Expand-EnvironmentPath $this.ArchivePath
        }
    }
}

# ============================================================================
# LOGGING FUNCTION
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        [switch]$Flush
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "INFO" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
        }
    )
    
    # Initialize log file and buffer if not set
    if (-not $script:LogFile) {
        $script:LogFile = Join-Path (Split-Path -Parent $script:ConfigFile) "BackupLog.txt"
        $script:LogBuffer = @()
        $script:LogBufferSize = 50
    }
    
    # Buffer log entries to reduce disk I/O (write in batches)
    $script:LogBuffer += $logEntry
    
    # Auto-flush for WARN/ERROR, or if buffer reaches threshold
    $shouldFlush = $Flush -or ($Level -in @("WARN", "ERROR")) -or ($script:LogBuffer.Count -ge $script:LogBufferSize)
    
    if ($shouldFlush) {
        if ($script:LogBuffer.Count -gt 0) {
            $script:LogBuffer | Add-Content -Path $script:LogFile -ErrorAction SilentlyContinue
            $script:LogBuffer = @()
        }
    }
}

# ============================================================================
# SYSTEM INFORMATION FUNCTIONS
# ============================================================================

function Flush-LogBuffer {
    if ($script:LogBuffer -and $script:LogBuffer.Count -gt 0) {
        $script:LogBuffer | Add-Content -Path $script:LogFile -ErrorAction SilentlyContinue
        $script:LogBuffer = @()
    }
}

function Get-SystemInfo {
    return @{
        ComputerName = $env:COMPUTERNAME
        Username = $env:USERNAME
        OSVersion = [System.Environment]::OSVersion.VersionString
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        DotNetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
        Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    }
}

function Test-PathAccessibility {
    param([string]$Path)
    
    try {
        $null = Test-Path $Path
        $null = [System.IO.Path]::GetFullPath($Path)
        return $true
    }
    catch {
        Write-Log "Path accessibility test failed for: $Path - $($_.Exception.Message)" "WARN"
        return $false
    }
}

# ============================================================================
# ADMINISTRATOR PRIVILEGES
# ============================================================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-AsAdministrator {
    if (-not (Test-Administrator)) {
        Write-Log "Administrator privileges required. Restarting script as Administrator..." "WARN"
        
        $arguments = "-ExecutionPolicy Bypass -File `"$($script:ScriptPath)`""
        $arguments += " -ConfigPath `"$($script:ConfigFile)`""
        if ($Mode -ne "Auto") {
            $arguments += " -Mode $Mode"
        }
        if ($SourcePath) {
            $arguments += " -SourcePath `"$SourcePath`""
        }
        if ($DestinationPath) {
            $arguments += " -DestinationPath `"$DestinationPath`""
        }
        if ($DaysToKeep) {
            $arguments += " -DaysToKeep $DaysToKeep"
        }
        
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
        exit
    }
}

# ============================================================================
# CONFIGURATION MANAGEMENT - CROSS-COMPUTER COMPATIBLE
# ============================================================================

function Get-BackupConfig {
    if (Test-Path $script:ConfigFile) {
        try {
            $configJson = Get-Content $script:ConfigFile -Raw | ConvertFrom-Json
            $config = New-Object BackupConfig
            $config.SourcePath = $configJson.SourcePath
            $config.DestinationPath = $configJson.DestinationPath
            $config.ArchivePath = $configJson.ArchivePath
            $config.DaysToKeep = $configJson.DaysToKeep
            $config.LastBackup = [datetime]$configJson.LastBackup
            $config.Version = $configJson.Version
            $config.ComputerName = $configJson.ComputerName
            $config.OSVersion = $configJson.OSVersion
            $config.UseRelativePaths = $configJson.UseRelativePaths
            
            # Expand environment variables in paths
            $config.ExpandPaths()
            
            Write-Log "Configuration loaded successfully from: $script:ConfigFile"
            Write-Log "Original computer: $($config.ComputerName) | Current computer: $env:COMPUTERNAME"
            return $config
        }
        catch {
            Write-Log "Error loading configuration: $($_.Exception.Message)" "ERROR"
            return $null
        }
    }
    else {
        Write-Log "Configuration file not found at: $script:ConfigFile" "WARN"
        return $null
    }
}

function Set-BackupConfig {
    param([BackupConfig]$Config)
    
    try {
        # Ensure config directory exists
        $configDir = Split-Path -Parent $script:ConfigFile
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Store current system information
        $Config.ComputerName = $env:COMPUTERNAME
        $Config.CreatedDateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $sysInfo = Get-SystemInfo
        $Config.OSVersion = $sysInfo.OSVersion
        
        $Config | ConvertTo-Json -Depth 2 | Out-File $script:ConfigFile -Encoding UTF8
        Write-Log "Configuration saved successfully to: $script:ConfigFile"
        return $true
    }
    catch {
        Write-Log "Error saving configuration: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================================
# INTERACTIVE SETUP MODE - CROSS-COMPUTER COMPATIBLE
# ============================================================================

function Start-SetupMode {
    Write-Host "`n=== Advanced Folder Backup Tool - Setup Mode ===" -ForegroundColor Cyan
    Write-Host "Version 2.0 - Cross-Computer Compatible`n" -ForegroundColor Gray
    
    # Display system info
    $sysInfo = Get-SystemInfo
    Write-Host "System Information:" -ForegroundColor Yellow
    Write-Host "  Computer: $($sysInfo.ComputerName)"
    Write-Host "  OS: $($sysInfo.OSVersion)"
    Write-Host "  Architecture: $($sysInfo.Architecture)`n"
    
    $config = New-Object BackupConfig
    
    # Get Source Path
    do {
        if ($SourcePath) {
            $sourcePath = $SourcePath
            Write-Host "Source path (from parameter): $sourcePath"
            $SourcePath = $null  # Clear for next iteration
        }
        else {
            Write-Host "Enter the source folder path to monitor"
            Write-Host "(Supports: local paths, UNC paths \\server\share, environment variables like %USERPROFILE%)"
            $sourcePath = Read-Host "Source Path"
            $sourcePath = Expand-EnvironmentPath $sourcePath
        }
        
        if (-not (Test-Path $sourcePath -PathType Container)) {
            Write-Host "Invalid path or folder does not exist. Please try again." -ForegroundColor Red
            $sourcePath = $null
        }
    } while (-not $sourcePath)
    $config.SourcePath = $sourcePath
    
    # Get Destination Path
    do {
        if ($DestinationPath) {
            $destPath = $DestinationPath
            Write-Host "Destination path (from parameter): $destPath"
            $DestinationPath = $null  # Clear for next iteration
        }
        else {
            Write-Host "`nEnter the destination folder path for backups"
            Write-Host "(Supports: local paths, UNC paths, environment variables)"
            $destPath = Read-Host "Destination Path"
            $destPath = Expand-EnvironmentPath $destPath
        }
        
        $parentPath = Split-Path -Parent $destPath
        if ($parentPath -and -not (Test-Path $parentPath)) {
            Write-Host "Parent directory does not exist. Please choose a valid location." -ForegroundColor Red
            $destPath = $null
        }
    } while (-not $destPath)
    $config.DestinationPath = $destPath
    
    # Create destination if it doesn't exist
    if (-not (Test-Path $config.DestinationPath)) {
        try {
            New-Item -ItemType Directory -Path $config.DestinationPath -Force | Out-Null
            Write-Log "Created destination directory: $($config.DestinationPath)"
        }
        catch {
            Write-Host "Cannot create destination directory: $($_.Exception.Message)" -ForegroundColor Red
            return $null
        }
    }
    
    # Set Archive Path
    $config.ArchivePath = Join-Path (Split-Path -Parent $config.DestinationPath) "BackupArchives"
    if (-not (Test-Path $config.ArchivePath)) {
        try {
            New-Item -ItemType Directory -Path $config.ArchivePath -Force | Out-Null
            Write-Log "Created archive directory: $($config.ArchivePath)"
        }
        catch {
            Write-Host "Cannot create archive directory: $($_.Exception.Message)" -ForegroundColor Red
            return $null
        }
    }
    
    # Get Retention Days
    do {
        try {
            if ($DaysToKeep -gt 0) {
                $days = $DaysToKeep
                Write-Host "Retention days (from parameter): $days"
                $DaysToKeep = 0  # Clear for next iteration
            }
            else {
                $daysInput = Read-Host "How many days of backup history do you want to keep? (1-365)"
                $days = [int]$daysInput
            }
            
            if ($days -lt 1 -or $days -gt 365) {
                Write-Host "Please enter a number between 1 and 365." -ForegroundColor Red
                $days = 0
            }
        }
        catch {
            Write-Host "Please enter a valid number." -ForegroundColor Red
            $days = 0
        }
    } while ($days -eq 0)
    $config.DaysToKeep = $days
    $config.LastBackup = Get-Date
    $config.UseRelativePaths = $false
    
    # Save Configuration
    if (Set-BackupConfig -Config $config) {
        Write-Host "`nSetup completed successfully!" -ForegroundColor Green
        Write-Host "Configuration saved to: $script:ConfigFile" -ForegroundColor Gray
        Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
        Write-Host "  Source: $($config.SourcePath)"
        Write-Host "  Destination: $($config.DestinationPath)"
        Write-Host "  Archive: $($config.ArchivePath)"
        Write-Host "  Retention: $($config.DaysToKeep) days"
        
        # Setup Task Scheduler
        $setupTask = Read-Host "`nDo you want to set up automatic scheduling? (y/n)"
        if ($setupTask -eq 'y' -or $setupTask -eq 'Y') {
            New-ScheduledTask
        }
        
        return $config
    }
    else {
        Write-Host "Setup failed. Please try again." -ForegroundColor Red
        return $null
    }
}

# ============================================================================
# TASK SCHEDULER MANAGEMENT - CROSS-COMPUTER COMPATIBLE
# ============================================================================

function Test-ScheduledTask {
    try {
        $task = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
        return $null -ne $task
    }
    catch {
        return $false
    }
}

function New-ScheduledTask {
    if (-not (Test-Administrator)) {
        Write-Log "Administrator privileges required to create scheduled task" "ERROR"
        Start-AsAdministrator
        return
    }
    
    if (Test-ScheduledTask) {
        Write-Log "Scheduled task '$script:TaskName' already exists"
        return $true
    }
    
    try {
        # Create task action - use quoted path to handle spaces in path
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script:ScriptPath`" -ConfigPath `"$script:ConfigFile`" -Mode Background"
        
        # Create task triggers (at startup and user logon)
        $trigger1 = New-ScheduledTaskTrigger -AtStartup
        $trigger2 = New-ScheduledTaskTrigger -AtLogOn
        $triggers = @($trigger1, $trigger2)
        
        # Create task principal - use SYSTEM for elevated privileges
        # Alternative for domain scenarios: -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
        
        # Register the task
        Register-ScheduledTask -TaskName $script:TaskName -Action $action -Trigger $triggers -Principal $principal -Settings $settings -Description "Advanced Folder Backup Tool - Real-time monitoring and archiving" -Force
        
        Write-Log "Scheduled task '$script:TaskName' created successfully"
        Write-Host "Task scheduled successfully!" -ForegroundColor Green
        Write-Host "The backup will run automatically at:" -ForegroundColor Yellow
        Write-Host "  • System Startup"
        Write-Host "  • User Logon"
        return $true
    }
    catch {
        Write-Log "Error creating scheduled task: $($_.Exception.Message)" "ERROR"
        Write-Host "Note: If Task Scheduler creation fails on domain-joined computers, you may need to run with domain admin rights." -ForegroundColor Yellow
        return $false
    }
}

# ============================================================================
# SYSTEM TRAY ICON
# ============================================================================

function New-NotifyIcon {
    param([BackupConfig]$Config)
    
    try {
        # Load required assemblies
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        
        # Create NotifyIcon
        $script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $script:NotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        $script:NotifyIcon.Text = "Advanced Folder Backup - Running`nSource: $(Split-Path -Leaf $Config.SourcePath)`nStatus: Active"
        $script:NotifyIcon.Visible = $true
        
        # Create context menu
        $script:ContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
        
        # Status menu item (read-only)
        $statusItem = $script:ContextMenu.Items.Add("Status: Monitoring Files")
        $statusItem.Enabled = $false
        
        # Show folder menu item
        $showSourceItem = $script:ContextMenu.Items.Add("Open Source Folder")
        $showSourceItem.add_Click({
            try {
                Invoke-Item $Config.SourcePath
            } catch {
                Write-Log "Could not open source folder: $($_.Exception.Message)" "WARN"
            }
        })
        
        # Show backup folder menu item
        $showBackupItem = $script:ContextMenu.Items.Add("Open Backup Folder")
        $showBackupItem.add_Click({
            try {
                Invoke-Item $Config.DestinationPath
            } catch {
                Write-Log "Could not open backup folder: $($_.Exception.Message)" "WARN"
            }
        })
        
        # Separator
        $script:ContextMenu.Items.Add("-") | Out-Null
        
        # Exit menu item
        $exitItem = $script:ContextMenu.Items.Add("Exit Backup Tool")
        $exitItem.add_Click({
            Write-Log "User stopped backup tool from system tray"
            Flush-LogBuffer
            $script:NotifyIcon.Visible = $false
            $script:NotifyIcon.Dispose()
            exit 0
        })
        
        $script:NotifyIcon.ContextMenuStrip = $script:ContextMenu
        
        Write-Log "System tray icon created successfully"
        return $true
    }
    catch {
        Write-Log "Error creating system tray icon: $($_.Exception.Message)" "WARN"
        return $false
    }
}

function Update-NotifyIcon {
    param(
        [string]$Status = "Monitoring",
        [string]$FilesBackedUp = "0"
    )
    
    if ($script:NotifyIcon) {
        $tooltip = "Advanced Folder Backup`nStatus: $Status`nFiles Backed Up: $FilesBackedUp`nClick to view options"
        if ($tooltip.Length -gt 63) {
            $tooltip = $tooltip.Substring(0, 60) + "..."
        }
        $script:NotifyIcon.Text = $tooltip
    }
}

function Cleanup-NotifyIcon {
    if ($script:NotifyIcon) {
        $script:NotifyIcon.Visible = $false
        $script:NotifyIcon.Dispose()
        Write-Log "System tray icon cleaned up"
    }
}

# ============================================================================
# FILE HANDLING
# ============================================================================
# CLOUD DRIVE MANAGEMENT
# ============================================================================

function Detect-CloudDrive {
    param([string]$FilePath)
    
    $cloudPatterns = @(
        'OneDrive',
        'Google Drive',
        'GoogleDrive',
        'Dropbox',
        'iCloudDrive'
    )
    
    foreach ($pattern in $cloudPatterns) {
        if ($FilePath -like "*$pattern*") {
            return $pattern
        }
    }
    return $null
}

function Free-CloudDriveSpace {
    param(
        [string]$FilePath,
        [string]$CloudProvider
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "Cloud free-up attempted on non-existent path: $FilePath" "WARN"
        return $false
    }
    
    try {
        switch ($CloudProvider) {
            'OneDrive' {
                # Mark as online-only (requires Windows 10/11 with modern OneDrive)
                attrib +U "$FilePath" 2>$null
                if ($?) {
                    Write-Log "OneDrive: Marked as online-only (free up space): $FilePath" "INFO"
                    return $true
                }
                else {
                    Write-Log "OneDrive: Could not mark online-only (may require newer Windows): $FilePath" "WARN"
                    return $false
                }
            }
            'Google Drive' {
                # Google Drive for desktop uses selective sync; direct file control limited
                Write-Log "Google Drive: File location detected but file control requires Drive app settings" "INFO"
                return $false
            }
            'Dropbox' {
                # Dropbox selective sync - would need Dropbox API or settings
                Write-Log "Dropbox: File location detected but requires Dropbox app settings for selective sync" "INFO"
                return $false
            }
            default {
                Write-Log "Unknown cloud provider: $CloudProvider" "WARN"
                return $false
            }
        }
    }
    catch {
        Write-Log "Error freeing cloud drive space for $FilePath : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================================

function Test-FileReady {
    param([string]$FilePath, [int]$MaxRetries = 10, [int]$DelayMs = 500)
    
    # For Office files, use shorter delays to catch unlock quickly
    if ($FilePath -match '\.(xlsx|xlsm|docx|docm|pptx)$') {
        $DelayMs = 200
        $MaxRetries = 15
    }
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $fileStream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
            $fileStream.Close()
            $fileStream.Dispose()
            if ($i -gt 1) {
                Write-Log "File ready after $i attempts: $FilePath"
            }
            return $true
        }
        catch [System.IO.IOException] {
            if ($i -eq $MaxRetries) {
                Write-Log "File locked after $MaxRetries attempts: $FilePath - backing up anyway" "WARN"
                return $true  # Return true anyway to attempt backup
            }
            Start-Sleep -Milliseconds $DelayMs
        }
        catch {
            Write-Log "Unexpected error checking file readiness: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    return $false
}

function Copy-FileWithRetry {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$MaxRetries = 3
    )
    
    # Ensure destination directory exists
    $destDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $destDir)) {
        try {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        catch {
            Write-Log "Cannot create destination directory: $destDir - $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            if (Test-FileReady -FilePath $SourcePath) {
                # Use robocopy for faster, multi-threaded transfer with resume capability
                # /Z: Resumable mode (for interrupted transfers)
                # /R:3: Retry 3 times on failed files
                # /W:2: Wait 2 seconds between retries
                # /NJH /NJS: No job header/summary (cleaner logging)
                $robocopyArgs = @(
                    '"' + (Split-Path -Parent $SourcePath) + '"',
                    '"' + $destDir + '"',
                    '"' + (Split-Item -Leaf $SourcePath) + '"',
                    '/Z',
                    '/R:3',
                    '/W:2',
                    '/NJH',
                    '/NJS'
                )
                
                $output = & robocopy $robocopyArgs 2>&1
                
                # robocopy exit codes: 0,1 = success, 16 = failure
                if ($LASTEXITCODE -le 1 -or $LASTEXITCODE -eq 2) {
                    Write-Log "File copied via robocopy: $SourcePath" "INFO"
                    
                    # Check if backup is in cloud drive and free up space
                    $cloudProvider = Detect-CloudDrive -FilePath $DestinationPath
                    if ($cloudProvider) {
                        Free-CloudDriveSpace -FilePath $DestinationPath -CloudProvider $cloudProvider
                    }
                    
                    # Update tray icon status
                    Update-NotifyIcon -Status "Backing up files" -FilesBackedUp "..."
                    
                    return $true
                }
                else {
                    Write-Log "Robocopy failed (attempt $i, exit code $LASTEXITCODE): $SourcePath" "WARN"
                }
            }
            else {
                Write-Log "File not ready for copying (attempt $i): $SourcePath" "WARN"
            }
        }
        catch {
            Write-Log "Copy failed (attempt $i): $($_.Exception.Message)" "ERROR"
            if ($i -lt $MaxRetries) {
                Start-Sleep -Seconds 2
            }
        }
    }
    return $false
}

# ============================================================================
# ARCHIVE MANAGEMENT
# ============================================================================

function Invoke-ArchiveManagement {
    param([BackupConfig]$Config)
    
    Write-Log "Starting archive management process"
    
    try {
        # Create today's archive
        $todayDate = Get-Date -Format "yyyy-MM-dd"
        $archiveFileName = "Backup_$todayDate.zip"
        $archivePath = Join-Path $Config.ArchivePath $archiveFileName
        
        # Check if archive already exists today
        $existingArchive = $null
        if (Test-Path $archivePath) {
            $existingArchive = Get-Item $archivePath
        }
        
        # Create temporary archive
        $tempArchivePath = Join-Path $Config.ArchivePath "temp_$archiveFileName"
        
        # Compress current backup
        Write-Log "Creating archive: $archiveFileName"
        $backupItems = Get-ChildItem $Config.DestinationPath -ErrorAction SilentlyContinue
        
        if ($backupItems) {
            Compress-Archive -Path "$($Config.DestinationPath)\*" -DestinationPath $tempArchivePath -CompressionLevel Optimal -Force -ErrorAction SilentlyContinue
            
            if (Test-Path $tempArchivePath) {
                $newArchive = Get-Item $tempArchivePath
                
                # Compare with existing archive and keep larger one
                if ($existingArchive) {
                    if ($newArchive.Length -gt $existingArchive.Length) {
                        Move-Item -Path $tempArchivePath -Destination $archivePath -Force
                        Write-Log "Replaced existing archive with larger version ($($newArchive.Length) bytes vs $($existingArchive.Length) bytes)"
                    }
                    else {
                        Remove-Item -Path $tempArchivePath -Force
                        Write-Log "Kept existing archive (larger: $($existingArchive.Length) bytes vs $($newArchive.Length) bytes)"
                    }
                }
                else {
                    Move-Item -Path $tempArchivePath -Destination $archivePath -Force
                    Write-Log "Created new archive: $archiveFileName ($($newArchive.Length) bytes)"
                    
                    # Free up cloud drive space if archive is in cloud
                    $cloudProvider = Detect-CloudDrive -FilePath $archivePath
                    if ($cloudProvider) {
                        Free-CloudDriveSpace -FilePath $archivePath -CloudProvider $cloudProvider
                    }
                }
            }
        }
        else {
            Write-Log "No files to archive in destination folder"
        }
        
        # Clean up old archives
        $cutoffDate = (Get-Date).AddDays(-$Config.DaysToKeep)
        $oldArchives = Get-ChildItem -Path $Config.ArchivePath -Filter "Backup_*.zip" -ErrorAction SilentlyContinue | Where-Object {
            $_.CreationTime -lt $cutoffDate
        }
        
        foreach ($oldArchive in $oldArchives) {
            try {
                Remove-Item -Path $oldArchive.FullName -Force
                Write-Log "Deleted old archive: $($oldArchive.Name) (created: $($oldArchive.CreationTime))"
            }
            catch {
                Write-Log "Could not delete archive $($oldArchive.Name): $($_.Exception.Message)" "WARN"
            }
        }
        
        Write-Log "Archive management completed successfully"
        return $true
    }
    catch {
        Write-Log "Error during archive management: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================================
# FILE SYSTEM WATCHER
# ============================================================================

function Start-FileSystemWatcher {
    param([BackupConfig]$Config)
    
    Write-Log "Starting real-time file system monitoring on: $($Config.SourcePath)"
    Write-Host "Monitoring active - Press Ctrl+C to stop" -ForegroundColor Green
    
    try {
        # Create FileSystemWatcher
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $Config.SourcePath
        $watcher.IncludeSubdirectories = $true
        $watcher.EnableRaisingEvents = $true
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName -bor [System.IO.NotifyFilters]::LastWrite
        
        # Define event handler for individual file operations
        $action = {
            param($source, $e)
            
            $sourcePath = $e.FullPath
            $relativePath = $sourcePath.Substring($Config.SourcePath.Length + 1)
            $destinationPath = Join-Path $Config.DestinationPath $relativePath
            
            # Skip temporary/lock files
            if ($sourcePath -match '\.(tmp|temp|lock)$' -or $sourcePath -match '~\$') {
                return
            }
            
            # Skip system files
            if ($sourcePath -like '*desktop.ini' -or $sourcePath -like '*.lnk') {
                return
            }
            
            Write-Log "File event: $($e.ChangeType) -> $relativePath"
            
            # Handle different event types
            switch ($e.ChangeType) {
                'Created' {
                    if (Test-Path $sourcePath -PathType Leaf) {
                        Start-Sleep -Milliseconds 500
                        
                        # Ensure destination directory structure exists
                        $destDir = Split-Path -Parent $destinationPath
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                            Write-Log "Created folder structure: $destDir"
                        }
                        
                        # Copy the new file with higher retry count for locked files
                        Write-Log "New file detected: $relativePath - Attempting backup..."
                        Copy-FileWithRetry -SourcePath $sourcePath -DestinationPath $destinationPath -MaxRetries 5
                        Write-Log "Backed up new file: $relativePath"
                    }
                    elseif (Test-Path $sourcePath -PathType Container) {
                        # Create folder in destination
                        if (-not (Test-Path $destinationPath)) {
                            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                            Write-Log "Created new folder: $relativePath"
                        }
                    }
                }
                'Changed' {
                    if (Test-Path $sourcePath -PathType Leaf) {
                        Start-Sleep -Milliseconds 800
                        
                        # Ensure destination directory exists
                        $destDir = Split-Path -Parent $destinationPath
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        
                        Write-Log "File change detected: $relativePath - Attempting backup..."
                        Copy-FileWithRetry -SourcePath $sourcePath -DestinationPath $destinationPath -MaxRetries 8
                        Write-Log "Updated/backed up modified file: $relativePath"
                    }
                }
                'Deleted' {
                    if (Test-Path $destinationPath) {
                        Remove-Item -Path $destinationPath -Force -ErrorAction SilentlyContinue
                        Write-Log "Removed deleted file from backup: $relativePath"
                    }
                }
                'Renamed' {
                    $oldDestPath = Join-Path $Config.DestinationPath ($e.OldName)
                    if (Test-Path $oldDestPath) {
                        $newDestDir = Split-Path -Parent $destinationPath
                        if (-not (Test-Path $newDestDir)) {
                            New-Item -ItemType Directory -Path $newDestDir -Force | Out-Null
                        }
                        Move-Item -Path $oldDestPath -Destination $destinationPath -Force -ErrorAction SilentlyContinue
                        Write-Log "Renamed in backup: $($e.OldName) -> $relativePath"
                    }
                }
            }
        }
        
        # Register event handlers
        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier "FileCreated"
        Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -SourceIdentifier "FileChanged"
        Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -SourceIdentifier "FileDeleted"
        Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -SourceIdentifier "FileRenamed"
        
        Write-Log "File system watcher started successfully"
        
        # Keep track of file hashes to detect changes
        $fileHashes = @{}
        
        # Keep the script running with periodic backup verification
        try {
            while ($true) {
                Start-Sleep -Seconds 10
                
                # Flush log buffer every 10 seconds to retain recent logs on disk
                Flush-LogBuffer
                
                # Periodic file scanner - catches changes that FileSystemWatcher might miss
                # This is especially important for OneDrive folders
                try {
                    $sourceFiles = Get-ChildItem $Config.SourcePath -File -Recurse -ErrorAction SilentlyContinue
                    
                    foreach ($file in $sourceFiles) {
                        # Skip temp and lock files
                        if ($file.Name -match '\.(tmp|temp|lock)$' -or $file.Name -match '~\$') {
                            continue
                        }
                        
                        # Get relative path
                        $relativePath = $file.FullName.Substring($Config.SourcePath.Length + 1)
                        $destPath = Join-Path $Config.DestinationPath $relativePath
                        
                        # Check if file needs backup
                        $needsBackup = $false
                        
                        if (-not (Test-Path $destPath)) {
                            $needsBackup = $true  # New file
                        }
                        else {
                            # Check if source is newer than destination
                            $destFile = Get-Item $destPath -ErrorAction SilentlyContinue
                            if ($destFile -and $file.LastWriteTime -gt $destFile.LastWriteTime) {
                                $needsBackup = $true  # File was modified
                            }
                        }
                        
                        if ($needsBackup) {
                            $destDir = Split-Path -Parent $destPath
                            if (-not (Test-Path $destDir)) {
                                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                            }
                            
                            Write-Log "Periodic scan detected change: $relativePath - Backing up..."
                            Copy-FileWithRetry -SourcePath $file.FullName -DestinationPath $destPath -MaxRetries 8
                        }
                    }
                }
                catch {
                    Write-Log "Error in periodic file scan: $($_.Exception.Message)" "WARN"
                }
            }
        }
        finally {
            Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue
            $watcher.Dispose()
            Write-Log "File system watcher stopped"
        }
    }
    catch {
        Write-Log "Error starting file system watcher: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================================
# BACKGROUND MODE
# ============================================================================

function Start-BackgroundMode {
    param([BackupConfig]$Config)
    
    Write-Log "=== Starting Background Mode ==="
    Write-Log "Computer: $env:COMPUTERNAME | User: $env:USERNAME"
    Write-Log "Source: $($Config.SourcePath)"
    Write-Log "Destination: $($Config.DestinationPath)"
    Write-Log "Archive: $($Config.ArchivePath)"
    Write-Log "Retention: $($Config.DaysToKeep) days"
    Write-Log "Backup Mode: Individual File Tracking (only modified/new files)"
    
    # Ensure destination folder exists
    if (-not (Test-Path $Config.DestinationPath)) {
        try {
            New-Item -ItemType Directory -Path $Config.DestinationPath -Force | Out-Null
            Write-Log "Created destination folder: $($Config.DestinationPath)"
        }
        catch {
            Write-Log "Error creating destination folder: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    Write-Log "Ready - waiting for file changes in source folder..."
    
    # Initialize Windows.Forms for system tray (message pump)
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    # Create system tray icon
    Write-Log "Creating system tray icon..."
    New-NotifyIcon -Config $Config
    
    # Setup cleanup on exit
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Cleanup-NotifyIcon
        Flush-LogBuffer
    }
    
    # Archive management
    Invoke-ArchiveManagement -Config $Config
    
    # Start real-time monitoring (individual file tracking)
    Start-FileSystemWatcher -Config $Config
}

# ============================================================================
# FIRST-RUN DETECTION
# ============================================================================

function Test-FirstRun {
    return -not (Test-Path $script:ConfigFile)
}

# ============================================================================
# SETTINGS & CONFIG MENU
# ============================================================================

function Update-BackupSourcePath {
    param([BackupConfig]$Config)
    
    Write-Host "`nCurrent Source: $($Config.SourcePath)" -ForegroundColor Yellow
    do {
        $sourcePath = Read-Host "Enter new source path (or press Enter to cancel)"
        
        if ([string]::IsNullOrWhiteSpace($sourcePath)) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return $null
        }
        
        $sourcePath = Expand-EnvironmentPath $sourcePath
        
        if (-not (Test-Path $sourcePath -PathType Container)) {
            Write-Host "Invalid path. Try again." -ForegroundColor Red
            $sourcePath = $null
        }
    } while (-not $sourcePath)
    
    $Config.SourcePath = $sourcePath
    if (Set-BackupConfig -Config $Config) {
        Write-Host "Source updated!  $($Config.SourcePath)" -ForegroundColor Green
        return $Config
    }
    return $null
}

function Update-BackupDestinationPath {
    param([BackupConfig]$Config)
    
    Write-Host "`nCurrent Destination: $($Config.DestinationPath)" -ForegroundColor Yellow
    do {
        $destPath = Read-Host "Enter new destination path (or press Enter to cancel)"
        
        if ([string]::IsNullOrWhiteSpace($destPath)) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return $null
        }
        
        $destPath = Expand-EnvironmentPath $destPath
        
        $parentPath = Split-Path -Parent $destPath
        if ($parentPath -and -not (Test-Path $parentPath)) {
            Write-Host "Parent directory doesn't exist. Try again." -ForegroundColor Red
            $destPath = $null
        }
    } while (-not $destPath)
    
    if (-not (Test-Path $destPath)) {
        try {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            Write-Host "Created directory." -ForegroundColor Green
        }
        catch {
            Write-Host "Cannot create directory." -ForegroundColor Red
            return $null
        }
    }
    
    $newArchivePath = Join-Path (Split-Path -Parent $destPath) "BackupArchives"
    if (-not (Test-Path $newArchivePath)) {
        New-Item -ItemType Directory -Path $newArchivePath -Force | Out-Null
    }
    
    $Config.DestinationPath = $destPath
    $Config.ArchivePath = $newArchivePath
    if (Set-BackupConfig -Config $Config) {
        Write-Host "Destination updated!  $($Config.DestinationPath)" -ForegroundColor Green
        return $Config
    }
    return $null
}

function Update-RetentionDays {
    param([BackupConfig]$Config)
    
    Write-Host "`nCurrent Retention: $($Config.DaysToKeep) days" -ForegroundColor Yellow
    do {
        try {
            $daysInput = Read-Host "Enter days (1-365) or press Enter to cancel"
            
            if ([string]::IsNullOrWhiteSpace($daysInput)) {
                Write-Host "Cancelled." -ForegroundColor Yellow
                return $null
            }
            
            $days = [int]$daysInput
            if ($days -lt 1 -or $days -gt 365) {
                Write-Host "Enter a number between 1 and 365." -ForegroundColor Red
                $days = 0
            }
        }
        catch {
            Write-Host "Invalid number." -ForegroundColor Red
            $days = 0
        }
    } while ($days -eq 0)
    
    $Config.DaysToKeep = $days
    if (Set-BackupConfig -Config $Config) {
        Write-Host "Retention updated!  $($Config.DaysToKeep) days" -ForegroundColor Green
        return $Config
    }
    return $null
}

function Show-SettingsMenu {
    param([BackupConfig]$Config)
    
    while ($true) {
        Write-Host "`n" -ForegroundColor Gray
        Write-Host "="*60 -ForegroundColor Cyan
        Write-Host "SETTINGS MENU" -ForegroundColor Cyan
        Write-Host "="*60 -ForegroundColor Cyan
        Write-Host "`nCurrent Configuration:" -ForegroundColor Yellow
        Write-Host "  Source:      $(Split-Path -Leaf $Config.SourcePath)" -ForegroundColor White
        Write-Host "  Destination: $(Split-Path -Leaf $Config.DestinationPath)" -ForegroundColor White
        Write-Host "  Retention:   $($Config.DaysToKeep) days" -ForegroundColor White
        Write-Host "`nOptions:" -ForegroundColor Yellow
        Write-Host "  (1) Change Source Folder" -ForegroundColor Cyan
        Write-Host "  (2) Change Destination Folder" -ForegroundColor Cyan
        Write-Host "  (3) Change Retention Days" -ForegroundColor Cyan
        Write-Host "  (4) Back to Main Menu" -ForegroundColor Cyan
        Write-Host "`n" -ForegroundColor Gray
        
        $choice = Read-Host "Select option (1-4)"
        
        switch ($choice) {
            "1" { $newConfig = Update-BackupSourcePath -Config $Config; if ($newConfig) { $Config = $newConfig } }
            "2" { $newConfig = Update-BackupDestinationPath -Config $Config; if ($newConfig) { $Config = $newConfig } }
            "3" { $newConfig = Update-RetentionDays -Config $Config; if ($newConfig) { $Config = $newConfig } }
            "4" { return $Config }
            default { Write-Host "Invalid option. Try again." -ForegroundColor Red }
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Write-Log "=== Advanced Folder Backup Tool Started ==="
    Write-Log "Version: 2.0 - Cross-Computer Compatible"
    Write-Log "Mode: $Mode"
    Write-Log "Script Path: $script:ScriptPath"
    Write-Log "Config Path: $script:ConfigFile"
    
    # Check if first run
    $isFirstRun = Test-FirstRun
    
    # Get configuration
    $config = Get-BackupConfig
    
    if ($isFirstRun -and $Mode -ne "Background") {
        # First-time setup
        Write-Log "First run detected - Running first-time setup"
        Start-AsAdministrator
        
        Write-Host "`n" -ForegroundColor Gray
        Write-Host "="*60 -ForegroundColor Green
        Write-Host "Welcome to Advanced Folder Backup Tool" -ForegroundColor Green
        Write-Host "="*60 -ForegroundColor Green
        Write-Host "Let's set up your backup configuration.`n" -ForegroundColor Gray
        
        $config = New-Object BackupConfig
        
        # Step 1: Source Path
        do {
            Write-Host "Step 1: Folder to Backup" -ForegroundColor Cyan
            $sourcePath = Read-Host "Enter source folder path"
            $sourcePath = Expand-EnvironmentPath $sourcePath
            
            if (-not (Test-Path $sourcePath -PathType Container)) {
                Write-Host "Invalid path. Try again." -ForegroundColor Red
                $sourcePath = $null
            }
        } while (-not $sourcePath)
        $config.SourcePath = $sourcePath
        
        # Step 2: Destination Path
        do {
            Write-Host "`nStep 2: Backup Destination" -ForegroundColor Cyan
            $destPath = Read-Host "Enter destination folder path"
            $destPath = Expand-EnvironmentPath $destPath
            
            $parentPath = Split-Path -Parent $destPath
            if ($parentPath -and -not (Test-Path $parentPath)) {
                Write-Host "Parent directory doesn't exist. Try again." -ForegroundColor Red
                $destPath = $null
            }
        } while (-not $destPath)
        $config.DestinationPath = $destPath
        
        # Create destination
        if (-not (Test-Path $config.DestinationPath)) {
            try {
                New-Item -ItemType Directory -Path $config.DestinationPath -Force | Out-Null
            }
            catch {
                Write-Host "Cannot create destination." -ForegroundColor Red
                exit 1
            }
        }
        
        # Archive path
        $config.ArchivePath = Join-Path (Split-Path -Parent $config.DestinationPath) "BackupArchives"
        if (-not (Test-Path $config.ArchivePath)) {
            New-Item -ItemType Directory -Path $config.ArchivePath -Force | Out-Null
        }
        
        # Step 3: Retention Days
        do {
            try {
                Write-Host "`nStep 3: Retention (days to keep)" -ForegroundColor Cyan
                $daysInput = Read-Host "Enter retention days (1-365)"
                $days = [int]$daysInput
                if ($days -lt 1 -or $days -gt 365) {
                    Write-Host "Enter a number between 1-365." -ForegroundColor Red
                    $days = 0
                }
            }
            catch {
                Write-Host "Invalid number." -ForegroundColor Red
                $days = 0
            }
        } while ($days -eq 0)
        $config.DaysToKeep = $days
        $config.LastBackup = Get-Date
        $config.UseRelativePaths = $false
        
        if (Set-BackupConfig -Config $config) {
            Write-Host "`n" -ForegroundColor Gray
            Write-Host "Setup complete!" -ForegroundColor Green
            Write-Host "  Source:      $($config.SourcePath)" -ForegroundColor Gray
            Write-Host "  Destination: $($config.DestinationPath)" -ForegroundColor Gray
            Write-Host "  Retention:   $($config.DaysToKeep) days" -ForegroundColor Gray
            Write-Log "First-time setup completed successfully"
        }
    }
    elseif ($Mode -eq "Setup" -or (-not $config)) {
        # Setup Mode
        Start-AsAdministrator
        $config = Start-SetupMode
        if (-not $config) {
            Write-Log "Setup failed or cancelled" "ERROR"
            exit 1
        }
    }
    elseif ($Mode -eq "Background" -or ($config -and (Test-ScheduledTask))) {
        # Background Mode
        if (-not $config) {
            Write-Log "Configuration not found. Please run setup first." "ERROR"
            exit 1
        }
        
        # Validate configuration
        if (-not (Test-Path $config.SourcePath)) {
            Write-Log "Source path not found: $($config.SourcePath)" "ERROR"
            exit 1
        }
        
        Start-BackgroundMode -Config $config
    }
    else {
        # Auto Mode - Check if scheduled task exists
        if (Test-ScheduledTask) {
            Write-Log "Scheduled task exists. Running in background mode."
            Start-BackgroundMode -Config $config
        }
        else {
            Write-Log "No scheduled task found. Running setup mode."
            Start-AsAdministrator
            $config = Start-SetupMode
            if ($config) {
                Write-Host "`nSetup complete. The backup service is now configured and will start automatically." -ForegroundColor Green
            }
        }
    }
    
    Write-Log "=== Advanced Folder Backup Tool Finished ==="
}

# Script Entry Point
try {
    Main
}
catch {
    Write-Log "Critical error in main execution: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}