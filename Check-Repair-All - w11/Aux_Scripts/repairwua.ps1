Write-Host $env:computername
$host.ui.RawUI.WindowTitle = $env:computername

Function stop_service
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]$ServiceName
        )
            $ServiceStat = Get-Service -Name $ServiceName
            Write-Host "Stoping service $ServiceName" -ForegroundColor "White"
            try {

                $ServiceStat = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
                $ServiceStat | Stop-Service -Force
                Write-Host "Service $($ServiceName) stopped" -ForegroundColor "White"
            }
            catch {
                Write-Host "Problems stopping service $($ServiceName)" -ForegroundColor "Red"
            }
           

}

Function start_services
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]$ServiceName
        )
    
        
    Write-Host "Starting service $($ServiceName)" -ForegroundColor "White"
    try {
        $ServiceStat = Get-Service -Name $ServiceName
        $ServiceStat | start-Service
        Write-Host "Service $($ServiceName) started" -ForegroundColor "White" 
    }
    catch {
        Write-Host "Problems starting service $($ServiceName)" -ForegroundColor "Red"
    }

        


}

stop_service "Sms Agent Host"
stop_service "Background Intelligent Transfer Service"
stop_service "Windows Update"
stop_service "Application Identity"
stop_service "Cryptographic Services"


Write-Host "Delete C:\Windows\SoftwareDistribution" -ForegroundColor Cyan
& cmd /c rmdir "C:\Windows\SoftwareDistribution\Download" /s /q
#Remove-Item -Path "C:\Windows\SoftwareDistribution\Download" -Recurse -Force
Get-ChildItem "C:\Windows\SoftwareDistribution" -Include *.* -Recurse | Remove-Item -Force -Recurse
Remove-Item -path "C:\Windows\SoftwareDistribution" -Recurse -Force -ea Continue

Write-Host "----Rename Catroot2----"  -ForegroundColor Cyan
$renname = "C:\windows\system32\catroot2.old"
if (Test-Path -Path $renname )
{
    Get-ChildItem $renname -Include *.* -Recurse | Remove-Item -Force -Recurse
    Remove-Item -path $renname -Force -Recurse -ea Continue

}
Rename-Item -path "C:\windows\system32\catroot2" -NewName "C:\windows\system32\catroot2.old" -Force


Write-Host "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ForegroundColor Cyan
Remove-Item -path "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction Continue


Write-Host "----Set Permissions----" -ForegroundColor Cyan
$cmd = "sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
invoke-expression -command $cmd
$cmd = "sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
invoke-expression -command $cmd


Write-Host "Register some dll's" -ForegroundColor Cyan

$somedlls = @("atl.dll","urlmon.dll","mshtml.dll","shdocvw.dll","browseui.dll","jscript.dll","vbscript.dll","scrrun.dll","msxml.dll","msxml3.dll","msxml6.dll","actxprxy.dll","softpub.dll","wintrust.dll","dssenh.dll","rsaenh.dll","gpkcsp.dll",
"sccbase.dll","slbcsp.dll","cryptdlg.dll","oleaut32.dll","ole32.dll","shell32.dll","initpki.dll","wuapi.dll","wuaueng.dll","wuaueng1.dll","wucltui.dll","wups.dll","wups2.dll","wuweb.dll","qmgr.dll","qmgrprxy.dll","wucltux.dll","muweb.dll","wuwebv.dll")

foreach ($dll in $somedlls)
{
    write-host "Registring $($dll)"
    $cmd = "C:\Windows\System32\regsvr32 /s " + "c:\windows\system32\" + $dll
    invoke-expression -command "$cmd"

}


start_services "Application Identity"
start_services "Cryptographic Services"


Write-Host "----WMI Repair----" -ForegroundColor Cyan
$cmd = "winmgmt /salvagerepository "
invoke-expression -command "$cmd"

Write-Host "Disable and stop WMI Service" -ForegroundColor "White"
try
{
    $servicestatus = Get-Service -Name "Windows Management Instrumentation"
    $servicestatus | Set-Service -startuptype Disabled
    $servicestatus | Stop-Service -Force    
}
catch {
    Write-Host "Error stopping WMI service" -ForegroundColor Red
}

Write-Host "Reset WMI Repository" -ForegroundColor Cyan
$cmd = "winmgmt /resetrepository"
invoke-expression -command "$cmd"

Write-Host "Enabling and starting WMI Service" -ForegroundColor Cyan
try
{
    $servicestatus = Get-Service -Name "Windows Management Instrumentation"
    $servicestatus | Set-Service -startuptype Automatic -Status Running -PassThru
    $servicestatus |  Start-Service    
}
catch {
    Write-Host "Error stopping WMI service" -ForegroundColor Red
}

Write-Host "Compiling wbem ddl's"  -ForegroundColor Cyan
$Dir = get-childitem "C:\Windows\System32\Wbem" | Where-Object {$_.extension -eq ".dll"} 

foreach ($dll in $dir)
{
    #write-host "Registring $($dll)"
    $cmd = "C:\Windows\System32\regsvr32 /s " + "c:\windows\system32\wbem\" + $dll
    invoke-expression -command "$cmd"

}

$cmd = "wmiprvse /regserver "
invoke-expression -command "$cmd"

Write-Host "Enabling and starting WMI Service" -ForegroundColor "White"
try
{
    $servicestatus = Get-Service -Name "Windows Management Instrumentation"
    $servicestatus | Set-Service -startuptype Automatic
    $servicestatus |  Start-Service    
}
catch {
    Write-Host "Error stopping WMI service" -ForegroundColor Red
}


Write-Host "Compiling wbem mof's"  -ForegroundColor Red
$Dir = get-childitem "C:\Windows\System32\Wbem" | Where-Object {$_.extension -eq ".mof" -or $_.extension -eq ".mfl"} 

foreach ($mof in $dir)
{
    #Write-Host "Registring $($mof)"
    #$cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + "c:\windows\system32\wbem\" + $mof
    $cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + "c:\windows\system32\wbem\" + $mof
    invoke-expression -command "$cmd"
}

$cmd = "mofcomp.exe c:\windows\system32\wbem\win32_encryptablevolume.mof"
invoke-expression -command "$cmd"

$cmd = "DISM /Online /Cleanup-Image /RestoreHealth"
invoke-expression -command "$cmd"

$cmd = "sfc /scannow"
invoke-expression -command "$cmd"

start_services "Sms Agent Host"

read-host "---- END ----"

