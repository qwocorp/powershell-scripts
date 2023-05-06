# Set source and destination directories
Param(
    [Parameter(Mandatory=$true)][string]$sourceDir,
    [Parameter(Mandatory=$true)][string]$destDir 
)
# Set list of subdirectories to zip
$subDirs = @("_classic_\WTF", "_classic_\Cache", "_classic_\Interface","_classic_era_\WTF", "_classic_era_\Cache", "_classic_era_\Interface","_retail_\WTF", "_retail_\Cache", "_retail_\Interface")

# Find subdirectories that exist in the source folder
$subDirs = $subDirs | Where-Object { Test-Path (Join-Path $sourceDir $_) -PathType Container }

# Check if any subdirectories were found
if ($subDirs.Count -eq 0) {
    Write-Error "No subdirectories were found in the source folder"
    return
}

# Display subdirectories that will be included in the backup
Write-Host "Subdirectories to include in backup:"
$subDirs | ForEach-Object { Write-Host " - $_" }

# Get current date to use in naming the backup folder and zip file
$date = Get-Date -Format "yyyy-MM-dd"

# Destination directory path
$destinationPath = "$destDir\$date"

# Check if destination directory already exists
if (Test-Path $destinationPath) {
    Write-Host "Destination directory already exists."
    $backupFolder = $destinationPath
} else {
    # Create backup folder
    $backupFolder = New-Item -ItemType Directory -Path $destinationPath
    Write-Host "Created backup folder $backupFolder"
}

# Get total file count and size of subdirectories
$totalFileCount = 0
$totalFileSize = 0
foreach ($subDir in $subDirs) {
    $subDirPath = Join-Path -Path $sourceDir -ChildPath $subDir
    $subDirFiles = Get-ChildItem $subDirPath -Recurse -File
    $subDirFileCount = $subDirFiles.Count
    $subDirFileSize = ($subDirFiles | Measure-Object -Property Length -Sum).Sum
    $totalFileCount += $subDirFileCount
    $totalFileSize += $subDirFileSize
    Write-Host "Subdirectory $subDir contains $subDirFileCount files totaling $(($subDirFileSize / 1GB).ToString("0.00")) GB"
}

# Prompt user to confirm backup
$confirm = Read-Host "Are you sure you want to create a backup of $totalFileCount files totaling $(($totalFileSize / 1GB).ToString("0.00")) GB? (Y/N)"
if ($confirm -ne "Y") {
    Write-Host "Backup cancelled by user."
    Exit
}

# Set zip file name and path
$zipFileName = "Backup_$date.zip"
$zipFilePath = Join-Path -Path $sourceDir -ChildPath $zipFileName

# Zip subdirectories to a new zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipFile = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
foreach ($subDir in $subDirs) {
    $subDirPath = Join-Path -Path $sourceDir -ChildPath $subDir
    $subDirFiles = Get-ChildItem $subDirPath -Recurse -File
    foreach ($file in $subDirFiles) {
        $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
        $entryName = [System.IO.Path]::Combine($relativePath)
        $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipFile, $file.FullName, $entryName)
    }
}
$zipFile.Dispose()

# Move zip file to backup folder on destination directory
Move-Item -Path $zipFilePath -Destination "$backupFolder" -verbose


