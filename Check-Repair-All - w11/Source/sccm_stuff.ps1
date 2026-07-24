Function get_client_Settings
{
    #Get Management Point
    #$new_clientVersion = "5.00.9122.1007" 2309
    #$new_clientVersion = "5.00.9132.1011" #2409
    $new_clientVersion = "5.00.9141.1011" #2509
    $upgrade = "N"

    

    try
    {
        #$mp = Get-WmiObject -Class "SMS_Authority" -ComputerName $ComputerName -Namespace "ROOT\ccm" -ErrorAction Stop  |Select-Object CurrentManagementPoint
        $mp = get-ciminstance -CimSession $cimsession -Class "SMS_Authority" -Namespace "ROOT\ccm"  -ea stop |Select-Object Name,CurrentManagementPoint
       # Write-Host $mp -ForegroundColor DarkMagenta

        $txt = "Current Management Point: " + $mp.CurrentManagementPoint
        Dolog -Message $txt -LogLevel 1 -color "Yellow" -color2 "White"
    }
    catch
    {
        Dolog "Unable to get Management Point" -LogLevel 3 -color "Red"
    }

    #Get Client Version
    try
    {
       # $clientVersion = Get-WmiObject -Class "SMS_Client" -ComputerName $ComputerName -Namespace "ROOT\ccm" -ErrorAction stop |Select-Object ClientVersion
        $clientVersion = get-ciminstance -CimSession $cimsession -Namespace "ROOT\ccm" -Class "SMS_Client" -ErrorAction stop |Select-Object ClientVersion

        $txt = "SCCM Client Version: " + $clientVersion.ClientVersion
        
        if ($clientVersion.ClientVersion -ge $new_clientVersion)
        {    
            Dolog -Message $txt -LogLevel 1 -color "Green"
        }
        else
        {
            Dolog -Message $txt -LogLevel 1 -color "Red"
            While( -not ( ($upgrade = (Read-Host "SCCM Agent Outdate!! Proceed with upgrade? (y/n)")) -match "y|n")){}
            if ($upgrade -eq "Y" -or $upgrade -eq "y")
            {
                install_Agent  
            }
        
        }        
    }
    catch
    {
        Dolog "Unable to get Client Version" -LogLevel 3 -color "Red"
        
        $get_ou = check_ou
        
        if ($get_ou -eq $false)
        {
            Dolog -Message "Computer is in Selfassist" -LogLevel 2 -color "Yellow"
            ExitRC 1
        }
    }

    if ($upgrade -eq "N" -or $upgrade -eq "n")
    {
        $clientok = $false

        $ccmsetup = "\\"+$ComputerName+"\c$\Windows\CCMSetup\Logs\Ccmsetup.log" 
       
        $clientok = check_log_errorv2 $ccmsetup "exiting with return code 0"
        #write-host "Aqui - " $clientok
        if ($clientok -eq $false )
        {
                
            #check_log_error $ccmsetup "not enough disk space","MSI: Could not open key: HKEY_LOCAL_MACHINE\Software\","0x8007042c","0x80004005","0x80070643","0x80041013","MAXDRIVE or MAXDRIVESPACE","Next retry in 10 minute(s)..." 200
            check_log_errorv2 $ccmsetup "not enough disk space","MSI: Could not open key: HKEY_LOCAL_MACHINE\Software\","Setup was unable to compile the file","0x8007042c","0x80004005","0x80070643","0x80041013","MAXDRIVE or MAXDRIVESPACE","Next retry in 10 minute(s)...","0x80070005","[Found Microsoft Application Root Cert]","0x80072ee5"
        }

        try
        {

            
            $cachesize = (Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $Computername -Namespace ROOT\CCM\SoftMgmtAgent -Query “Select ContentSize from CacheInfoEx”)
            $CacheSizeSCCm = [math]::round((($cachesize.contentSize | measure -sum).Sum) /1mb, 2)
            if ($CacheSizeSCCm -gt 8) 
            {
                $txt = "Cache Content Size: " + $CacheSizeSCCm + "Gb"
                Dolog -Message $txt -LogLevel 2 -color "Red"
            }
            else
            {
                $txt = "Cache Content Size: " + $CacheSizeSCCm + "Gb"
                Dolog -Message $txt -LogLevel 2 -color "White"
            }
        }
        catch
        {
            Dolog -message "Unable to get SCCM Cache info!" -LogLevel 2 -color "Red"
        }
    } 

}

Function Force_Trigger
{
param (
    [Parameter(Mandatory = $true)]
    [string]$action
    )

    Switch ($action)
    {
        "{00000000-0000-0000-0000-000000000108}" {$aux_action  = "Software Updates Assignments Evaluation Cycle"}
        "{00000000-0000-0000-0000-000000000113}" {$aux_action  = "Scan by Update Source"}
        "{00000000-0000-0000-0000-000000000021}" {$aux_action  = "Refresh Machine Policy"}
    }

    try
    {
        Dolog -Message "Forcing action $aux_action" -LogLevel 1 -color "White"
        #Invoke-WmiMethod -ComputerName $Computername -Namespace root\ccm -Class sms_client -Name TriggerSchedule $action| Out-Null
        #Invoke-CimMethod -ComputerName $Computername -Namespace 'root\CCM' -ClassName SMS_Client -MethodName TriggerSchedule -Arguments @{sScheduleID='$action'}
        Invoke-cimmethod -CimSession $cimsession -Namespace 'root\CCM' -ClassName SMS_Client -MethodName TriggerSchedule -Arguments @{sScheduleID=$action} | Out-Null
    }
    catch
    {
        Dolog -Message "Error Forcing action $aux_action" -LogLevel 1 -color "White"
    }
}
