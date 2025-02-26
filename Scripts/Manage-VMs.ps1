 <#
This script was writen by Liam Paul for SYS480
Its intended purpose is manage VMs in vCenter
#>
function ConnectTovCenter {
    # Runs the simple command pointed at my vCenter server, this will prompt a username and password to be entered
    Connect-VIServer -Server "vcenter.liam.local"
}

function CheckvCenterConnection {
    Clear-Host
    # Writes into the terminal the current vCenter server it is connected to and what user is connected
    Write-Host "Connected to" $global:defaultviserver "as" $global:defaultviserver.user 
}

function CreateLinkedClone {
    # Gets all VMs in my environment.
    $VMs = Get-VM
    
    # Filters down to VMs with a "Base" snapshot
    $VMsWithBaseSnapshot = $VMs | Where-Object { $_ | Get-Snapshot | Where-Object {$_.Name -eq "Base"}}
    

    Write-Host "======================================================="
    Write-Host "The VMs listed have a base snapshot ready to be cloned"

    # Enumerates the VMs that have a snapshot named "Base"
    Write-Host "======================================================="
    Write-Host $VMsWithBaseSnapshot
    Write-Host "======================================================="

    $VMtoClone = Read-Host "Enter the name of the VM to be cloned"
    $New = Read-Host "Enter the name of the new VM"
    $snapshot = (Get-Snapshot -VM (Get-VM -Name $VMtoClone) -Name "Base") 
    $vmserver = "super21.liam.local"
    $vmnetwork = "480-WAN"
    $datastore = "datastore2"

    Write-Host "Creating new vm:" $New -ForegroundColor Green

    # Creates new linked clone
    New-VM -LinkedClone -Name $New -VM $VMtoClone -ReferenceSnapshot $snapshot -VMHost $vmserver -Datastore $datastore
    
    Write-Host "Created" $New -ForegroundColor Green

    Start-Sleep -Seconds 1
    
}

# Print a menu to show users the features the script has
while ($true) {
    # Show menu options
    Write-Host "============================="
    Write-Host "Menu:"
    Write-Host "1. Connect to vCenter"
    Write-Host "2. Check vCenter connection"
    Write-Host "3. Create a linked clone"
    Write-Host "4. Quit"
    Write-Host "============================="

    # Asks for users choice
    $choice = Read-Host "Select an option (1-4)"

    # Takes input and runs the function selected
    switch ($choice) {
        1 { Write-Host "Connecting to vCenter..."; Clear-Host; ConnectTovCenter }
        2 { Write-Host "Checking vCenter connection..."; Clear-Host; CheckvCenterConnection }
        3 { Write-Host "Creating linked clone..."; Clear-Host; CreateLinkedClone }
        4 { Write-Host "Quiting..."; Start-Sleep -Seconds 0.5; Clear-Host; exit }
        default { Write-Host "Invalid option, try again"; Clear-host; pause }
    }

}