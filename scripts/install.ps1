# Pointbreak Debug CLI Installation Script for Windows
#
# Usage:
#   irm https://raw.githubusercontent.com/withpointbreak/pointbreak-debug/main/scripts/install.ps1 | iex
#
# Or with parameters:
#   $version = "0.4.1"; irm https://raw.githubusercontent.com/withpointbreak/pointbreak-debug/main/scripts/install.ps1 | iex
#
# Prefer the stable entry point: https://withpointbreak.com/install.ps1
# Raw URLs under the old repository slug are unsupported after slug reuse.
# Downloads from: https://download.withpointbreak.com/cli/

param(
    [string]$Version = "latest",
    [string]$InstallDir = "$env:LOCALAPPDATA\Pointbreak\bin",
    [switch]$NoVerify
)

$ErrorActionPreference = "Stop"

# Configuration
$RepositoryUrl = "https://github.com/withpointbreak/pointbreak-debug"
$DownloadBaseUrl = "https://download.withpointbreak.com"

# Colors
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "  $Message" -ForegroundColor Cyan
}

# Print header
Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-ColorOutput "  Pointbreak Debug Installer" -ForegroundColor Blue
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Detect platform
function Get-Platform {
    $arch = $env:PROCESSOR_ARCHITECTURE

    switch ($arch) {
        "AMD64" {
            $platform = "win32-x64"
        }
        "ARM64" {
            $platform = "win32-arm64"
        }
        default {
            Write-Error "Unsupported architecture: $arch"
            Write-Info "Supported architectures: AMD64 (x64), ARM64"
            exit 1
        }
    }

    Write-Success "Detected platform: $platform"
    return $platform
}

# Get download URL
function Get-DownloadUrl {
    param([string]$Platform)

    if ($Version -eq "latest") {
        Write-Info "Fetching latest Debug CLI version..."

        try {
            $listing = Invoke-WebRequest -Uri "$DownloadBaseUrl/cli/latest/" -UseBasicParsing -ErrorAction Stop
            $listingContent = $listing.Content

            if ($listingContent -match 'pointbreak-v(\d+\.\d+\.\d+)') {
                $versionClean = $matches[1]
                Write-Info "Using latest version: v$versionClean"
                $versionPath = "latest"
                $archiveName = "pointbreak-v$versionClean-$Platform.zip"
            }
            else {
                Write-Warning "Could not detect latest version"
                Write-Info "Falling back to the version-less filename..."
                $versionPath = "latest"
                $archiveName = "pointbreak-$Platform.zip"
            }
        }
        catch {
            Write-Warning "Could not fetch version info: $_"
            Write-Info "Falling back to the version-less filename..."
            $versionPath = "latest"
            $archiveName = "pointbreak-$Platform.zip"
        }
    }
    else {
        Write-Info "Using version: $Version"
        $versionClean = $Version -replace '^v', ''
        $versionPath = "v$versionClean"
        $archiveName = "pointbreak-v$versionClean-$Platform.zip"
    }

    Write-Success "Download path: cli/$versionPath"

    $archiveUrl = "$DownloadBaseUrl/cli/$versionPath/$archiveName"
    $checksumsUrl = "$DownloadBaseUrl/cli/$versionPath/checksums.txt"

    return @{
        VersionPath  = $versionPath
        ArchiveName  = $archiveName
        ArchiveUrl   = $archiveUrl
        ChecksumsUrl = $checksumsUrl
    }
}

