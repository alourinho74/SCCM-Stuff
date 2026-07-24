. ".\Source\Aux_Functions.ps1"
. ".\Source\variables.ps1"
. ".\Source\userstuff.ps1"
. ".\Source\sccm_stuff.ps1"
. ".\Source\Win_Updates.ps1"
. ".\Source\Disk.ps1"
. ".\Source\feature_updates.ps1"
. ".\Source\repair.ps1"
. ".\Source\bits.ps1"
. ".\Source\LogFiles.ps1"
. ".\Source\Parse_inf.ps1"

if ( $ARGS[0] ) 
{
    $ComputerName = $ARGS[0]
}
else
{
    $ComputerName = Read-Host -Prompt 'Hostname'  
}

$restart_ccm_wua = $false

$host_online = check_online

if ($host_online -eq $true)
{
    $dcomoption = New-CimSessionOption -Protocol Dcom
    $cimsession = New-CimSession -ComputerName $ComputerName -SessionOption $dcomoption
    $logfile = New-Item -Path "\\$ComputerName\c$\windows\temp\Recover_w10.log" -ItemType "file" -Force

    reverse_dns $ComputerName
}


Dolog -Message " " -LogLevel 1 -color "White"
Dolog -Message "SCCM Agent Info" -LogLevel 1 -color "Cyan"

get_client_Settings
   
While( -not ( ($verify_monthly = (Read-Host "Debug Monthly Updates Issues (y/n)?")) -match "y|n")){}
if ($verify_monthly -eq "Y" -or $verify_monthly -eq "y")
{
    $verify_monthly = $true
}

While( -not ( ($verify_fu = (Read-Host "Check Windows 10 Feature Upgrade (y/n)?")) -match "y|n")){}
if ($verify_fu -eq "Y" -or $verify_fu -eq "y")
{
    $verify_fu = $true
}

While( -not ( ($chkdsk = (Read-Host "CheckDisk (y/n)?")) -match "y|n")){}
if ($chkdsk -eq "Y" -or $chkdsk -eq "y")
{
    $chkdsk = $true
}

While( -not ( ($userinfo = (Read-Host "Get User Info (y/n)?")) -match "y|n")){}
if ($userinfo -eq "Y" -or $userinfo -eq "y")
{
    $userinfo = $true
}

if ($verify_monthly -ne $true)
{
    While( -not ( ($ComputerInfo = (Read-Host "Get Computer Info (y/n)?")) -match "y|n")){}
    if ($ComputerInfo -eq "Y" -or $ComputerInfo -eq "y")
    {
        $ComputerInfo = $true

    }
}
else 
{
    $ComputerInfo = $true   
}

if ($chkdsk -eq "Y" -or $chkdsk -eq "y")
{
    Dolog -Message "Check Disk Running" -LogLevel 1 -color "White"
    Check_Disk
}

if ($userinfo -eq "Y" -or $userinfo -eq "y")
{
    Dolog -Message " " -LogLevel 1 -color "White"
    Dolog -Message "User information" -LogLevel 1 -color "Cyan"
    GetUserInfo
}

if ($ComputerInfo -eq "Y" -or $ComputerInfo -eq "y")
{
    Dolog -Message " " -LogLevel 1 -color "White"
    Dolog -Message "Computer Info" -LogLevel 1 -color "Cyan"
    
    
    $os_data = check_os
<#
    if ($os_data.BuildNumber -le 26100)
    {
        Dolog -message " " -loglevel 1 -color "White"
        Dolog -message "Check VPN and Win11 Popups" -loglevel 1 -color "Cyan"

        $win11_count = "Count_w11_popup_24h2"
        $vpn_count = "Count-VPN-Msg-E88-62"

        $counter = Read_registry_popups $win11_count
        if ( $counter -eq "ERR")
        {
            Dolog -Message "$($win11_count) does not exists!" -color "Red" -LogLevel 3
        }
        else
        {
            Dolog -Message "Windows 11 popup run $($counter) times" -LogLevel 1 -color "White"
        }
        

        $counter = Read_registry_popups $vpn_count
        if ( $counter -eq "ERR")
        {
            Dolog -Message "$($vpn_count) does not exists!" -color "Red" -LogLevel 3
        }
        else
        {
            Dolog -Message "VPN popup run $($counter) times" -LogLevel 1 -color "White"
        }
    }
    #>
}

