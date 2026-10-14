<#
.SYNOPSIS
    Prompts the user to accept a default source file or browse for one.
    If browsing, it checks the clipboard for a valid path/file to pre-navigate to.
#>

# Define your default source file path here
$defaultPath = "C:\path\to\your\default_source.txt"

Write-Host "Default source file: $defaultPath" -ForegroundColor Cyan
$response = Read-Host "Do you want to use this default file? (Y/N)"

$sourceFile = $null

# Check if user accepted the default path
if ($response -eq 'Y' -or $response -eq 'yes') {
    if (Test-Path $defaultPath) {
        $sourceFile = $defaultPath
        Write-Host "Using default file: $sourceFile" -ForegroundColor Green
    } else {
        Write-Warning "The default file could not be found at: $defaultPath"
        Write-Host "Launching File Explorer to choose a file manually..." -ForegroundColor Yellow
        $response = 'N' # Force fallback to file dialog
    }
}

# Open File Explorer dialog if default was rejected or not found
if ($response -ne 'Y' -and $response -ne 'yes') {
    # Load Windows Forms assembly for the file dialog
    Add-Type -AssemblyName System.Windows.Forms

    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Title = "Select Source File"
    $fileDialog.Filter = "All Files (*.*)|*.*|Text Files (*.txt)|*.txt"
    $fileDialog.RestoreDirectory = $true

    # Check clipboard for a valid path
    $clipboardText = Get-Clipboard -ErrorAction SilentlyContinue
    $validClipboardPath = $null

    if (-not [string]::IsNullOrEmpty($clipboardText)) {
        # Clean potential surrounding quotes from copied paths
        $cleanPath = $clipboardText.Trim('"').Trim("'")
        if (Test-Path $cleanPath) {
            $validClipboardPath = $cleanPath
        }
    }

    # Set initial directory or pre-selected file based on clipboard
    if ($validClipboardPath) {
        if (Test-Path $validClipboardPath -PathType Container) {
            # Clipboard is a valid folder
            $fileDialog.InitialDirectory = $validClipboardPath
            Write-Host "Using clipboard folder path: $validClipboardPath" -ForegroundColor Cyan
        } else {
            # Clipboard is a valid file
            $fileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($validClipboardPath)
            $fileDialog.FileName = [System.IO.Path]::GetFileName($validClipboardPath)
            Write-Host "Pre-selecting clipboard file: $validClipboardPath" -ForegroundColor Cyan
        }
    } else {
        # Fallback to default folder (My Documents)
        $fileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
        Write-Host "Clipboard path not found or invalid. Opening default folder (Documents)." -ForegroundColor DarkYellow
    }

    # Show the dialog
    $dialogResult = $fileDialog.ShowDialog()

    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $sourceFile = $fileDialog.FileName
        Write-Host "Selected file: $sourceFile" -ForegroundColor Green
    } else {
        Write-Error "No file was selected. Operation cancelled."
        exit
    }
}

# --- Your script logic continues here ---
Write-Host "Proceeding with file: $sourceFile" -ForegroundColor Yellow

# Example: Read content from the chosen file
# Get-Content $sourceFile