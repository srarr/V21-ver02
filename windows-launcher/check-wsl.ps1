# Heliox ATLAS v21 - WSL Checker Script
# Diagnoses WSL installation and configuration issues

param(
    [switch]$Fix = $false
)

# Color functions
function Write-Success { Write-Host "✓ " -ForegroundColor Green -NoNewline; Write-Host $args[0] }
function Write-Warning { Write-Host "⚠ " -ForegroundColor Yellow -NoNewline; Write-Host $args[0] }
function Write-Err { Write-Host "✗ " -ForegroundColor Red -NoNewline; Write-Host $args[0] }
function Write-Info { Write-Host "ℹ " -ForegroundColor Cyan -NoNewline; Write-Host $args[0] }

Clear-Host
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     WSL Installation Checker" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Success "Running as Administrator"
} else {
    Write-Warning "Not running as Administrator (some checks may be limited)"
}

Write-Host
Write-Host "System Information:" -ForegroundColor Cyan
Write-Host "-------------------"

# Check Windows version
$os = Get-WmiObject Win32_OperatingSystem
$build = [System.Environment]::OSVersion.Version.Build
Write-Info "Windows Version: $($os.Caption)"
Write-Info "Build: $build"

if ($build -lt 18362) {
    Write-Err "Your Windows version is too old for WSL 2"
    Write-Host "  Minimum required: Windows 10 version 1903 (Build 18362)" -ForegroundColor Yellow
} else {
    Write-Success "Windows version supports WSL 2"
}

Write-Host
Write-Host "WSL Status:" -ForegroundColor Cyan
Write-Host "-----------"

# Check if WSL is installed
$wslPath = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($wslPath) {
    Write-Success "WSL executable found: $($wslPath.Path)"
    
    # Check WSL version
    try {
        $wslVersion = & wsl --version 2>$null
        if ($wslVersion) {
            Write-Success "WSL version info:"
            $wslVersion | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    } catch {
        Write-Warning "Could not get WSL version info"
    }
} else {
    Write-Err "WSL is not installed or not in PATH"
    
    if ($Fix -and $isAdmin) {
        Write-Host
        Write-Warning "Attempting to install WSL..."
        try {
            wsl --install
            Write-Success "WSL installation initiated. Please restart your computer."
        } catch {
            Write-Err "Failed to install WSL: $_"
        }
    } else {
        Write-Host
        Write-Host "To install WSL:" -ForegroundColor Yellow
        Write-Host "1. Run PowerShell as Administrator"
        Write-Host "2. Execute: wsl --install"
        Write-Host "3. Restart your computer"
        Write-Host
        Write-Host "Or run this script with -Fix flag as Administrator" -ForegroundColor Cyan
    }
    exit 1
}

Write-Host
Write-Host "Windows Features:" -ForegroundColor Cyan
Write-Host "-----------------"

# Check Windows features
$features = @{
    "Microsoft-Windows-Subsystem-Linux" = "Windows Subsystem for Linux"
    "VirtualMachinePlatform" = "Virtual Machine Platform"
    "Microsoft-Hyper-V" = "Hyper-V (optional)"
}

foreach ($feature in $features.Keys) {
    try {
        $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue).State
        if ($state -eq "Enabled") {
            Write-Success "$($features[$feature]): Enabled"
        } else {
            if ($feature -eq "Microsoft-Hyper-V") {
                Write-Info "$($features[$feature]): Not enabled (optional)"
            } else {
                Write-Warning "$($features[$feature]): Not enabled"
                
                if ($Fix -and $isAdmin) {
                    Write-Host "  Attempting to enable..." -ForegroundColor Yellow
                    Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
                }
            }
        }
    } catch {
        Write-Info "$($features[$feature]): Could not check (may require admin)"
    }
}

Write-Host
Write-Host "Linux Distributions:" -ForegroundColor Cyan
Write-Host "-------------------"

