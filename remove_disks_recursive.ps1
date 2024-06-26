function Has-USB-Parent($deviceID) {
    $parentDeviceId = (Get-PnpDeviceProperty -InstanceId $deviceID -KeyName DEVPKEY_Device_Parent).Data
    if ($parentDeviceId -eq $null) { return $false }
    $parentDevice = Get-PnpDevice | Where-Object { $_.InstanceId -eq $parentDeviceID }
    if ($parentDevice.Class -eq "USB") {
        return $true
    } else {
        return Has-USB-Parent($parentDeviceId)
    }
}

$debugging = $true
# Filter and output disk drives connected via USB and internally
Get-PnpDevice | Where-Object { $_.Class -eq "DiskDrive" } | ForEach-Object {
    $diskDrive = $_
    $deviceID = $diskDrive.InstanceId
    $USBParent = Has-USB-Parent $deviceID

    # Outputs all DiskDrives (including non-usb devices) currently on the system
    if ($debugging) {
        [PSCustomObject]@{
            DeviceID = $deviceID
            USBAttached = $USBParent
            Present = $diskDrive.Present
        }
    # Deletes device DiskDrive USB devices that aren't currently connected
    } else {
        if ($USBParent -and $diskDrive.Present -eq $false) {
            Write-Host "Deleting "$deviceID" Parent: "$ParentClass
            $command = "pnputil /remove-device '" + $deviceID + "'"
            Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$command`"" -Verb RunAs
        } else {
            Write-Host "Keeping "$deviceID" Parent: "$ParentClass
        }
    }
}
