Add-Type -AssemblyName System.Windows.Forms

function Select-FolderDialog {
    param([string]$Description="Select a folder", [string]$RootFolder="Desktop")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = $Description
    $foldername.RootFolder = $RootFolder
    $foldername.ShowDialog() | Out-Null
    return $foldername.SelectedPath
}

function Copy-WithProgress {
    param(
        [string]$sourceFolder,
        [string]$destinationFolder
    )

    $files = Get-ChildItem -Path $sourceFolder -Recurse -File
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $currentSize = 0
    $fileCount = 0

    foreach ($file in $files) {
        $fileCount++
        $relativePath = $file.FullName.Substring($sourceFolder.Length + 1)
        $destinationPath = [System.IO.Path]::Combine($destinationFolder, $relativePath)

        $directory = [System.IO.Path]::GetDirectoryName($destinationPath)
        if (!(Test-Path -Path $directory)) {
            New-Item -ItemType Directory -Path $directory | Out-Null
        }

        Copy-Item -Path $file.FullName -Destination $destinationPath
        $currentSize += $file.Length

        $progress = [math]::Round(($currentSize / $totalSize) * 100, 2)
        Write-Progress -Activity "Copying files..." -Status "$progress% Complete:" -PercentComplete $progress -CurrentOperation $file.Name
    }
    Write-Progress -Activity "Copying files..." -Completed
}

Write-Host "Waiting for source folder selection..." -ForeGroundColor Cyan

$source = Select-FolderDialog -Description "Select source folder"

# Output the selected folder
if ($source -ne "") {
    Write-Host "Selected source folder: $source"
} else {
    Write-Host "No source folder selected. Operation cancelled."
    exit
}

Write-Host "Waiting for destination folder selection..." -ForeGroundColor Cyan

$destination = Select-FolderDialog -Description "Select destination folder"

if ($destination -ne "") {
     Write-Host "Selected destination folder: $destination"
    try {
        Copy-WithProgress -sourceFolder $source -destinationFolder $destination
        Write-Host "Copy operation completed successfully."
    } catch {
        Write-Host "An error occurred: $_"
    }
} else {
    Write-Host "No destination folder selected. Operation cancelled."
}
