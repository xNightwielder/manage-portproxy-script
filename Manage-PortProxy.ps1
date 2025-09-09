
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Add', 'Remove')]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$TargetIP,

    [Parameter(Mandatory=$true)]
    [int[]]$Ports
)

$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script should run as an administrator. Please start PowerShell as an Administrator."
    exit
}

foreach ($port in $Ports) {
    $ruleName = "PortProxy ($port -> $TargetIP)"

    if ($Action -eq 'Add') {
        try {
            Write-Host "Adding a PortProxy Rule: Listening Port $port -> Destination $TargetIP : $port" -ForegroundColor Cyan
            netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$TargetIP
            Write-Host "[SUCCESSFUL] PortProxy rule has been added." -ForegroundColor Green
        }
        catch {
            Write-Error "An error occurred while adding the PortProxy rule: $_"
        }

        # --- Güvenlik Duvarı Kuralı Ekleme ---
        try {
            Write-Host "Adding a Firewall Rule: '$ruleName'" -ForegroundColor Cyan
            if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
                Write-Warning "There is already a firewall rule with this name: '$ruleName'"
            }
            else {
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
                Write-Host "[SUCCESSFUL] Firewall rule has been added." -ForegroundColor Green
            }
        }
        catch {
            Write-Error "An error occurred while adding the Firewall rule: $_"
        }
    }
    elseif ($Action -eq 'Remove') {
        try {
            Write-Host "Deleting PortProxy Rule: Listening Port $port" -ForegroundColor Yellow
            netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0
            Write-Host "[SUCCESSFUL] PortProxy rule has beed deleted." -ForegroundColor Green
        }
        catch {
            Write-Error "An error occurred while deleting the portproxy rule: $_"
        }

        # --- Güvenlik Duvarı Kuralını Silme ---
        try {
            Write-Host "Deleting Firewall Rule: '$ruleName'" -ForegroundColor Yellow
            Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            Write-Host "[SUCCESSFUL] Firewall rule has been deleted." -ForegroundColor Green
        }
        catch {
            Write-Error "An error occurred while deleting the firewall rule: $_"
        }
    }
    Write-Host "--------------------------------------------------"
}

Write-Host "The process is complete." -ForegroundColor Magenta