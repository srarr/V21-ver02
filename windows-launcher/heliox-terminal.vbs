' Heliox ATLAS v21 - Open in Windows Terminal (if available)
' This opens WSL in Windows Terminal with nice UI

Set objShell = CreateObject("WScript.Shell")

' Try Windows Terminal first, fallback to regular WSL
On Error Resume Next

' Try to open in Windows Terminal
objShell.Run "wt.exe -d ""C:\New Claude Code\V21 Ver01"" wsl -e bash -l -c ""cd '/mnt/c/New Claude Code/V21 Ver01' && ./start-heliox.sh; exec bash""", 1, False

If Err.Number <> 0 Then
    ' Fallback to regular WSL window
    objShell.Run "wsl -e bash -l -c ""cd '/mnt/c/New Claude Code/V21 Ver01' && ./start-heliox.sh; exec bash"""
End If