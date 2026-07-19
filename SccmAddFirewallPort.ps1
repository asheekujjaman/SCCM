<#
.SYNOPSIS
    Add SCCM Client Firewall Rules (Inbound + Outbound)

.DESCRIPTION
    Creates Windows Firewall rules for SCCM client communication.

    Ports:
    80   - SCCM MP HTTP
    443  - SCCM MP HTTPS
    445  - SMB Client Installation
    8530 - WSUS/SUP HTTP
    8531 - WSUS/SUP HTTPS
    10123- SCCM Client Notification

    Run as Administrator
#>

# Require Administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Run PowerShell as Administrator" -ForegroundColor Red
    exit
}


# SCCM ports
$Ports = @(
    80,
    443,
    445,
    8530,
    8531,
    10123
)


foreach ($Port in $Ports) {

    # Inbound Rule
    $InboundName = "SCCM Client Inbound TCP Port $Port"

    if (-not (Get-NetFirewallRule -DisplayName $InboundName -ErrorAction SilentlyContinue)) {

        New-NetFirewallRule `
            -DisplayName $InboundName `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $Port `
            -Action Allow `
            -Profile Domain,Private,Public

        Write-Host "Created inbound rule: $Port" -ForegroundColor Green
    }
    else {
        Write-Host "Inbound rule exists: $Port" -ForegroundColor Yellow
    }


    # Outbound Rule
    $OutboundName = "SCCM Client Outbound TCP Port $Port"

    if (-not (Get-NetFirewallRule -DisplayName $OutboundName -ErrorAction SilentlyContinue)) {

        New-NetFirewallRule `
            -DisplayName $OutboundName `
            -Direction Outbound `
            -Protocol TCP `
            -RemotePort $Port `
            -Action Allow `
            -Profile Domain,Private,Public

        Write-Host "Created outbound rule: $Port" -ForegroundColor Green
    }
    else {
        Write-Host "Outbound rule exists: $Port" -ForegroundColor Yellow
    }
}


Write-Host ""
Write-Host "SCCM Firewall Rules Completed" -ForegroundColor Cyan


# Display created rules
Get-NetFirewallRule |
Where-Object {$_.DisplayName -like "SCCM Client*"} |
Select-Object DisplayName,Enabled,Direction,Action