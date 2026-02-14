# Test Script for Advanced Folder Backup Tool
# This script helps test the backup functionality

# Test Configuration
$TestSourcePath = "C:\Temp\BackupTest\Source"
$TestDestPath = "C:\Temp\BackupTest\Destination"

Write-Host "=== Advanced Folder Backup Tool - Test Script ===" -ForegroundColor Cyan
Write-Host "This script will create test folders and files to validate backup functionality.`n"

# Create test directories
Write-Host "Creating test directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $TestSourcePath -Force | Out-Null
New-Item -ItemType Directory -Path $TestDestPath -Force | Out-Null

# Create test files
Write-Host "Creating test files..." -ForegroundColor Yellow
$testFiles = @(
    "TestDocument1.txt",
    "TestDocument2.txt", 
    "TestSpreadsheet.csv",
    "TestPresentation.pptx"
)

foreach ($file in $testFiles) {
    $filePath = Join-Path $TestSourcePath $file
    "This is a test file: $file`nCreated: $(Get-Date)" | Out-File $filePath
    Write-Host "  Created: $file"
}

# Create a subfolder with files
$subfolderPath = Join-Path $TestSourcePath "SubFolder"
New-Item -ItemType Directory -Path $subfolderPath -Force | Out-Null
"Subfolder test content" | Out-File (Join-Path $subfolderPath "SubfolderFile.txt")

Write-Host "`nTest structure created successfully!" -ForegroundColor Green
Write-Host "Source Path: $TestSourcePath"
Write-Host "Destination Path: $TestDestPath"

Write-Host "`n=== Instructions for Testing ===" -ForegroundColor Cyan
Write-Host "1. Run the main backup script: .\AdvancedFolderBackup.ps1 -Mode Setup"
Write-Host "2. When prompted, use these paths:"
Write-Host "   Source: $TestSourcePath" -ForegroundColor White
Write-Host "   Destination: $TestDestPath" -ForegroundColor White
Write-Host "3. Set retention days (e.g., 7 for testing)"
Write-Host "4. After setup, test by modifying files in the source folder"
Write-Host "5. Check that files are automatically copied to destination"

Write-Host "`n=== Test Scenarios ===" -ForegroundColor Cyan
Write-Host "• Modify an existing file in source folder"
Write-Host "• Create a new file in source folder"  
Write-Host "• Delete a file from source folder"
Write-Host "• Create/modify files in the subfolder"
Write-Host "• Check that archives are created in BackupArchives folder"

Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
Read-Host

# Provide option to clean up
$cleanup = Read-Host "Do you want to clean up test files after testing? (y/n)"
if ($cleanup -eq 'y' -or $cleanup -eq 'Y') {
    Write-Host "Test files will remain for your testing. Run this script again to clean up."
} else {
    Write-Host "Test files created. Remember to clean up C:\Temp\BackupTest when done testing."
}

Write-Host "`nTest script completed!" -ForegroundColor Green