<#
.SYNOPSIS
    Windows üzerinde Netsh PortProxy ve Güvenlik Duvarı kurallarını otomatik olarak ekler veya kaldırır.

.DESCRIPTION
    Bu script, belirtilen bir hedef IP adresine ve port listesine göre port yönlendirme (portproxy) kuralları oluşturur.
    Ayrıca, yönlendirilen her port için Windows Güvenlik Duvarı'nda bir "Gelen Kuralı" (Inbound Rule) oluşturarak
    bu portlara erişime izin verir. 'Remove' parametresi ile oluşturulan bu kuralları temizler.
    Script'in yönetici (Administrator) haklarıyla çalıştırılması gerekmektedir.

.PARAMETER Action
    Yapılacak işlem. 'Add' (eklemek için) veya 'Remove' (kaldırmak için).

.PARAMETER TargetIP
    Portların yönlendirileceği hedef makinenin IP adresi.

.PARAMETER Ports
    İşlem yapılacak portların listesi. Virgülle ayrılmış olarak girilmelidir (örn: 80,443,8080).

.EXAMPLE
    # 192.168.1.100 IP'sine 80, 443 ve 8080 portları için kuralları EKLEME
    .\Manage-PortProxy.ps1 -Action Add -TargetIP 192.168.1.100 -Ports 80,443,8080

.EXAMPLE
    # 80, 443 ve 8080 portları için daha önce oluşturulmuş kuralları KALDIRMA
    .\Manage-PortProxy.ps1 -Action Remove -TargetIP 192.168.1.100 -Ports 80,443,8080
#>
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