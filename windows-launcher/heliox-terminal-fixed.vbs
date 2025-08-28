' Heliox ATLAS v21 - Windows Terminal Launcher (Fixed Version)
' This script launches WSL with proper error handling

Option Explicit

Dim objShell, objFSO, strWSLPath, strWTPath, intResult
Dim strProjectPath, strWSLProjectPath

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Project paths
strProjectPath = "C:\New Claude Code\V21 Ver01"
strWSLProjectPath = "/mnt/c/New Claude Code/V21 Ver01"

' Function to check if a program exists
Function ProgramExists(strProgram)
    Dim strCommand, intReturn
    On Error Resume Next
    strCommand = "where " & strProgram & " >nul 2>&1"
    intReturn = objShell.Run(strCommand, 0, True)
    ProgramExists = (intReturn = 0)
    On Error GoTo 0
End Function

' Function to show error message
Sub ShowError(strTitle, strMessage)
    MsgBox strMessage, vbExclamation, strTitle
End Sub

' Main execution
On Error Resume Next

' Check if WSL is installed
If Not ProgramExists("wsl.exe") Then
    ShowError "WSL Not Found", _
        "Windows Subsystem for Linux (WSL) is not installed or not in PATH." & vbCrLf & vbCrLf & _
        "To install WSL:" & vbCrLf & _
        "1. Open PowerShell as Administrator" & vbCrLf & _
        "2. Run: wsl --install" & vbCrLf & _
        "3. Restart your computer" & vbCrLf & vbCrLf & _
        "Or enable WSL in Windows Features."
    WScript.Quit 1
End If

' Check if project directory exists
If Not objFSO.FolderExists(strProjectPath) Then
    ShowError "Project Not Found", _
        "Project directory not found:" & vbCrLf & _
        strProjectPath & vbCrLf & vbCrLf & _
        "Please check the path and try again."
    WScript.Quit 1
End If

' Try different methods to launch
Dim strCommand, bSuccess
bSuccess = False

' Method 1: Try Windows Terminal (best experience)
If ProgramExists("wt.exe") Then
    strCommand = "wt.exe -d """ & strProjectPath & """ " & _
                 "wsl.exe bash -l -c ""cd '" & strWSLProjectPath & "' && " & _
                 "if [ -f ./start-heliox.sh ]; then ./start-heliox.sh; else " & _
                 "echo 'Welcome to Heliox ATLAS v21'; echo 'Directory: " & strWSLProjectPath & "'; fi; " & _
                 "exec bash"""
    
    intResult = objShell.Run(strCommand, 1, False)
    If Err.Number = 0 Then
        bSuccess = True
    End If
    Err.Clear
End If

' Method 2: Try CMD with WSL (fallback)
If Not bSuccess Then
    strCommand = "cmd.exe /c start ""Heliox Terminal"" wsl.exe bash -l -c " & _
                 """cd '" & strWSLProjectPath & "' && " & _
                 "if [ -f ./start-heliox.sh ]; then ./start-heliox.sh; else " & _
                 "echo 'Welcome to Heliox ATLAS v21'; echo 'Directory: " & strWSLProjectPath & "'; " & _
                 "echo 'Run: make help for commands'; fi; " & _
                 "exec bash"""
    
    intResult = objShell.Run(strCommand, 1, False)
    If Err.Number = 0 Then
        bSuccess = True
    End If
    Err.Clear
End If

' Method 3: Direct WSL launch (last resort)
If Not bSuccess Then
    strCommand = "wsl.exe"
    intResult = objShell.Run(strCommand, 1, False)
    If Err.Number = 0 Then
        MsgBox "WSL launched. Please navigate to:" & vbCrLf & _
               strWSLProjectPath & vbCrLf & vbCrLf & _
               "Run: cd '" & strWSLProjectPath & "'", _
               vbInformation, "Manual Navigation Required"
        bSuccess = True
    End If
    Err.Clear
End If

' If all methods failed
If Not bSuccess Then
    ShowError "Launch Failed", _
        "Could not launch WSL terminal." & vbCrLf & vbCrLf & _
        "Error: " & Err.Description & vbCrLf & vbCrLf & _
        "Try running manually:" & vbCrLf & _
        "1. Open Command Prompt or PowerShell" & vbCrLf & _
        "2. Type: wsl" & vbCrLf & _
        "3. Navigate to: " & strWSLProjectPath
End If

' Clean up
Set objShell = Nothing
Set objFSO = Nothing