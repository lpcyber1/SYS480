<#
Powershell module written by Liam Paul for SYS480
#>

# Importing variables from another file


# Function to connect to a vCenter server
function ConnectTovCenter(){
    # Connects to the vCenter server, this will prompt for a password
    Connect-VIServer -Server $config.vcenter
}

# Function to create a Linked Clone of a VM
function CreateLinkedClone(){
    # Retrieves all virtual machines in the environment
    $VMs = Get-VM
    
    # Filters VMs that have a snapshot named "Base"
    $VMsWithBaseSnapshot = $VMs | Where-Object { $_ | Get-Snapshot | Where-Object {$_.Name -eq "Base"}}
    
    # Prints information about VMs with the "Base" snapshot
    Write-Host "======================================================="
    Write-Host "The VMs listed have a base snapshot ready to be cloned"
    Write-Host "======================================================="
    Write-Host $VMsWithBaseSnapshot
    Write-Host "======================================================="

    # Prompts the user to select a VM to clone and provides the name for the new VM
    $VMtoClone = Read-Host "Enter the name of the VM to be cloned"
    $New = Read-Host "Enter the name of the new VM"
    
    # Retrieves the "Base" snapshot from the selected VM
    $snapshot = (Get-Snapshot -VM (Get-VM -Name $VMtoClone) -Name "Base") 
    
    # Outputs the creation process of the new VM to the console
    Write-Host "Creating new vm:" $New -ForegroundColor Green

    # Creates the new linked clone using the reference snapshot
    New-VM -LinkedClone -Name $New -VM $VMtoClone -ReferenceSnapshot $snapshot -VMHost $config.vmserver -Datastore $config.datastore
    
    # Confirms the creation of the new VM
    Write-Host "Created" $New -ForegroundColor Green
}

# Function to create a full clone of a VM
function CreateFullClone(){
    # Retrieves all virtual machines in the environment
    $VMs = Get-VM
    
    # Filters VMs that have a snapshot named "Base"
    $VMsWithBaseSnapshot = $VMs | Where-Object { $_ | Get-Snapshot | Where-Object {$_.Name -eq "Base"}}
    
    # Prints information about VMs with the "Base" snapshot
    Write-Host "======================================================="
    Write-Host "The VMs listed have a base snapshot ready to be cloned"
    Write-Host "======================================================="
    Write-Host $VMsWithBaseSnapshot
    Write-Host "======================================================="

    # Prompts the user to select a VM to clone and provides the name for the new VM
    $VMtoClone = Read-Host "Enter the name of the VM to be cloned"
    $New = Read-Host "Enter the name of the new VM"
    
    # Retrieves the "Base" snapshot from the selected VM
    $snapshot = (Get-Snapshot -VM (Get-VM -Name $VMtoClone) -Name "Base") 
    
    # Outputs the creation process of the new VM to the console
    Write-Host "Creating new vm:" $New -ForegroundColor Green

    # Creates the new full clone using the reference snapshot
    New-VM -Name $New -VM $VMtoClone -VMHost $config.vmserver -Datastore $config.datastore
    
    # Confirms the creation of the new VM
    Write-Host "Created" $New -ForegroundColor Green
}

# Function to set the network for a VM
function SetVMNetwork(){
    # Retrieves all virtual machines in the environment
    $VMs = Get-VM
    Write-Host $VMs

    # Prompts the user to select a VM
    $SelectedVM = Read-Host "Enter the name of the VM"

    # Retrieves the network adapter of the selected VM
    $NetworkAdapter = Get-NetworkAdapter -VM $SelectedVM
    
    # Retrieves all available virtual networks
    $Networks = Get-VirtualNetwork

    # Displays the available networks to the user
    Write-Host "Available Networks"
    Write-Host $Networks

    # Prompts the user to select a network for the VM
    $SelectedNetwork = Read-Host "Enter the name of the network"
    
    # Sets the selected network for the network adapter of the VM
    Set-NetworkAdapter -NetworkAdapter $NetworkAdapter -NetworkName $SelectedNetwork
}

# Function to turn on a VM
function TurnOnVM(){
    # Retrieves all VMs that are powered off
    $VMsPoweredOff = Get-VM | Where-Object {$_.PowerState -eq "PoweredOff"}
    
    # Displays the VMs that are powered off
    Write-Host "VMs that are currently off:"
    Write-Host $VMsPoweredOff

    # Prompts the user to select a VM to power on
    $VMtoTurnON = Read-Host "Enter the name of the VM to power on" 

    # Starts the selected VM
    Start-VM -VM $VMtoTurnON
}

# Function to turn off a VM
function TurnOffVM(){
    # Retrieves all VMs that are powered on
    $VMsPoweredOn = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
    
    # Displays the VMs that are powered on
    Write-Host "VMs that are currently on:"
    Write-Host $VMsPoweredOn
    
    # Prompts the user to select a VM to power off
    $VMtoTurnOFF = Read-Host "Enter the name of the VM to power off"

    # Stops the selected VM
    Stop-VM -VM $VMtoTurnOFF
}

# Function to create a Virtual Switch and Portgroup
function NewNetwork(){
    # Asks for the name of new network
    $NewVirtualSwitch = Read-Host "Enter the name of the new virtual switch"

    # Creates new Virtual Switch
    New-VirtualSwitch -VMHost $config.vmserver -Name $NewVirtualSwitch

    # Asks for the name of the new port group 
    $NewPortGroup = Read-Host "Enter the name of the new port group on" $NewVirtualSwitch

    # Creates new Port Group
    New-VirtualPortGroup -VirtualSwitch $NewVirtualSwitch -Name $NewPortGroup

    Write-Host "Created new Virtual Switch" $NewVirtualSwitch "and Port Group" $NewPortGroup -ForegroundColor Green
}

function Get-IP {
    # Asks for the variable 
    $SelectVM = Read-Host "Enter the name of the VM"
    $VM = Get-VM -Name $SelectVM

    # Gets the network adapters for the VM and IP
    $networkadapters = Get-NetworkAdapter -VM $vm
    $IP = Get-VMGuest -VM $VM
    
    # Custom result I created to neatly display the results of the commands above
    $results = [PSCustomObject]@{
        "VM Name" = $VM
        "VM Network" = $networkadapters.NetworkName
        "MAC Address" = $networkadapters.MacAddress
        "IP Address" = $IP.IPAddress
    }
    
    # Returns the PSCustomObject to display results
    return $results
}

function Set-Windows-IP {
    # Asking for variables
    $SelectVM = Read-Host "Enter the name of the VM"
    $VM = Get-VM -Name $SelectVM

    $NewIP = Read-Host "Enter the new IP"
    $NewGateway = Read-Host "Enter the new Gateway IP"
    $NewNetmask = Read-Host "Enter the new Netmask"
    $NewNameserver = Read-Host "Enter the new Nameserver"
    $Interface = "Ethernet0"

    # Gets the Creds to the VM
    $Creds = Get-Credential

    # Script to run within the VM
    $Script = @"
netsh interface ip set address name=$Interface static $NewIP $NewNetmask $NewGateway 1
netsh interface ip set dns name=$Interface static $NewNameserver
"@

    # Runs the script within the VM
    Invoke-VMScript -VM $VM -ScriptText $Script -GuestCredential $Creds -ScriptType Bat

    Write-Host "IP Configuration applied successfully to:" $SelectVM

}