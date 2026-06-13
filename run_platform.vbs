Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = ".\Platforme"

' Launch the Flutter web dev server in the background (hidden)
shell.Run "run_platform.bat", 0, False