if ($verify_monthly -eq $true)
{
    cmtrace.exe "\\$ComputerName\c$\windows\ccm\logs\ccmexec.log" "\\$ComputerName\c$\windows\ccm\logs\PolicyAgent.log" "\\$ComputerName\c$\windows\ccm\logs\Execmgr.log" "\\$ComputerName\c$\windows\ccm\logs\WUAHandler.log" "\\$ComputerName\c$\windows\ccm\logs\UpdatesDeployment.log"   
    $aux_sup = get_sup
    $check_srv = check_bits

    if ($check_srv -eq $false)
    {
        repair_bits
    }

    Dolog -message " " -LogLevel 1 -color "White"
    Dolog -Message "Entering Monthly updates debug" -LogLevel 1 -color "Cyan"
    Dolog -Message " " -LogLevel 1 -color "White"    
    $wuahandler = "\\"+$ComputerName+"\c$\Windows\CCM\Logs\WUAHandler.log"

    
    #check_monthly_updates [string]$os_Data.BuildNumber [string]$os_Data.Caption
    check_monthly_updates $os_Data.BuildNumber $os_Data.Caption

    Dolog -message " " -loglevel 1 -color "White"
    Dolog -message "Checking Windows Updates Logs for known errors..." -loglevel 1 -color "White"
    check_log_errorv2 $wuahandler "0x80240022","0x80240438","0x80240439", "0x80244022","Failed to Add Update Source for WUAgent of type (2)","0xc80003fd","0x80070422","0x80070020","0x80080005","Unable to read existing WUA Group Policy object. Error = 0x80004005","0xc80003fd","0x8007000d","0x80073712"
    
    
    if (($aux_sup.ContentLocation -eq "https://CKPSCC04.PTPORTUGAL.CORPPT.COM:8531") -or ($aux_sup.ContentLocation -eq "https://sccmcb.telecom.pt:8531"))
    {
        $restart_ccm_wua = $true
    }

    Dolog -message " " -loglevel 1 -color "White"

    if ($restart_ccm_wua -ne $true)
    {
        While( -not ( ($choice = (Read-Host "Restart <CCMExec> and <Windows Update Agent> Services (y/n)?")) -match "y|n")){}
        if ($choice -eq "Y" -or $choice -eq "y")
        {
            Dolog -Message "Restarting Services" -LogLevel 1 -color "White"
            Restart_Services
            Force_Trigger "{00000000-0000-0000-0000-000000000021}"
            Force_Trigger "{00000000-0000-0000-0000-000000000108}"
            Force_Trigger "{00000000-0000-0000-0000-000000000113}"
        }
    }
    
    if ($restart_ccm_wua -eq $true)
    {
        While( -not ( ($choice = (Read-Host "Force Scan (y/n)?")) -match "y|n")){}
        if ($choice -eq "Y" -or $choice -eq "y")
        {
            Dolog -Message "Forcing Updates Scan" -LogLevel 1 -color "White"
            Force_Trigger "{00000000-0000-0000-0000-000000000021}"
            Force_Trigger "{00000000-0000-0000-0000-000000000108}"
            Force_Trigger "{00000000-0000-0000-0000-000000000113}"
        }
        break
    }    
}

