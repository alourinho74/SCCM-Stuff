$HKLM = [UInt32] "0x80000002"
    $wmiRegistry = [WMIClass] "\\.\root\default:StdRegProv"

$RegistryWUAU = $wmiRegistry.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
$RegistryWUAU.sNames

$RegistryWUAU = $wmiRegistry.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")


    if ($RegistryWUAU.sNames -contains "RebootRequired") {
        Write-Host "Windows Update have a reboot required"
        $PendingReboot = $true
    }
    else
    {
        Write-Host "nope"
    }