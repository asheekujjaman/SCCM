# =====================================================================
# Configuration Manager (SCCM) Client Complete Cleanup Script
# Run as Administrator
# =====================================================================

Write-Host "Starting Configuration Manager Client Cleanup..." -ForegroundColor Cyan

# Stop on non-terminating errors where appropriate
$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------
# Run official uninstall
# ---------------------------------------------------------------------

$CCMSetup = "$env:windir\ccmsetup\ccmsetup.exe"

if (Test-Path $CCMSetup) {
    Write-Host "Running official SCCM uninstall..."
    Start-Process -FilePath $CCMSetup -ArgumentList "/uninstall" -Wait
}
else {
    Write-Host "ccmsetup.exe not found. Continuing cleanup..."
}

Start-Sleep -Seconds 10

# ---------------------------------------------------------------------
# Stop SCCM Services
# ---------------------------------------------------------------------

$Services = @(
    "CcmExec",
    "ccmsetup",
    "smstsmgr",
    "CmRcService"
)

foreach ($Service in $Services) {
    try {
        if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
            Stop-Service $Service -Force -ErrorAction SilentlyContinue
        }
    }
    catch {}
}

Start-Sleep -Seconds 5

# ---------------------------------------------------------------------
# Kill remaining SCCM processes
# ---------------------------------------------------------------------

$Processes = @(
    "CcmExec",
    "ccmsetup",
    "SCNotification",
    "CmRcService"
)

foreach ($Process in $Processes) {
    Get-Process $Process -ErrorAction SilentlyContinue | Stop-Process -Force
}

# ---------------------------------------------------------------------
# Remove WMI Namespaces
# ---------------------------------------------------------------------

Write-Host "Removing WMI namespaces..."

try {
    Get-CimInstance -Namespace root -ClassName __Namespace |
        Where-Object Name -eq "ccm" |
        Remove-CimInstance
}
catch {}

try {
    Get-CimInstance -Namespace root\cimv2 -ClassName __Namespace |
        Where-Object Name -eq "sms" |
        Remove-CimInstance
}
catch {}

# ---------------------------------------------------------------------
# Remove Registry Keys
# ---------------------------------------------------------------------

Write-Host "Removing registry keys..."

$RegistryKeys = @(
    "HKLM:\SOFTWARE\Microsoft\CCM",
    "HKLM:\SOFTWARE\Microsoft\CCMSetup",
    "HKLM:\SOFTWARE\Microsoft\SMS",

    "HKLM:\SYSTEM\CurrentControlSet\Services\CcmExec",
    "HKLM:\SYSTEM\CurrentControlSet\Services\CCMSetup",
    "HKLM:\SYSTEM\CurrentControlSet\Services\CmRcService",
    "HKLM:\SYSTEM\CurrentControlSet\Services\smstsmgr"
)

foreach ($Key in $RegistryKeys) {
    if (Test-Path $Key) {
        Remove-Item $Key -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------
# Remove SMS Certificates
# ---------------------------------------------------------------------

Write-Host "Removing SMS certificates..."

try {
    Get-ChildItem Cert:\LocalMachine\SMS -ErrorAction SilentlyContinue |
        Remove-Item -Force -Recurse
}
catch {}

# ---------------------------------------------------------------------
# Remove Scheduled Tasks
# ---------------------------------------------------------------------

Write-Host "Removing scheduled tasks..."

Get-ScheduledTask -ErrorAction SilentlyContinue |
Where-Object {
    $_.TaskName -like "*Configuration Manager*" -or
    $_.TaskName -like "*CCM*" -or
    $_.TaskName -like "*SMS*"
} |
ForEach-Object {
    try {
        Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false
    }
    catch {}
}

# ---------------------------------------------------------------------
# Remove Folders
# ---------------------------------------------------------------------

Write-Host "Removing folders..."

$Folders = @(
    "$env:windir\CCM",
    "$env:windir\ccmsetup",
    "$env:windir\ccmcache"
)

foreach ($Folder in $Folders) {
    if (Test-Path $Folder) {
        Remove-Item $Folder -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------
# Remove Files
# ---------------------------------------------------------------------

Write-Host "Removing remaining files..."

$Files = @(
    "$env:windir\SMSCFG.ini"
)

foreach ($File in $Files) {
    if (Test-Path $File) {
        Remove-Item $File -Force -ErrorAction SilentlyContinue
    }
}

Get-ChildItem "$env:windir" -Filter "SMS*.mif" -ErrorAction SilentlyContinue |
Remove-Item -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------
# Remove SCCM Environment Variables
# ---------------------------------------------------------------------

[Environment]::SetEnvironmentVariable("_SMSTSCurrentActionName",$null,"Machine")
[Environment]::SetEnvironmentVariable("_SMSTSMachineName",$null,"Machine")

# ---------------------------------------------------------------------
# Reset Windows Management Instrumentation (Optional)
# ---------------------------------------------------------------------

Write-Host "Verifying WMI repository..."

try {
    winmgmt /verifyrepository | Out-Null
}
catch {}

# ---------------------------------------------------------------------
# Finished
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " SCCM Client cleanup completed." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "RECOMMENDED NEXT STEPS:"
Write-Host "1. Restart the computer."
Write-Host "2. Verify C:\Windows\CCM no longer exists."
Write-Host "3. Verify the SMSCFG.ini file has been removed."
Write-Host "4. Reinstall the SCCM client."