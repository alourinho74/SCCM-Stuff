Function stop_services
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]$ServiceName
        )
    
    $DoLogDef = ${function:DoLog}
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Set-Item Function:DoLog $Using:DoLogDef

        $timeout_seconds = 60
        Write-Host $using:ServiceName
        
        $ServiceStat = Get-Service -Name $using:ServiceName
        #Write-Host "Stoping service $using:ServiceName" -ForegroundColor "White"
        Dolog -message "Stoping service $using:ServiceName" -loglevel 1 -color "White" -access_type "local"
        $ServiceStat = Get-Service -Name $using:ServiceName -ErrorAction SilentlyContinue
        $ServiceStat | Stop-Service

        try 
        {
            $ServiceStat.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, $timeout_seconds)    
        }
        catch [ServiceProcess.TimeoutException]
        {
            #Write-Host "$using:ServiceName)took more than $timeout_seconds seconds to stop. Terminating process" -ForegroundColorr "Yellow"
            Dolog -message "$using:ServiceName)took more than $timeout_seconds seconds to stop. Terminating process" -loglevel 1 -color "Yellow" -access_type = "local"
                    #taskkill /IM ccmexec.exe /T /F 
            if ($using:ServiceName -like "sms*")
            {
                Stop-Process -Name "ccmexec.exe" -Force
            }
        }
    }
}

Function start_services
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]$ServiceName,
        [Parameter(Mandatory = $true)]
        [String]$ServiceStartupType
        )
    
    $DoLogDef = ${function:DoLog}

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Set-Item Function:DoLog $Using:DoLogDef
        Write-Host $using:ServiceName
        #read-host
        $ServiceStat = Get-Service -Name $using:ServiceName -ErrorAction SilentlyContinue
       
        $ServiceStat = Get-Service -Name $using:ServiceName
        if($ServiceStat)
        {
            if ($ServiceStat.Status -ne "Running")
            {
                $ServiceStat | Set-Service -startuptype $using:ServiceStartupType -Status Running -PassThru
                $txt = "Starting " + $using:ServiceName + " service on " + $using:ComputerName + " Service is now started"
                #Write-Host $txt -ForegroundColor "White"
                Dolog -message $txt -loglevel 1 -color "White" -access_type "local"
            }
            else
            {
                $ServiceStat | Restart-Service
                $txt = "ReStarting " + $using:ServiceName + " service on " + $using:ComputerName + " Service is now Restarted"
                #Write-Host $txt -ForegroundColor "White"
                Dolog -message $txt -loglevel 1 -color "White" -access_type "local"
            }
        }
        else
        {
            Write-Host "No $using:ServiceName service"  -ForegroundColor "Red"
            Dolog -message "No $using:ServiceName service" -loglevel 3 -color "Red" -access_type "local"
        }
    }
}

