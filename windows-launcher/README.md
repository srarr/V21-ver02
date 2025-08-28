# Heliox ATLAS v21 - Windows Launcher

Windows-specific scripts for launching Heliox ATLAS v21 in WSL environment.

## Quick Start

Double-click any of these files to launch:
- `heliox-terminal.bat` - **Recommended** - Batch file with color output
- `heliox-terminal.ps1` - PowerShell script with advanced features
- `heliox-terminal-fixed.vbs` - VBScript with error handling

## Available Launchers

### 1. Batch File (`heliox-terminal.bat`)
**Recommended for most users**
- Color-coded output
- Clear error messages
- Works on all Windows versions
- Shows progress indicators

### 2. PowerShell Script (`heliox-terminal.ps1`)
**Best for advanced users**
- Comprehensive error checking
- Debug mode available (`-Debug` flag)
- Detailed WSL distribution detection
- Multiple fallback methods

To run with debug mode:
```powershell
powershell -ExecutionPolicy Bypass -File heliox-terminal.ps1 -Debug
```

### 3. VBScript (`heliox-terminal-fixed.vbs`)
**Silent launcher**
- No console window
- Message boxes for errors
- Multiple launch methods
- Good for shortcuts

### 4. Original Scripts
- `heliox-terminal.vbs` - Original VBScript (may have issues)
- `heliox-wsl.bat` - Basic WSL launcher
- `CREATE-DESKTOP-SHORTCUT.bat` - Creates desktop shortcuts

## Troubleshooting

### Error: "The system cannot find the file specified" (0x80070002)

This error usually means WSL is not properly installed or configured.

**Solutions:**
1. **Install WSL** (if not installed):
   ```powershell
   # Run in PowerShell as Administrator
   wsl --install
   # Restart computer after installation
   ```

2. **Install a Linux distribution**:
   ```powershell
   wsl --install Ubuntu
   ```

3. **Check WSL status**:
   ```powershell
   wsl --status
   wsl --list --verbose
   ```

4. **Reset WSL** (if corrupted):
   ```powershell
   # Run as Administrator
   wsl --shutdown
   wsl --unregister Ubuntu
   wsl --install Ubuntu
   ```

### Error: "Windows Terminal not found"

Windows Terminal provides the best experience but is optional.

**Install Windows Terminal:**
- From Microsoft Store: Search "Windows Terminal"
- From PowerShell:
  ```powershell
  winget install Microsoft.WindowsTerminal
  ```

### Error: "Project directory not found"

The launcher expects the project at: `C:\New Claude Code\V21 Ver01`

**Solutions:**
1. Check if the path exists
2. Update the path in the launcher scripts if your project is elsewhere
3. Ensure no typos in the directory name

### WSL Issues

**Common WSL problems and fixes:**

1. **WSL not enabled in Windows Features:**
   - Open "Turn Windows features on or off"
   - Check "Windows Subsystem for Linux"
   - Check "Virtual Machine Platform"
   - Restart computer

2. **WSL version issues:**
   ```powershell
   # Update to WSL 2
   wsl --set-default-version 2
   
   # Update WSL kernel
   wsl --update
   ```

3. **Permission issues:**
   - Run launchers as Administrator if needed
   - Check Windows Defender/Antivirus settings

## Creating Desktop Shortcuts

### Automatic Method
Run `CREATE-DESKTOP-SHORTCUT.bat` to automatically create shortcuts.

### Manual Method
1. Right-click on desktop → New → Shortcut
2. Browse to launcher file (`heliox-terminal.bat` recommended)
3. Name it "Heliox ATLAS v21"
4. Optional: Change icon in Properties

## Manual Launch Methods

If all launchers fail, try manually:

### Method 1: Command Prompt
```cmd
wsl
cd "/mnt/c/New Claude Code/V21 Ver01"
./start-heliox.sh
```

### Method 2: PowerShell
```powershell
wsl bash -c "cd '/mnt/c/New Claude Code/V21 Ver01' && ./start-heliox.sh"
```

### Method 3: Windows Terminal
```cmd
wt.exe wsl -d Ubuntu
# Then navigate to project directory
```

## After Launch

The terminal will:
1. Show project status
2. Display environment check
3. List quick commands
4. Ask if you want to open Claude Code

Available commands:
- `make dev` - Start all services
- `make db-up` - Start Supabase
- `make test` - Run tests
- `make help` - See all commands

## Requirements

- Windows 10 version 1903+ or Windows 11
- WSL 2 installed with a Linux distribution
- Project files at `C:\New Claude Code\V21 Ver01`
- Optional: Windows Terminal for best experience

## Customization

If your project is in a different location, update paths in all scripts:
- Windows path: `C:\New Claude Code\V21 Ver01`
- WSL path: `/mnt/c/New Claude Code/V21 Ver01`

## Support

If you continue to have issues:
1. Run the PowerShell launcher with `-Debug` flag
2. Take a screenshot of any error messages
3. Check WSL logs: `wsl --log-level verbose`
4. Verify project files exist in WSL: `wsl ls "/mnt/c/New Claude Code/V21 Ver01"`