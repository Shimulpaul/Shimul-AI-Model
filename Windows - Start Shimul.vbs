Option Explicit
Dim fso, shell, scriptDir, coreDir, installDir, startupDir, pyCheck, agentPath, pyExe, pywExe

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
coreDir = scriptDir & "\_shimul_core"

If Not fso.FileExists(coreDir & "\shimul_agent.py") Then
  MsgBox "Please extract (Unzip) the folder first, then double-click 'Windows - Start Shimul.vbs'.", 48, "Shimul Voice OS"
  WScript.Quit
End If

' 1. Cleanly stop & remove any previous Shimul software versions and old startup entries
shell.Run "powershell -NoProfile -WindowStyle Hidden -Command ""Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*shimul_agent*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }""", 0, True

startupDir = shell.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\Start Menu\Programs\Startup"
On Error Resume Next
If fso.FileExists(startupDir & "\ShimulAlwaysOn.bat") Then fso.DeleteFile startupDir & "\ShimulAlwaysOn.bat", True
If fso.FileExists(startupDir & "\ShimulAlwaysOn.vbs") Then fso.DeleteFile startupDir & "\ShimulAlwaysOn.vbs", True
If fso.FileExists(startupDir & "\ShimulVoiceOS.lnk") Then fso.DeleteFile startupDir & "\ShimulVoiceOS.lnk", True

installDir = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\ShimulVoiceOS"
If fso.FolderExists(installDir) Then
  fso.DeleteFolder installDir, True
End If
On Error GoTo 0

fso.CreateFolder(installDir)
fso.CopyFile coreDir & "\shimul_agent.py", installDir & "\shimul_agent.py", True
fso.CopyFile coreDir & "\shimul_config.json", installDir & "\shimul_config.json", True
fso.CopyFile coreDir & "\requirements.txt", installDir & "\requirements.txt", True

' 2. Detect Python (python or py launcher)
pyExe = "python"
pywExe = "pythonw"
pyCheck = shell.Run("cmd /c python --version", 0, True)
If pyCheck <> 0 Then
  pyCheck = shell.Run("cmd /c py -3 --version", 0, True)
  If pyCheck = 0 Then
    pyExe = "py -3"
    pywExe = "pyw -3"
  Else
    shell.Run "cmd /c winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements", 0, True
    pyCheck = shell.Run("cmd /c python --version", 0, True)
    If pyCheck <> 0 Then
      MsgBox "Python 3 is required once on Windows to run Shimul Buddy. Opening Python download page now.", 48, "Shimul Voice OS"
      shell.Run "https://www.python.org/downloads/", 1, False
      WScript.Quit
    End If
  End If
End If

shell.Run "cmd /c " & pyExe & " -m pip install SpeechRecognition --quiet", 0, True

agentPath = installDir & "\shimul_agent.py"

Dim startupFile
Set startupFile = fso.CreateTextFile(startupDir & "\ShimulAlwaysOn.vbs", True)
startupFile.WriteLine "Set WshShell = CreateObject(""WScript.Shell"")"
startupFile.WriteLine "WshShell.Run """ & pywExe & " """"" & agentPath & """"""", 0, False"
startupFile.Close

shell.Run pywExe & " """ & agentPath & """", 0, False
