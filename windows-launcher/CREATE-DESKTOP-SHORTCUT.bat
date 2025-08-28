@echo off
echo ========================================
echo   Creating Heliox Desktop Shortcut
echo ========================================
echo.

:: Create shortcut using PowerShell
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Heliox ATLAS v21.lnk'); $Shortcut.TargetPath = '%CD%\heliox-terminal.vbs'; $Shortcut.WorkingDirectory = '%CD%'; $Shortcut.IconLocation = 'C:\Windows\System32\wsl.exe'; $Shortcut.Description = 'Open Heliox ATLAS v21 Trading Platform in WSL'; $Shortcut.Save()"

echo.
echo ✓ Desktop shortcut created!
echo.
echo You can now double-click "Heliox ATLAS v21" on your desktop
echo to open WSL with the project loaded.
echo.
pause