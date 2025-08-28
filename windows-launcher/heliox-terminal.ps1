# Heliox ATLAS v21 - PowerShell Launcher (Enhanced Version)
# Opens WSL in Windows Terminal with comprehensive error handling

param(
    [switch]$Debug = $false
)

# Configuration
$projectPath = "C:\New Claude Code\V21 Ver01"
$wslPath = "/mnt/c/New Claude Code/V21 Ver01"

# Color output functions
function Write-Success {
    param($Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param($Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Err {
    param($Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Info {
    param($Message)
    Write-Host "ℹ " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

# Header
Clear-Host
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Heliox ATLAS v21 - Terminal Launcher" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host

# Check WSL installation
function Test-WSL {
    $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $wslCommand) {
        Write-Err "WSL not found!"
        Write-Host
        Write-Host "To install WSL:" -ForegroundColor Yellow
        Write-Host "1. Open PowerShell as Administrator"
        Write-Host "2. Run: wsl --install"
        Write-Host "3. Restart your computer"
        Write-Host
        Write-Host "Or enable WSL in Windows Features:"
        Write-Host "- Search for 'Turn Windows features on or off'"
        Write-Host "- Check 'Windows Subsystem for Linux'"
        Write-Host
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Success "WSL found"
    
    # Check if any distributions are installed
    $distributions = wsl --list --quiet 2>$null
    if (-not $distributions -or $distributions.Count -eq 0) {
        Write-Warning "No WSL distributions installed"
        Write-Host "Install Ubuntu with: wsl --install Ubuntu" -ForegroundColor Yellow
        Write-Host
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    } else {
        Write-Success "WSL distribution: $($distributions[0])"
    }
    
    return $true
}

# Check project directory
function Test-ProjectDirectory {
    if (-not (Test-Path $projectPath)) {
        Write-Err "Project directory not found!"
        Write-Host "Path: $projectPath" -ForegroundColor Red
        Write-Host
        Write-Host "Please check the path and try again."
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Success "Project directory found"
    return $true
}

# Check Windows Terminal
function Test-WindowsTerminal {
    $wtCommand = Get-Command wt.exe -ErrorAction SilentlyContinue
    if ($wtCommand) {
        Write-Success "Windows Terminal found"
        return $true
    } else {
        Write-Warning "Windows Terminal not found (will use default terminal)"
        return $false
    }
}

# Launch with Windows Terminal
function Start-WindowsTerminal {
    Write-Host
    Write-Info "Launching in Windows Terminal..."
    
    $arguments = @(
        "--title", "Heliox ATLAS v21",
        "-d", $projectPath
    )
    
    # Build the WSL command
    $wslCommand = "cd '$wslPath' && if [ -f ./start-heliox.sh ]; then ./start-heliox.sh; else echo 'Welcome to Heliox ATLAS v21'; echo 'Directory: $wslPath'; echo 'Run: make help for commands'; fi; exec bash"
    
    $arguments += @("wsl.exe", "bash", "-l", "-c", $wslCommand)
    
    if ($Debug) {
        Write-Host "Debug: wt.exe arguments:" -ForegroundColor Gray
        Write-Host ($arguments -join " ") -ForegroundColor Gray
    }
    
    try {
        $process = Start-Process wt.exe -ArgumentList $arguments -PassThru
        Start-Sleep -Milliseconds 500
        
        if ($process.HasExited -and $process.ExitCode -ne 0) {
            Write-Err "Windows Terminal failed to launch (Exit code: $($process.ExitCode))"
            return $false
        }
        
        Write-Success "Successfully launched in Windows Terminal!"
        return $true
    }
    catch {
        Write-Err "Failed to launch Windows Terminal: $_"
        return $false
    }
}

# Launch with default terminal
function Start-DefaultTerminal {
    Write-Host
    Write-Info "Launching in default terminal..."
    
    $wslCommand = "cd '$wslPath' && if [ -f ./start-heliox.sh ]; then ./start-heliox.sh; else echo 'Welcome to Heliox ATLAS v21'; echo 'Directory: $wslPath'; echo 'Run: make help for commands'; fi; exec bash"
    
    $arguments = @("bash", "-l", "-c", $wslCommand)
    
    if ($Debug) {
        Write-Host "Debug: wsl.exe arguments:" -ForegroundColor Gray
        Write-Host ($arguments -join " ") -ForegroundColor Gray
    }
    
    try {
        Start-Process wsl.exe -ArgumentList $arguments
        Write-Success "Successfully launched WSL!"
        return $true
    }
    catch {
        Write-Err "Failed to launch WSL: $_"
        return $false
    }
}

# Launch basic WSL (fallback)
function Start-BasicWSL {
    Write-Host
    Write-Warning "Launching basic WSL session..."
    
    try {
        Start-Process wsl.exe
        Write-Host
        Write-Warning "Please navigate manually to:"
        Write-Host "cd $wslPath" -ForegroundColor Yellow
        Write-Host "./start-heliox.sh" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Err "Failed to launch basic WSL: $_"
        return $false
    }
}

# Main execution
try {
    # Run checks
    Test-WSL
    Test-ProjectDirectory
    $hasWT = Test-WindowsTerminal
    
    # Try to launch
    $success = $false
    
    if ($hasWT) {
        $success = Start-WindowsTerminal
    }
    
    if (-not $success) {
        $success = Start-DefaultTerminal
    }
    
    if (-not $success) {
        $success = Start-BasicWSL
    }
    
    if (-not $success) {
        Write-Host
        Write-Err "All launch methods failed!"
        Write-Host
        Write-Host "Manual launch instructions:" -ForegroundColor Yellow
        Write-Host "1. Open Command Prompt or PowerShell"
        Write-Host "2. Type: wsl"
        Write-Host "3. Navigate to: $wslPath"
        Write-Host "4. Run: ./start-heliox.sh"
        Write-Host
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host
    Write-Success "Terminal launched successfully!"
    
    # Keep window open briefly to show success message
    if (-not $Debug) {
        Start-Sleep -Seconds 2
    } else {
        Write-Host
        Read-Host "Debug mode: Press Enter to exit"
    }
}
catch {
    Write-Err "Unexpected error: $_"
    Read-Host "Press Enter to exit"
    exit 1
}