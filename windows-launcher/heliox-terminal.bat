@echo off
REM Heliox ATLAS v21 - Windows Terminal Launcher (Batch Version)
REM This batch file launches WSL with the Heliox project

setlocal enabledelayedexpansion

REM Set colors
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "CYAN=[96m"
set "RESET=[0m"

REM Project paths
set "PROJECT_PATH=C:\New Claude Code\V21 Ver01"
set "WSL_PROJECT_PATH=/mnt/c/New Claude Code/V21 Ver01"

echo.
echo %CYAN%=======================================%RESET%
echo %CYAN%  Heliox ATLAS v21 - Terminal Launcher%RESET%
echo %CYAN%=======================================%RESET%
echo.

REM Check if WSL is installed
where wsl.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: WSL not found!%RESET%
    echo.
    echo To install WSL:
    echo 1. Open PowerShell as Administrator
    echo 2. Run: wsl --install
    echo 3. Restart your computer
    echo.
    echo Or enable WSL in Windows Features:
    echo - Search for "Turn Windows features on or off"
    echo - Check "Windows Subsystem for Linux"
    echo.
    pause
    exit /b 1
)

echo %GREEN%✓%RESET% WSL found

REM Check if project directory exists
if not exist "%PROJECT_PATH%" (
    echo %RED%ERROR: Project directory not found!%RESET%
    echo Path: %PROJECT_PATH%
    echo.
    echo Please check the path and try again.
    echo.
    pause
    exit /b 1
)

echo %GREEN%✓%RESET% Project directory found

REM Check for Windows Terminal
where wt.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✓%RESET% Windows Terminal found
    echo.
    echo Launching in Windows Terminal...
    
    REM Launch with Windows Terminal
    start "" wt.exe -d "%PROJECT_PATH%" wsl.exe bash -l -c "cd '%WSL_PROJECT_PATH%' && if [ -f ./start-heliox.sh ]; then ./start-heliox.sh; else echo 'Welcome to Heliox ATLAS v21'; echo 'Directory: %WSL_PROJECT_PATH%'; echo 'Run: make help for commands'; fi; exec bash"
    
    if %errorlevel% equ 0 (
        echo %GREEN%Successfully launched!%RESET%
        timeout /t 2 /nobreak >nul
        exit /b 0
    )
)

REM Fallback to regular WSL window
echo %YELLOW%Windows Terminal not found, using default terminal...%RESET%
echo.
echo Launching WSL...

REM Try to launch WSL with the project directory
wsl.exe bash -l -c "cd '%WSL_PROJECT_PATH%' && if [ -f ./start-heliox.sh ]; then ./start-heliox.sh; else echo 'Welcome to Heliox ATLAS v21'; echo 'Directory: %WSL_PROJECT_PATH%'; echo 'Run: make help for commands'; fi; exec bash"

if %errorlevel% neq 0 (
    echo.
    echo %RED%Failed to launch WSL with project directory.%RESET%
    echo.
    echo Trying basic WSL launch...
    
    REM Last resort - just launch WSL
    start "" wsl.exe
    
    echo.
    echo %YELLOW%Please navigate manually to:%RESET%
    echo cd %WSL_PROJECT_PATH%
    echo.
    pause
)

endlocal