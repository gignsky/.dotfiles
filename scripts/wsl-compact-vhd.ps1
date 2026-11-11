# wsl-compact-vhd.ps1 — shrink a WSL2 distro's ext4.vhdx after `just gc`.
#
# Run from an ELEVATED PowerShell on Windows (not from inside WSL):
#   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\wsl-compact-vhd.ps1" -Distro NixOS
#
# Optional:
#   -Sparse         also switch the vhdx to sparse mode (`wsl --manage --set-sparse`),
#                   so future `fstrim` inside WSL returns space to Windows by itself
#   -VhdPath <p>    skip the registry lookup and compact this file
#
# This runs `wsl --shutdown`, which closes every WSL session. Results are
# appended to $env:USERPROFILE\wsl-compact-vhd.log so the in-WSL test script
# can pick them up afterwards.

#Requires -RunAsAdministrator
param(
    [string]$Distro = "NixOS",
    [string]$VhdPath,
    [switch]$Sparse
)
$ErrorActionPreference = "Stop"
$env:WSL_UTF8 = "1"
$log = Join-Path $env:USERPROFILE "wsl-compact-vhd.log"
function Log($msg) { $line = "[{0}] {1}" -f (Get-Date -Format s), $msg; Write-Host $line; Add-Content -Path $log -Value $line }

if (-not $VhdPath) {
    $lxss = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
    $entry = Get-ChildItem $lxss | ForEach-Object { Get-ItemProperty $_.PSPath } |
        Where-Object { $_.DistributionName -eq $Distro } | Select-Object -First 1
    if (-not $entry) {
        $names = (Get-ChildItem $lxss | ForEach-Object { (Get-ItemProperty $_.PSPath).DistributionName }) -join ", "
        throw "Distro '$Distro' not found under $lxss (found: $names). Pass -Distro or -VhdPath."
    }
    $VhdPath = Join-Path ($entry.BasePath -replace '^\\\\\?\\', '') "ext4.vhdx"
}
if (-not (Test-Path $VhdPath)) { throw "vhdx not found: $VhdPath" }

$before = (Get-Item $VhdPath).Length
Log ("{0}: {1:N1} GB before compaction ({2})" -f $Distro, ($before / 1GB), $VhdPath)

Log "wsl --shutdown"
wsl.exe --shutdown
Start-Sleep -Seconds 8

if (Get-Command Optimize-VHD -ErrorAction SilentlyContinue) {
    Log "Optimize-VHD -Mode Full"
    Optimize-VHD -Path $VhdPath -Mode Full
} else {
    Log "diskpart compact vdisk (Optimize-VHD not installed)"
    $dp = New-TemporaryFile
    @(
        "select vdisk file=`"$VhdPath`""
        "attach vdisk readonly"
        "compact vdisk"
        "detach vdisk"
    ) | Set-Content -Path $dp -Encoding ascii
    diskpart /s $dp | ForEach-Object { Add-Content -Path $log -Value "  $_"; Write-Host $_ }
    Remove-Item $dp
}

$after = (Get-Item $VhdPath).Length
Log ("{0}: {1:N1} GB after compaction (freed {2:N1} GB)" -f $Distro, ($after / 1GB), (($before - $after) / 1GB))

if ($Sparse) {
    Log "wsl --manage $Distro --set-sparse true"
    $out = wsl.exe --manage $Distro --set-sparse true 2>&1
    $out | ForEach-Object { Log "  $_" }
}
Log "done — start WSL again normally"
