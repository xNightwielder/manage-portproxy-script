# Manage PortProxy Script

## Description
This script, managing port proxy and permissions for inbound rules in the firewall on Windows operating systems. It creates port forwarding rules for the specified target IP and port list. Also it creates Inbound Rule on firewall for every forwarding ports and allows to accessing ports. It can delete rules created with the "Remove" parameter. The script should be run with administrator privileges.

## Parameters
### Action
The action to be taken. 'Add' (For Adding) or 'Remove' (For Deleting)

### Target IP
The ip address of the target machine to which the ports will be forwarded.

### Ports
The action to be taken of ports list.

## Usage
### Example Usage Case: 
Add rules for ports 80, 443 and 8080 to the 192.168.1.100 IP address
```
   .\\Manage-PortProxy.ps1 -Action Add -TargetIP 192.168.1.100 -Ports 80,443,8080
```

Remove rules for ports 80, 443 and 8080 to the 192.168.1.100 IP address
```
   .\\Manage-PortProxy.ps1 -Action Remove -TargetIP 192.168.1.100 -Ports 80,443,8080
```