if ($verify_fu -eq $true)
{
    Dolog -message " " -loglevel 1 -color "White"
    Dolog -Message "Entering Feature Upgrade Debug" -LogLevel 1 -color "Cyan"

    #$os_data = check_os

    if ($os_data.BuildNumber -le 26100)
    {
        Dolog -message " " -loglevel 1 -color "White"
        Dolog -message "Check VPN and Win11 Popups" -loglevel 1 -color "Cyan"

        $win11_count = "Count_w11_popup_24h2"
        #$vpn_count = "Count-VPN-Msg-E88-62"
        $vpn_count = "Count-VPN-Msg-E88-63"

        $counter = Read_registry_popups $win11_count
        if ( $counter -eq "ERR")
        {
            Dolog -Message "$($win11_count) does not exists!" -color "Red" -LogLevel 3
        }
        else
        {
            Dolog -Message "Windows 11 popup run $($counter) times" -LogLevel 1 -color "White"
        }
        

        $counter = Read_registry_popups $vpn_count
        if ( $counter -eq "ERR")
        {
            Dolog -Message "$($vpn_count) does not exists!" -color "Red" -LogLevel 3
        }
        else
        {
            Dolog -Message "VPN popup run $($counter) times" -LogLevel 1 -color "White"
        }
    }



    Feature_update

    $setupactlog = "\\$ComputerName\" + 'c$\$WINDOWS.~BT\Sources\Panther\setupact.log'

    if (Test-Path $setupactlog)
    {
        $filesize = (Get-Item $setupactlog).Length/1MB
    
        if ($filesize -le 10)
        {
            cmtrace.exe "\\$ComputerName\c$\windows\ccm\logs\ccmexec.log" "\\$ComputerName\c$\windows\ccm\logs\PolicyAgent.log" "\\$ComputerName\c$\windows\ccm\logs\Execmgr.log" "\\$ComputerName\c$\windows\ccm\logs\WUAHandler.log" $setupactlog     
        }
        else 
        {
            cmtrace.exe "\\$ComputerName\c$\windows\ccm\logs\ccmexec.log" "\\$ComputerName\c$\windows\ccm\logs\PolicyAgent.log" "\\$ComputerName\c$\windows\ccm\logs\Execmgr.log" "\\$ComputerName\c$\windows\ccm\logs\WUAHandler.log" "\\$ComputerName\c$\windows\ccm\logs\UpdatesDeployment.log"          
        }
    }
    else 
    {
        cmtrace.exe "\\$ComputerName\c$\windows\ccm\logs\ccmexec.log" "\\$ComputerName\c$\windows\ccm\logs\PolicyAgent.log" "\\$ComputerName\c$\windows\ccm\logs\Execmgr.log" "\\$ComputerName\c$\windows\ccm\logs\WUAHandler.log" "\\$ComputerName\c$\windows\ccm\logs\UpdatesDeployment.log"      
    }

    Dolog -message " " -loglevel 1 -color "White"
    Dolog -message "Proceeding with possible repair action" -loglevel 1 -color "Cyan"
    While( -not ( ($choice = (Read-Host "Repair Windows Update Agent (y/n)?")) -match "y|n")){}
    
    if ($choice -eq "Y" -or $choice -eq "y")
    {
        Dolog -Message "Repair Windows Update Agent" -LogLevel 1 -color "White"
        Invoke-Command -FilePath Aux_Scripts\repairwua.ps1 -ArgumentList $ComputerName -ComputerName $ComputerName
    }

    While( -not ( ($choice = (Read-Host "Restart <CCMExec> and <Windows Update Agent> Services (y/n)?")) -match "y|n")){}
    if ($choice -eq "Y" -or $choice -eq "y")
    {
        Dolog -Message "Restarting Services" -LogLevel 1 -color "White"
        Restart_Services
    }

    While( -not ( ($choice = (Read-Host "Force Scan (y/n)?")) -match "y|n")){}
    if ($choice -eq "Y" -or $choice -eq "y")
    {
        Dolog -Message "Forcing Updates Scan" -LogLevel 1 -color "White"
        Force_Trigger "{00000000-0000-0000-0000-000000000108}"
        Force_Trigger "{00000000-0000-0000-0000-000000000113}"
    }
}