# Download and verify binary
function Install-Binary {
    param(
        [hashtable]$DownloadInfo,
        [string]$Platform
    )

    $tempDir = New-Item -ItemType Directory -Path "$env:TEMP\pointbreak-install-$(New-Guid)"
    $archivePath = Join-Path $tempDir $DownloadInfo.ArchiveName

    try {
        Write-Host ""
        Write-Info "Downloading archive..."

        Invoke-WebRequest -Uri $DownloadInfo.ArchiveUrl -OutFile $archivePath

        if (-not (Test-Path $archivePath)) {
            Write-Error "Download failed"
            exit 1
        }

        $fileSize = (Get-Item $archivePath).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-Success "Downloaded: $fileSizeMB MB"

        # Verify checksum
        if (-not $NoVerify) {
            Write-Host ""
            Write-Info "Verifying checksum..."

            try {
                $checksumsPath = Join-Path $tempDir "checksums.txt"
                Invoke-WebRequest -Uri $DownloadInfo.ChecksumsUrl -OutFile $checksumsPath

                $checksums = Get-Content $checksumsPath
                $expectedLine = $checksums | Where-Object { $_ -match $DownloadInfo.ArchiveName }

                if ($expectedLine) {
                    $expectedChecksum = $expectedLine.Split()[0]

                    # Validate checksum format (64 hex characters for SHA256)
                    if ($expectedChecksum -notmatch '^[a-f0-9]{64}$') {
                        Write-Warning "Invalid checksum format (expected 64 hex characters)"
                        Write-Info "Skipping checksum verification"
                    }
                    else {
                        $actualHash = Get-FileHash -Path $archivePath -Algorithm SHA256
                        $actualChecksum = $actualHash.Hash.ToLower()

                        if ($actualChecksum -eq $expectedChecksum) {
                            Write-Success "Checksum verified"
                        }
                        else {
                            Write-Error "Checksum mismatch!"
                            Write-Info "Expected: $expectedChecksum"
                            Write-Info "Got:      $actualChecksum"
                            exit 1
                        }
                    }
                }
                else {
                    Write-Warning "Checksum not found in checksums.txt"
                    Write-Info "Skipping checksum verification"
                }
            }
            catch {
                Write-Warning "Could not verify checksum: $_"
                Write-Info "Continuing anyway..."
            }
        }

        Write-Host ""
        Write-Info "Extracting archive..."

        $extractDir = Join-Path $tempDir "extracted"
        Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force
        $binaryPath = Join-Path $extractDir "pointbreak.exe"

        if (-not (Test-Path $binaryPath)) {
            Write-Error "Binary not found in archive"
            exit 1
        }

        Write-Success "Extracted successfully"

        # Install binary
        Write-Host ""
        Write-Info "Installing to: $InstallDir"

        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        }

        $targetPath = Join-Path $InstallDir "pointbreak.exe"
        Copy-Item -Path $binaryPath -Destination $targetPath -Force

        Write-Success "Installed successfully"

        # Verify installation
        Write-Host ""
        Write-Info "Verifying installation..."
        try {
            $versionOutput = & $targetPath --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $installedVersion = ($versionOutput | Select-Object -First 1).ToString()
                Write-Success "Verification successful: $installedVersion"
            }
            else {
                Write-Warning "Could not verify installation"
                Write-Info "Binary installed but --version check failed"
            }
        }
        catch {
            Write-Warning "Could not verify installation: $_"
            Write-Info "Binary installed but verification failed"
        }

        return $targetPath
    }
    finally {
        # Cleanup temp directory
        # Add small delay to avoid Windows file locking issues
        Start-Sleep -Seconds 1
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Check if directory is in PATH
function Test-PathEntry {
    param([string]$Directory)

    Write-Host ""

    $pathEntries = $env:PATH -split ";"
    $inPath = $pathEntries -contains $Directory

    if ($inPath) {
        Write-Success "Install directory is in PATH"
        return $true
    }
    else {
        Write-Warning "Install directory is not in PATH"
        return $false
    }
}

# Add directory to PATH
function Add-ToPath {
    param([string]$Directory)

    Write-Host ""
    Write-Info "Adding to PATH..."

    try {
        # Get current user PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

        # Check if already in PATH
        $pathEntries = $currentPath -split ";"
        if ($pathEntries -contains $Directory) {
            Write-Success "Directory already in PATH"
            return
        }

        # Add to PATH
        $newPath = "$currentPath;$Directory"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

        # Update current session
        $env:PATH = "$env:PATH;$Directory"

        Write-Success "Added to PATH"
        Write-Warning "Please restart your terminal for PATH changes to take effect"
    }
    catch {
        Write-Error "Failed to add to PATH: $_"
        Write-Host ""
        Write-Info "You can manually add to PATH by running:"
        Write-Host "  `$env:PATH += `";$Directory`"" -ForegroundColor Cyan
    }
}

# Print next steps
function Show-NextSteps {
    Write-Host ""
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-ColorOutput "  Installation Complete!" -ForegroundColor Green
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Info "Verify installation:"
    Write-Host "  pointbreak --version" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Install the final Pointbreak Debug VS Code extension (v0.2.5)" -ForegroundColor White
    Write-Host "  2. Configure your AI assistant to use the Pointbreak Debug MCP server" -ForegroundColor White
    Write-Host "  3. Support: $RepositoryUrl/issues" -ForegroundColor Cyan
    Write-Host ""
}

# Main installation flow
function Main {
    $platform = Get-Platform
    $downloadInfo = Get-DownloadUrl -Platform $platform
    $binaryPath = Install-Binary -DownloadInfo $downloadInfo -Platform $platform

    $inPath = Test-PathEntry -Directory $InstallDir

    if (-not $inPath) {
        $response = Read-Host "Add install directory to PATH? (Y/n)"
        if ($response -eq "" -or $response -eq "Y" -or $response -eq "y") {
            Add-ToPath -Directory $InstallDir
        }
    }

    Show-NextSteps
}

# Run main function
Main
