$cmd = 'winmgmt /salvagerepository'
invoke-expression -command "$cmd"

Set-Service winmgmt -startuptype "Disabled"

try
{
    Stop-Service -Name "winmgmt" -Force
    WaitUntilServices "winmgmt" "Stopped" 
    $aux_wmi = 1
    Start-Sleep -Seconds 5
}
catch
{
$linha = "WMI Service failed to stop"
        $aux_wmi = 0
}


if ($aux_wmi -eq 1)
{
    $cmd = 'winmgmt /resetrepository'
    invoke-expression -command "$cmd"

    Set-Service winmgmt -startuptype "Automatic"
}

try
{
	(Get-WmiObject  -Class Win32_Service -Filter "Name='winmgmt'").StartService()
    $aux_wmi = 1 
    WaitUntilServices "winmgmt" "Running" 
}
catch
{
	$linha = "WMI Service failed to start"
    $aux_wmi = 0
}

$Dir = get-childitem "C:\Windows\System32\Wbem" | where {$_.extension -eq ".dll"} 

foreach ($dll in $dir)
{
	$cmd = "cmd /C C:\Windows\System32\regsvr32 /s " + $dll
    invoke-expression -command "$cmd"
}

$cmd = "cmd /C C:\Windows\System32\wbem\wmiprvse /regserver"
invoke-expression -command "$cmd"

try
{
    (Get-WmiObject  -Class Win32_Service -Filter "Name='winmgmt'").StartService()
    $aux_wmi = 1 
    WaitUntilServices "winmgmt" "Running" 
}
catch
{
    $aux_wmi = 0
}

$Dir = get-childitem "C:\Windows\System32\Wbem" | where {$_.extension -eq ".mof"} 

foreach ($mof in $dir)
{
    $cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + "c:\windows\system32\wbem\" + $mof
    invoke-expression -command "$cmd"
}

$cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + "c:\windows\system32\wbem\win32_encryptablevolume.mof"
invoke-expression -command "$cmd"

try
{
	(Get-WmiObject -Class Win32_Service -Filter "Name='wuauserv'").StopService()
    WaitUntilServices "wuauserv" "Stopped"
    Start-Sleep -s 15
    $aux = 1     
}
catch
{
    $aux = 0
}

if ($aux -eq 1)
{
    Write-Host "Deleting C:\Windows\SoftwareDistribution"
    Remove-Item -path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ea SilentlyContinue
    Start-Sleep -s 5
}

#####

$proc_mem = Get-Process ccmexec -ErrorAction SilentlyContinue

if ($proc_mem)
{
    Write-Host "Terminating ccmexec.exe process"
	$ccmid = (get-process ccmexec).id
    stop-process -id $ccmid -Force -ErrorAction SilentlyContinue
    wait-process -id $ccmid -Timeout 10
}
        
if (Test-Path "C:\Windows\ccmsetup\ccmsetup.exe")
{
    Write-Host "Uninstalling SCCM Agent"
    $cmd = 'cmd /C C:\Windows\ccmsetup\ccmsetup.exe /uninstall'
    invoke-expression -command "$cmd"
}

try
{
    Remove-Item "c:\windows\ccmsetup\*" -Recurse -Force -ea SilentlyContinue
    Remove-Item "c:\windows\smscfg.ini" -Recurse -Force -ea SilentlyContinue
}
catch
{
}

$cert = Get-ChildItem "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\19c5cf9*"

Write-Host "Delete certificate files"
foreach ($i in $cert)
{
        #write-host $i
    $i |%{$_.Delete()}
}

$cmd = "cmd /C C:\Windows\temp\Reinstall_Agent\Aux_Files\ccmdelcert.exe"
invoke-expression -command "$cmd"

write-host "Executing ccmclean"
$cmd = "cmd /C C:\Windows\temp\Reinstall_Agent\Aux_Files\ccmclean.exe /q /logdir:c:\Windows\temp\uninst_sms.log"
invoke-expression -command "$cmd"

Write-Host "Deleting Registry Keys"
if (Test-Path -Path "c:\Program Files (x86)")
{
    try
    {
		reg delete "HKLM\SOFTWARE\Microsoft\SMS\" /f /reg:64
    }
    catch [system.exception]
    {
    }
}
else
{
    try
    {
		reg delete "HKLM\SOFTWARE\Microsoft\SMS"
    }
    catch [system.exception]
    { 
    }
}

Start-Sleep -Seconds (5)