function wua_disable
{
<#
    stop_services "SMS Agent Host"
    stop_services "Windows Update"
    stop_services "Cryptographic Services"
    stop_services "Background Intelligent Transfer Service"
    stop_services "Application Identity"

    Read-Host "1"

    if (Test-Path "\\$ComputerName\C$\Windows\SoftwareDistribution\")
    {
        $linha =  "Deleting c:\Windows\SoftwareDistribution"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution\*" -Recurse -ea SilentlyContinue
        Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution" -Recurse -Force -ea SilentlyContinue
        Start-Sleep -s 5
    }

    if (Test-Path "\\$ComputerName\C$\Windows\System32\catroot2.old\")
    {
        $linha =  "Deleting old C:\Windows\System32\catroot2.old\"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\Windows\System32\catroot2.old\*" -Recurse -ea SilentlyContinue
        Remove-Item "\\$ComputerName\C$\Windows\System32\catroot2.old" -Recurse -Force -ea SilentlyContinue
        
        Start-Sleep -s 5
    }

    if (Test-Path "\\$ComputerName\C$\Windows\System32\catroot2\")
    {
        $linha =  "Renaming Windows\System32\catroot2\"
        dolog -message $linha -loglevel 1 -color "white"
        #Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution\*" -Recurse -ea SilentlyContinue
        #Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution" -Recurse -Force -ea SilentlyContinue
        Rename-Item -path "\\$ComputerName\C$\Windows\System32\catroot2" -newname "\\$ComputerName\C$\Windows\System32\catroot2.old"
        Start-Sleep -s 5
    }

    Read-Host "2"
    #>
    Copy-Item  .\Aux_Scripts\Recover_wua.cmd -Destination "\\$ComputerName\C$\Windows\Temp" -Force
    Read-Host "3"
    
    #psexec \\$ComputerName -d C:\Windows\Temp\Recover_wua.cmd 2>$null
    psexec \\$ComputerName -s C:\Windows\Temp\Recover_wua.cmd 2>$null
    Read-Host "4"
    start_services "SMS Agent Host" "Automatic"
    start_services "Windows Update" "Manual"
    start_services "Cryptographic Services" "Automatic"
    start_services "Background Intelligent Transfer Service" "Manual"
    start_services "Application Identity" "Manual"

    Read-Host "5"



    
}


Function update_policies
{
param 
(
    [Parameter(Mandatory = $true)]
    [Boolean]$startservices
    )
    #$ServiceSMS = "SMS Agent Host"
    #$ServiceWUA = "Windows Update"
    #$ServiceCryptSvc = "Cryptographic Services"
    Dolog -message "Stoping services" -loglevel 1 -color "White"
    stop_services "SMS Agent Host"
    stop_services "Windows Update"
    stop_services "Cryptographic Services"
    
   
    
    #$ServiceWUAStat = Get-Service -computername $ComputerName -Name $ServiceWUA -ErrorAction SilentlyContinue
    #$ServiceWUAStat | Stop-Service
    #$ServiceSMSStat = Get-Service -computername $ComputerName -Name $ServiceSMS -ErrorAction SilentlyContinue
    #$ServiceSMSStat | Stop-Service
    #$ServiceCryptSvcStat = Get-Service -computername $ComputerName -Name $ServiceCryptSvc -ErrorAction SilentlyContinue
    #$ServiceCryptSvcStat | Stop-Service

    
    if (Test-Path "\\$ComputerName\C$\Windows\System32\GroupPolicy")
    {
        $linha =  "deleting Windows\System32\GroupPolicy"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\Windows\System32\GroupPolicy\*" -Recurse -ea SilentlyContinue
        Start-Sleep -s 5
    }

    
    if (Test-Path "\\$ComputerName\C$\Windows\Security")
    {
        $linha =  "deleting Windows\Security"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\Windows\Security\*" -Recurse -ea SilentlyContinue
        Start-Sleep -s 5
    }
    
    if (Test-Path "\\$ComputerName\C$\ProgramData\Microsoft\Group Policy\")
    {
        $linha =  "deleting ProgramData\Microsoft\Group Policy\History"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\ProgramData\Microsoft\Group Policy\History\*" -Recurse -ea SilentlyContinue
        Start-Sleep -s 5
    }
    

    if (Test-Path "\\$ComputerName\C$\Windows\SoftwareDistribution\")
    {
        $linha =  "Deleting c:\Windows\SoftwareDistribution"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution\*" -Recurse -ea SilentlyContinue
        Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution" -Recurse -Force -ea SilentlyContinue
        Start-Sleep -s 5
    }

    if (Test-Path "\\$ComputerName\C$\Windows\System32\catroot2.old\")
    {
        $linha =  "Deleting old C:\Windows\System32\catroot2.old\"
        dolog -message $linha -loglevel 1 -color "white"
        Remove-Item "\\$ComputerName\C$\Windows\System32\catroot2.old\*" -Recurse -ea SilentlyContinue
        Remove-Item "\\$ComputerName\C$\Windows\System32\catroot2.old" -Recurse -Force -ea SilentlyContinue
        
        Start-Sleep -s 5
    }

    if (Test-Path "\\$ComputerName\C$\Windows\System32\catroot2\")
    {
        $linha =  "Renaming Windows\System32\catroot2\"
        dolog -message $linha -loglevel 1 -color "white"
        #Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution\*" -Recurse -ea SilentlyContinue
        #Remove-Item "\\$ComputerName\C$\Windows\SoftwareDistribution" -Recurse -Force -ea SilentlyContinue
        Rename-Item -path "\\$ComputerName\C$\Windows\System32\catroot2" -newname "\\$ComputerName\C$\Windows\System32\catroot2.old"
        Start-Sleep -s 5
    }
    
   
    Dolog -message "Updating policies.." -loglevel 1 -color "White"

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        gpupdate /force 2>$null
    }

    kill_proccess -proc_name "gpupdate" -waitseconds 15

    
    if ($startservices -eq $true)
    {

        start_services "SMS Agent Host" "Automatic"
        #start_services "Windows Update" "Manual"
        start_services "Cryptographic Services" "Automatic"
        #start_services "Background Intelligent Transfer Service" "Manual"
        #start_services "Application Identity" "Manual"
    <#

        Dolog -message "Starting Services" -loglevel 1 -color "White"
        $ServiceSMSStat = Get-Service -computername $ComputerName -Name $ServiceSMS -ErrorAction SilentlyContinue
        if($ServiceSMSStat)
        {
            if ($ServiceSMSStat.Status -ne "Running")
            {
                $ServiceSMSStat | Set-Service -startuptype "Automatic" -Status Running -PassThru
                $txt = "Starting " + $ServiceSMS + " service on " + $ComputerName + " Service is now started"
                Dolog -Message $txt -LogLevel 1 -color "White"
            }
            else
            {
                $ServiceSMSStat | Restart-Service
                $txt = "ReStarting " + $ServiceSMS + " service on " + $ComputerName + " Service is now Restarted"
                Dolog -Message $txt -LogLevel 1 -color "White"
            }
        }
        else
        {
            Dolog -Message "No $ServiceSMS service"   -LogLevel 2 -color "Red"
        }
        if($ServiceCryptSvcStat)
        {
            if ($ServiceCryptSvcStat.Status -ne "Running")
            {
                $ServiceCryptSvcStat | Set-Service -startuptype "Automatic" -Status Running -PassThru
                $txt = "Starting " + $ServiceCryptSvc + " service on " + $ComputerName + " Service is now started"
                Dolog -Message $txt -LogLevel 1 -color "White"
            }
            else
            {
                $ServiceCryptSvcStat | Restart-Service
                $txt = "ReStarting " + $ServiceCryptSvc + " service on " + $ComputerName + " Service is now Restarted"
                Dolog -Message $txt -LogLevel 1 -color "White"
            }
        }
        else
        {
            Dolog -Message "No $ServiceCryptSvc service"   -LogLevel 2 -color "Red"
        }#>
    }
}

Function Full_repair
{
    Dolog -Message "Reinstalling agent [Full reinstall]" -LogLevel 2 -color "Yellow"
    copy_files
    
    Dolog -message "Starting process..." -loglevel 1 -color "White"
    update_policies $false
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Powershell.exe -ExecutionPolicy Bypass -Command c:\windows\temp\Reinstall_Agent\Reinstall.ps1 2>$null
    }
    #psexec.exe -s \\$computername Powershell.exe -ExecutionPolicy Bypass -Command c:\windows\temp\Reinstall_Agent\Reinstall.ps1 2>$null
    install_Agent


}

Function repair_ccmsetup
{
 
    while( -not ( ($choice= (Read-Host "Proceed with agent repair?")) -match "y|n")){}
    if ($choice -eq "Y" -or $choice -eq "y")
    {
        Dolog -message "Reparing CCM Client" -LogLevel 1 -color "White"
        cmtrace.exe "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log"

        install_Agent
    }
}

Function copy_files
{
    $aux_path = $PSCommandPath | Split-Path -Parent

    Dolog -message "Copying setup files to remote computer...." -loglevel 1 -Color "White"
    
    if (-not (Test-Path "\\$ComputerName\c$\Windows\temp\Reinstall_Agent"))
    {
        New-Item "\\$ComputerName\c$\Windows\temp\Reinstall_Agent\Aux_Files" -ItemType Directory 2>$null
    }
    
    #Copy-Item -Path "$aux_path\Aux_Scripts\Reinstall.ps1" -Destination "\\$ComputerName\c$\windows\Temp\Reinstall_Agent" -Force #2>$null
    #Copy-Item -Path "$aux_path\Aux_Files" -Destination "\\$ComputerName\c$\windows\Temp\Reinstall_Agent" -Force -Recurse #2>$null

    Copy-Item -Path ".\Aux_Scripts\Reinstall.ps1" -Destination "\\$ComputerName\c$\windows\Temp\Reinstall_Agent" -Force
    Copy-Item -Path ".\Aux_Files\*.*" -Destination "\\$ComputerName\c$\windows\Temp\Reinstall_Agent\Aux_Files" -Force

}

Function Run_Setup
{

    copy_files
    Dolog -message "Starting process..." -loglevel 1 -color "White"

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $install_command = "cmd /C C:\windows\temp\Reinstall_Agent\Aux_Files\ccmsetup.exe /mp:PKPSCC07,CKPSCC05 /AllowMetered SMSSITECODE=CB1 CCMLOGMAXSIZE=500000 /UsePKICert /NoCRLCheck CCMHOSTNAME=sccmcb.telecom.pt CCMCERTSEL=SubjectStr:corpPT.com"
        invoke-expression -command "$install_command"
    }
    #psexec -s \\$ComputerName c:\windows\temp\Reinstall_Agent\Aux_Files\ccmsetup.exe /mp:PKPSCC07,CKPSCC05 /AllowMetered SMSSITECODE=CB1 CCMLOGMAXSIZE=500000 /UsePKICert /NoCRLCheck CCMHOSTNAME=sccmcb.telecom.pt CCMCERTSEL=SubjectStr:corpPT.com 2>$null


}


Function install_Agent
{

    try
    {
        $Timeout = 600
        $RetryInterval = 5

        Dolog -message "Installing client. Please wait" -loglevel 1 -color "White"
        run_setup
        cmtrace.exe "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log"
        $end=$false
        $timer = [Diagnostics.Stopwatch]::StartNew()

        
        while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and ($end -ne $true))
        {
 
            ## Wait a specific interval
            Start-Sleep -Seconds $RetryInterval
       
            #$totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
            #$end = Get_CMLog "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log" "exiting with return code 0" 1 'Setup'
            $end = check_log_errorv2 -filename "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log" -listerrors "exiting with return code 0" -searchtype "setup"
            Write-Host "." -NoNewLine -ForegroundColor White
        
            ## Check the time
            #$totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
            #Write-host "Still waiting for action to complete after [$totalSecs] seconds..."
        }
       
        $timer.Stop()
        if ($timer.Elapsed.TotalSeconds -gt $Timeout) 
        {
            #throw 'Action did not complete before timeout period.'
            Dolog -Message "Setup did not complete before timeout period." -LogLevel 3 -color "Red"
        } 
        else
        {
            Dolog -message " " -loglevel 1 -color "White"
            dolog -message "Setup finished installing" -loglevel 1 -color "White"
        }
        
        While( -not ( ($choice = (Read-Host "Is agent ok (y/n)?")) -match "y|n")){}
        if ($choice -eq "N" -or $choice -eq "n")
        {
            do
            {
                Start-Sleep -Seconds (5)
                #$end = Get_CMLog "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log" "exiting with return code 0" 1 'setup'
                $end = check_log_errorv2 -filename "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log" -listerrors "exiting with return code 0" -searchtype "setup"
                #Write-Host "End2=$end" -NoNewLine -ForegroundColor White
            }
            while ($end -ne $true)
        }
        else
        {
            Dolog -Message "Client successfully installed" -LogLevel 1 -color "Green"
            ExitRC 0
        }
    }
    catch
    {
        dolog -Message "Unable to upgrade SCCM Agent" -LogLevel 2 -color "Red"
    }
}

Function mof_comp
{
    Dolog -Message "Setup is unable to compile mof file. Proceeding with repair" -LogLevel 2 -color "Yellow"
    Copy-Item -Path ".\Aux_Scripts\MofComp.ps1" -Destination "\\$ComputerName\c$\windows\Temp" -Force
    #copy_files

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Powershell.exe -ExecutionPolicy Bypass -Command c:\windows\temp\MofComp.ps1 2>$null
    }

    #psexec.exe -s \\$computername Powershell.exe -ExecutionPolicy Bypass -Command c:\windows\temp\MofComp.ps1 2>$null
    Run_Setup
}