# Check installed distributions
try {
    $distros = wsl --list --verbose 2>$null | Where-Object { $_ -match '\S' }
    
    if ($distros -and $distros.Count -gt 1) {
        Write-Success "Installed distributions:"
        $distros | ForEach-Object { 
            if ($_ -notmatch "NAME|----") {
                Write-Host "  $_" -ForegroundColor Gray 
            }
        }
        
        # Check default distribution
        $default = wsl --list --verbose 2>$null | Where-Object { $_ -match '\*' }
        if ($default) {
            Write-Success "Default distribution: $($default -replace '^\*\s*', '')"
        }
    } else {
        Write-Warning "No Linux distributions installed"
        
        if ($Fix) {
            Write-Host
            Write-Info "Installing Ubuntu..."
            try {
                wsl --install Ubuntu
                Write-Success "Ubuntu installation initiated"
            } catch {
                Write-Err "Failed to install Ubuntu: $_"
            }
        } else {
            Write-Host
            Write-Host "To install Ubuntu:" -ForegroundColor Yellow
            Write-Host "  wsl --install Ubuntu"
        }
    }
} catch {
    Write-Err "Could not list distributions: $_"
}

Write-Host
Write-Host "WSL Configuration:" -ForegroundColor Cyan
Write-Host "-----------------"

# Check default WSL version
try {
    $defaultVersion = wsl --status 2>$null | Select-String "Default Version"
    if ($defaultVersion) {
        Write-Info $defaultVersion.Line.Trim()
    }
} catch {
    Write-Warning "Could not determine default WSL version"
}

# Check if WSL 2 kernel is updated
try {
    $kernelVersion = wsl --version 2>$null | Select-String "Kernel version"
    if ($kernelVersion) {
        Write-Info $kernelVersion.Line.Trim()
    }
} catch {}

Write-Host
Write-Host "Project Check:" -ForegroundColor Cyan
Write-Host "--------------"

$projectPath = "C:\New Claude Code\V21 Ver01"
$wslProjectPath = "/mnt/c/New Claude Code/V21 Ver01"

if (Test-Path $projectPath) {
    Write-Success "Project directory found: $projectPath"
    
    # Check if accessible from WSL
    try {
        $wslLs = wsl ls "$wslProjectPath" 2>$null
        if ($wslLs) {
            Write-Success "Project accessible from WSL"
            
            # Check for start-heliox.sh
            $startScript = wsl test -f "$wslProjectPath/start-heliox.sh" 2>$null
            if ($?) {
                Write-Success "start-heliox.sh found"
            } else {
                Write-Warning "start-heliox.sh not found in project directory"
            }
        } else {
            Write-Warning "Project not accessible from WSL"
        }
    } catch {
        Write-Warning "Could not check WSL access to project"
    }
} else {
    Write-Err "Project directory not found: $projectPath"
}

Write-Host
Write-Host "Windows Terminal:" -ForegroundColor Cyan
Write-Host "----------------"

$wtPath = Get-Command wt.exe -ErrorAction SilentlyContinue
if ($wtPath) {
    Write-Success "Windows Terminal found: $($wtPath.Path)"
} else {
    Write-Warning "Windows Terminal not installed (optional but recommended)"
    Write-Host "  Install from Microsoft Store or:" -ForegroundColor Gray
    Write-Host "  winget install Microsoft.WindowsTerminal" -ForegroundColor Gray
}

Write-Host
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "           Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$issues = 0

# Summarize issues
if (-not $wslPath) {
    $issues++
    Write-Err "WSL is not installed"
}

try {
    $distros = wsl --list --quiet 2>$null
    if (-not $distros -or $distros.Count -eq 0) {
        $issues++
        Write-Err "No Linux distributions installed"
    }
} catch {}

if (-not (Test-Path $projectPath)) {
    $issues++
    Write-Err "Project directory not found"
}

if ($issues -eq 0) {
    Write-Host
    Write-Success "All checks passed! WSL should be working correctly."
    Write-Host
    Write-Host "Try running:" -ForegroundColor Green
    Write-Host "  .\heliox-terminal.bat" -ForegroundColor Yellow
    Write-Host "  or"
    Write-Host "  .\heliox-terminal.ps1" -ForegroundColor Yellow
} else {
    Write-Host
    Write-Warning "Found $issues issue(s)"
    
    if (-not $Fix) {
        Write-Host
        Write-Host "Run with -Fix flag to attempt automatic fixes:" -ForegroundColor Cyan
        Write-Host "  .\check-wsl.ps1 -Fix" -ForegroundColor Yellow
        
        if (-not $isAdmin) {
            Write-Host
            Write-Host "Note: Some fixes require Administrator privileges" -ForegroundColor Gray
        }
    }
}

Write-Host
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host