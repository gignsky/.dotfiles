# wsl-vhd-info.ps1 — report a WSL distro's ext4.vhdx size as JSON (read-only, no elevation).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File wsl-vhd-info.ps1 -Distro NixOS
#
# "length" is the logical file size (what Explorer calls Size); "allocated" is
# what the file actually occupies on the Windows drive (Size on disk), which is
# what matters for a sparse vhdx.

param([string]$Distro = "NixOS")
$ErrorActionPreference = "Stop"

$lxss = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
$entry = Get-ChildItem $lxss | ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DistributionName -eq $Distro } | Select-Object -First 1
if (-not $entry) { throw "Distro '$Distro' not found under $lxss" }
$path = Join-Path ($entry.BasePath -replace '^\\\\\?\\', '') "ext4.vhdx"
$item = Get-Item $path

Add-Type -Namespace WslVhd -Name Native -MemberDefinition '[DllImport("kernel32.dll", CharSet=CharSet.Unicode)] public static extern uint GetCompressedFileSizeW(string name, out uint high);'
$high = [uint32]0
$low = [WslVhd.Native]::GetCompressedFileSizeW($path, [ref]$high)

[ordered]@{
    path      = $path
    sparse    = [bool]($item.Attributes -band [IO.FileAttributes]::SparseFile)
    length    = [int64]$item.Length
    allocated = [int64](([uint64]$high -shl 32) + $low)
} | ConvertTo-Json -Compress
