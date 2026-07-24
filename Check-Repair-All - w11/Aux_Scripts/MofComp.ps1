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

$Dir = get-childitem "c:\program files\Microsoft Policy Platform" | Where-Object {$_.extension -eq ".dll"} 
Write-Host $Dir


foreach ($dll in $dir)
{
	$cmd = "cmd /C C:\Windows\System32\regsvr32 /s " + $dll
    invoke-expression -command "$cmd"
}

$Dir = get-childitem "c:\program files\Microsoft Policy Platform" | Where-Object {$_.extension -eq ".mof"} 
Write-Host $Dir
foreach ($mof in $dir)
{
    #$cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + "c:\windows\system32\wbem\" + $mof
    #invoke-expression -command "$cmd"
	$cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + """c:\program files\Microsoft Policy Platform\" + $mof + """"
    invoke-expression -command "$cmd"
}

$Dir = get-childitem "c:\program files\Microsoft Policy Platform" | Where-Object {$_.extension -eq ".mfl"} 

foreach ($mfl in $dir)
{
    #$cmd = "cmd /C C:\Windows\System32\mofcomp " + $mfl
    $cmd = "cmd /C C:\Windows\System32\wbem\mofcomp.exe " + "c:\program files\Microsoft Policy Platform\" + $mfl
    invoke-expression -command "$cmd"
}

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

#$cmd = "cmd /C c:\windows\temp\reinstall_agent\aux_files\ccmsetup.exe /mp:PKPSCC07,CKPSCC05 /AllowMetered SMSSITECODE=CB1 CCMLOGMAXSIZE=500000 /UsePKICert /NoCRLCheck CCMHOSTNAME=sccmcb.telecom.pt CCMCERTSEL=SubjectStr:corpPT.com " + $mfl
#invoke-expression -command "$cmd"
