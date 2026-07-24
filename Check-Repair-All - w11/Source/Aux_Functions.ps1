Function check_online
{
    $online = $false
    try
    {
        if (Test-Connection -count 1 -Quiet $ComputerName)
        {
            $online = $true
            return $online
            

            <#
            #$strComputerName = Get-WmiObject -ComputerName $ComputerName -Class Win32_ComputerSystem -ea stop |Select-Object Name
            #$strComputerName = get-ciminstance -CimSession $cimsession -Class Win32_ComputerSystem  -ea stop |Select-Object Name

            
            
            if ($strComputerName.Name -ne $ComputerName)
            {
                
                $txt = "Computername is not correct!!! Correct name is " + $strComputerName
                Write-Host $txt -ForegroundColor Red
            }
            else
            {
                write-host "Computername is correct!!! $ComputerName" -ForegroundColor Green
            }
                
            #>
        }
        else
        {
            Write-Host "Unable to connect to computer $computername" -ForegroundColor Yellow
            #return $online
            break
        }
    }
    catch
    {
        Write-Host "RDP Error connecting to computer $computername" -ForegroundColor Yellow
        break
    }

    Write-Host $online
    
}

Function reverse_dns
{

    try 
    {
        $strComputerName = get-ciminstance -CimSession $cimsession -Class Win32_ComputerSystem  -ea stop |Select-Object Name
        
        if ($strComputerName.Name -ne $ComputerName)
        {
            
            $txt = "Computername is not correct!!! Correct name is " + $strComputerName
            Write-Host $txt -ForegroundColor Red
        }
        else
        {
            write-host "Computername is correct!!! $ComputerName" -ForegroundColor Green
        }    
    }
    catch 
    {
        
        
    }
    

            
            
    
        
    #>

}

Function Restart_Services
{
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $ServiceSMS = "SMS Agent Host"
        $ServiceWUA = "Windows Update"
    
        $ServiceWUAStat = Get-Service  -Name $ServiceWUA -ErrorAction SilentlyContinue
        $ServiceWUAStat | Stop-Service
    
        $ServiceWUAStat = Get-Service -name $ServiceWUA -ErrorAction SilentlyContinue
        $ServiceSMSStat = Get-Service -Name $ServiceSMS -ErrorAction SilentlyContinue
    
        if($ServiceSMSStat)
        {
            if ($ServiceSMSStat.Status -ne "Running")
            {
                $ServiceSMSStat | Set-Service -startuptype "Automatic" -Status Running -PassThru
                $txt = "Starting " + $ServiceSMS + " service on " + $ComputerName + " Service is now started"
                Write-Host $txt -ForegroundColor "White"
            }
            else
            {
                $ServiceSMSStat | Restart-Service
                $txt = "ReStarting " + $ServiceSMS + " service on " + $ComputerName + " Service is now Restarted"
                Write-Host $txt -ForegroundColor "White"
            }
        }
        else
        {
            Write-Host "No NAC service"  -ForegroundColor "Red"
        }
        
        Write-Host "Sleep x sec!!" -ForegroundColor "White"
        Start-Sleep -s 30
    }

}
Function Restart_Services2
{

    $ServiceSMS = "SMS Agent Host"
    $ServiceWUA = "Windows Update"

    $ServiceWUAStat = Get-Service -computername $ComputerName -Name $ServiceWUA -ErrorAction SilentlyContinue
    $ServiceWUAStat | Stop-Service
    $ServiceSMSStat = Get-Service -computername $ComputerName -Name $ServiceSMS -ErrorAction SilentlyContinue

   
    if($ServiceSMSStat)
    {
        if ($ServiceSMSStat.Status -ne "Running")
        {
            $ServiceSMSStat | Set-Service -startuptype "Automatic" -Status Running -PassThru
            $txt = "Starting " + $ServiceSMS + " service on " + $ComputerName + " Service is now started"
            Write-Host $txt -ForegroundColor "White"
        }
        else
        {
            $ServiceSMSStat | Restart-Service
            $txt = "Restarting " + $ServiceSMS + " service on " + $ComputerName + " Service is now Restarted"
            Write-Host $txt -ForegroundColor "White"
        }
    }
    else
    {
        Write-Host "No NAC service"  -ForegroundColor "Red"
    }
    
    Write-Host "Sleep x sec!!" -ForegroundColor "White"
    Start-Sleep -s 30
}

Function Dolog
{
param (
    [Parameter(Mandatory = $true)]
    [string]$Message,
		
    [Parameter()]
    [ValidateSet(1, 2, 3)]
    [int]$LogLevel = 1,

    [Parameter(Mandatory = $true)]
    [string]$color,

    [Parameter(Mandatory = $false)]
    [string]$color2,

    [Parameter(Mandatory = $false)]
    [ValidateSet("local","remote")]
    [string]$access_type
)


    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf)", $LogLevel


    $Line = $Line -f $LineFormat

    if ($access_type -eq "local")
    {
        $logfile = "C:\Windows\Temp\Recover_w10.log"
    }

    Add-Content -Value $Line -Path $logfile
    Write-Host $Message -ForegroundColor $color

}

Function check_os
{

    $DaysWithOutReboot = 7
    $DateNow = Get-Date

    $Win10Ver = $null
    $Win11Ver = $null
    #$OS = Get-WmiObject -ComputerName $ComputerName -Class Win32_OperatingSystem -ea stop
    #$LastBootUp = ([System.Management.ManagementDateTimeConverter]::ToDateTime($OS.LastBootUpTime)).ToString("dd/MM/yyyy HH:mm")
    #$LastBootUpComp = ([System.Management.ManagementDateTimeConverter]::ToDateTime($OS.LastBootUpTime)).adddays($DaysWithOutReboot)
    #$TotalDayWithOutBoot = $DateNow-$LastBootUpComp
    
    $OS = get-ciminstance -CimSession $cimsession -Class Win32_OperatingSystem -ea stop
    $LastBootUp = $OS.LastBootUpTime
    $LastBootUpComp = ($OS.LastBootUpTime).adddays($DaysWithOutReboot)
    $TotalDayWithOutBoot = $DateNow-$LastBootUpComp
    
    $DayWithOutBoot = [math]::Round($TotalDayWithOutBoot.TotalDays,2)

    switch ($OS.BuildNumber) 
    {
        14393 { $Win10Ver = '1607'} 
        16299 { $Win10Ver = '1709'} 
        17134 { $Win10Ver = '1803'} 
        17763 { $Win10Ver = '1809'} 
        18362 { $Win10Ver = '1903'} 
        18363 { $Win10Ver = '1909'} 
        19041 { $Win10Ver = '2004'}
        19042 { $Win10Ver = '20H2'}
        19043 { $Win10Ver = '21H1'}
        19044 { $Win10Ver = '21H2'}
        19045 { $Win10Ver = '22H2'}
        22000 { $Win10Ver = '21H2'}
        22621 { $Win10Ver = '22H2'}
        22621 { $Win10Ver = '23H2'}
        26100 { $Win10Ver = '24H2'}
        26200 { $Win10Ver = '25H2'}
    default {}}

    $txt= $OS.Caption + " " + $OS.BuildNumber + " (Version " + $Win10Ver + ")"
    Dolog -Message $txt -color "White"

    $OSInstDLongMin,$OSInstDLongMax = (14,365)

    #$OSInstallDate = ([System.Management.ManagementDateTimeConverter]::ToDateTime($OS.InstallDate))
    $OSInstallDate = $OS.InstallDate

    $TotalDayInstalled = $DateNow-$OSInstallDate
    $CountTotalDayInstalled = [math]::Round($TotalDayInstalled.TotalDays,2)
    if($CountTotalDayInstalled -lt $OSInstDLongMin)
    {
        $txt = "OS installed " + $CountTotalDayInstalled + " days ago"
        Dolog -Message $txt -color "Green" -LogLevel 1
    }
    elseif($CountTotalDayInstalled -gt $OSInstDLongMin -AND $CountTotalDayInstalled -lt $OSInstDLongMax)
    {
        $txt = "OS installed " + $CountTotalDayInstalled + " days ago"
        Dolog -Message $txt -color "Yellow" -LogLevel 2
    }
    elseif($CountTotalDayInstalled -gt $OSInstDLongMax)
    {
        $txt = "OS installed " + $CountTotalDayInstalled + " days ago"
        Dolog -Message $txt -color "Red" -LogLevel 3
    }

    if($DateNow -lt $LastBootUpComp)
    {
        $txt = "Last-Boot " + $LastBootUp
        Dolog -Message $txt -color "Green"
    }
    else
    {
        $txt = "Last-Boot " + $LastBootUp + " $DaysWithOutReboot + $DayWithOutBoot" + " Days"
        Dolog -Message $txt -color "Red" -LogLevel 3
    }

    $minimumfreespace = 5*104*1024*1024*10

    #$disk = Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $Computername Win32_LogicalDisk -Filter "DeviceID='C:'" #| Select-Object Size, FreeSpace
    $disk = get-ciminstance -CimSession $cimsession -Class Win32_LogicalDisk -Filter "DeviceID='C:'"

    $Disk = get-ciminstance -CimSession $cimsession -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $DiskPartition = Get-CimInstance  -CimSession $cimsession -ClassName Win32_DiskPartition
    $Win32_DiskDrive = Get-CimInstance  -CimSession $cimsession -ClassName Win32_DiskDrive
    $LogicalDiskToPartition =  Get-CimInstance  -CimSession $cimsession -ClassName Win32_LogicalDiskToPartition
    $Win32_DiskDriveToDiskPartition =  Get-CimInstance  -CimSession $cimsession -ClassName Win32_DiskDriveToDiskPartition

    foreach ($ldisk2part in $LogicalDiskToPartition)
    {
        if ($ldisk2part.Dependent.DeviceID -eq $Disk.DeviceID)
        {
            foreach ($part in $DiskPartition)
            {
                if ($part.Name -eq $ldisk2part.Antecedent.DeviceID)
                { 
                    foreach ($dd2partin in $Win32_DiskDriveToDiskPartition )
                    {
                        if ($dd2partin.Dependent.DeviceID -eq $ldisk2part.Antecedent.DeviceID )
                        {
                            foreach ($diskdrive in $Win32_DiskDrive)
                            {
                                if ($diskdrive.DeviceID -eq $dd2partin.Antecedent.DeviceID )
                                {
                                    $DiskDriveC = $diskdrive
                                    break
                                }
                            }

                        }
                    }
                }
            }

        }

    }

    $HardDriveF = $null
    if ($os.Version -notlike "6.1*")
    {
        #$HardDriveF =  Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $Computername MSFT_PhysicalDisk -Namespace Root\Microsoft\Windows\Storage | Select-Object Model, MediaType
        try 
        {
            $HardDriveF =  get-ciminstance -CimSession $cimsession -Class MSFT_PhysicalDisk -Namespace Root\Microsoft\Windows\Storage -ErrorAction SilentlyContinue | Select-Object Model, MediaType
        }
        catch 
        {
            Dolog -Message "Unable to Disk Media Type Information" -LogLevel 2 -color "Red"
            $HardDriveF = $null
        }
        
    }
    else
    {
        $HarddiskType = "Windows 7[Não consigo saber!]"
    }
    if ($HardDriveF.MediaType)
    {
        switch (($HardDriveF.MediaType)[0]) 
        {
            3 { $HarddiskType = 'HDD'} 
            4 { $HarddiskType = 'SSD'} 
            0 { $HarddiskType = 'Unspecified'} 
            5 { $HarddiskType = 'SCM'} 
            666 { $HarddiskType = 'Win7'} 
            default {}
        }
    }

    $txt = "Hard Drive Type: " + $HarddiskType
    if($HarddiskType -ne 'SSD')
    {
        Dolog -Message $txt -LogLevel 1 -color "Red" 
    }
    else
    {
        Dolog -Message $txt -LogLevel 1 -color "Green"
    }
    
    $disksize = [math]::truncate($disk.Size / 1GB)

    #$txt = "Model " + ($DiskDriveC.Model) + (" Disk Size {0} GB" -f [math]::truncate($disk.Size / 1GB))
    $txt = "Model " + ($DiskDriveC.Model) + (" Disk Size {0} GB" -f $disksize)
    $txt = "Model " + ($HardDriveF.Model) + (" Disk Size {0} GB" -f $disksize)
    
    if ($disksize -le 80)
    {
        Dolog -Message $txt -LogLevel 3 -color "Red"
    }
    else
    {
        Dolog -Message $txt -LogLevel 1 -color "Green"
    }
     
    $txt = "Free Disk Space: " + (" {0} GB" -f [math]::truncate($disk.FreeSpace / 1GB)) 

    if($disk.FreeSpace -lt $minimumfreespace) 
    {
        Dolog -Message $txt -LogLevel 2 -color "Red"
    }
    else
    {
        Dolog -Message $txt -LogLevel 2 -color "White"
    }

    # Reboot pending?
    #$rebootRequiredBoolean = Invoke-WmiMethod   | Select-Object -Property PSComputerName, RebootPending
    $clientutils = [wmiclass]"\\$computername\root\ccm\clientsdk:CCM_ClientUtilities"
    $rebootRequiredBoolean = $clientutils.DetermineIfRebootPending()
    $rebootRequiredBoolean
    if ($rebootRequiredBoolean.RebootPending -eq $True) 
    {
        $txt = "Reboot pending?? " + $rebootRequiredBoolean.RebootPending
        Dolog -Message $txt -color "Yellow" -LogLevel 2
    }
    else
    {
        $txt = "Reboot pending?? " + $rebootRequiredBoolean.RebootPending
        Dolog -Message $txt -color "White" -LogLevel 1
    }

     # Model
   # $model = Get-WmiObject -ComputerName $Computername Win32_ComputerSystem
    $model = get-ciminstance -CimSession $cimsession -Class Win32_ComputerSystem
    $txt = "Model: " + $model.model + " SKU: " + $model.SystemSKUNumber
    Dolog -Message $txt -LogLevel 1 -color "Yellow"
    
    # BIOS Version
    $datebiosOK = [DateTime]"1/1/2015 23:59:59"
    #$bios = Get-WmiObject -ComputerName $Computername Win32_Bios
    #$biosdate = $bios.ConverttoDateTime($bios.ReleaseDate)

    $bios = get-ciminstance -CimSession $cimsession -class Win32_Bios
    $biosdate = $bios.ReleaseDate

    #$txt = "Bios Version = " + $bios.SMBIOSBIOSVersion + " Bios Date = " + $bios.ConverttoDateTime($bios.ReleaseDate).ToString('dd MMM yyyy')
    $txt = "Bios Version = " + $bios.SMBIOSBIOSVersion + " Bios Date = " + $bios.ReleaseDate
    if($biosdate -lt $datebiosOK)
    {
        Dolog -Message $txt -LogLevel 2 -color "Red"
    }
    else
    {
        Dolog -Message $txt -LogLevel 2 -color "Green"
    }

    # Network INfo
    #$nwINFO = Get-WmiObject -ComputerName $Computername Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }
    $nwINFO = get-ciminstance -CimSession $cimsession -class Win32_NetworkAdapterConfiguration | Where-Object { $null -ne $_.IPAddress}
    foreach ($nwINFOService in $nwINFO)
    {
        if ($nwINFOService.serviceName -eq "vna_ap")
        {
            $txt = "Connected with VPN!!! IP " + $nwINFOService.IPAddress
            Dolog -message $txt -LogLevel 1 -color "Red"
        }
    }

    return $os
   
}

Function ExitRC
{
param (
    [Parameter(Mandatory = $true)]
    [int]$ExitCode
    )
    exit 
    #[System.Environment]::Exit($ExitCode)
}

Function kill_proccess
{
param 
(
    [Parameter(Mandatory = $true)]
    [string]$proc_name,
    [Parameter(Mandatory = $true)]
    [int]$waitseconds
)
    $count=0

    do
    {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        #$aux_proc = Get-WmiObject Win32_Process -ComputerName $ComputerName | ?{ $_.ProcessName -match "$proc_name" }
        $aux_proc = get-ciminstance -CimSession $cimsession -Class Win32_Process | Where-Object{ $_.ProcessName -match "$proc_name" }
        
        if ($aux_proc)
        {
            $count++
        }
        else
        {
            Dolog -message "Process $proc_name fininsh" -LogLevel 1 -color "Green"
            break
        }
    }
    while ($count -le $waitseconds)
    

    if ($count -eq $waitseconds+1)
    {
        try
        {
            Dolog -message "Process $proc_name in memory for to long...Terminating it!" -loglevel 1 -color "White"
            #(Get-WmiObject Win32_Process -ComputerName $ComputerName | ?{ $_.ProcessName -match "$proc_name" }).Terminate() | Out-Null
            $kill_status = get-ciminstance  -CimSession $cimsession -Class Win32_Process -Filter "name='$proc_name'" | Invoke-CimMethod -MethodName Terminate

            if ($kill_status.ReturnValue -ne 0)
            {
                Dolog -Message "Process $($proc_name) terminate with status = $($kill_status.ReturnValue)" -LogLevel 2 -color "Red"
            }
            else 
            {
                Dolog -Message "Process $($proc_name) terminate with status = $($kill_status.ReturnValue)" -LogLevel 1 -color "White"
            }
            
        }
        catch
        {
            Dolog -Message "Unable to kill process $proc_name" -LogLevel 2 -color "Red"
        }
    }

}

Function check_Service
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$service_name
    )

    Dolog -Message "Checking service $servicename status" -LogLevel 1 -color "White"
    try 
    {
        $Service_Status = Get-Service -computername $ComputerName -Name $service_name -ErrorAction SilentlyContinue

        $Service_Status | Restart-Service
        $txt = "ReStarting " + $service_name + " service on " + $ComputerName + " Service is now Restarted"
        Dolog -Message $txt -LogLevel 1 -color "White"
            
        
        if ($Service_Status.Status -ne "Running")
        {
            Dolog -Message "Service $service_name is OK" -LogLevel 3 -color "False"
            return $false
        }
        else
        {
            Dolog -Message "Service $service_name is OK" -LogLevel 1 -color "Green"
            return $true
        }
    }
    catch 
    {
        
    }
}

Function check_ou
{
    
    $computerOU = get-ADComputer -Identity $computername -Properties DistinguishedName
    
    if ($computerOU -like "*OU=SelfAssist*")
    {
        return $false
    }
}

Function do_timeout
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [int]$Timeout,
        [Parameter(Mandatory = $true)]
        [int]$RetryInterval,
        [Parameter(Mandatory = $true)]
        [string]$Filename,
        [Parameter(Mandatory = $true)]
        [string]$Search_string
    )
        #$Timeout = 300
        #$RetryInterval = 5

        $end=$false
        $timer = [Diagnostics.Stopwatch]::StartNew()

        while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and ($end -ne $true))
        {
 
            ## Wait a specific interval
            Start-Sleep -Seconds $RetryInterval
       
            #$totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
            #$end = Get_CMLog "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log" "exiting with return code 0" 1 'Setup'
            $end = check_log_errorv2 -filename $Filename -listerrors $Search_string -searchtype "scan"
            Write-Host "." -NoNewLine -ForegroundColor White
        
            ## Check the time
            #$totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
            #Write-host "Still waiting for action to complete after [$totalSecs] seconds..."
        }
       
        $timer.Stop()
        if ($timer.Elapsed.TotalSeconds -gt $Timeout) 
        {
            #throw 'Action did not complete before timeout period.'
            return $true
        } 
        else
        {
            return $false
        }
}

Function Uninstall
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$Program
    )

    write-host "AQUI-UNINSTALL" $Program

    #$uninst_str = Get-WmiObject -ComputerName $ComputerName -Namespace "ROOT\cimv2\sms" -query "Select UninstallString from SMS_InstalledSoftware where ArpDisplayName='$Program'"
    $uninst_str =  get-ciminstance -CimSession $cimsession -Namespace "ROOT\cimv2\sms" -query "Select UninstallString from SMS_InstalledSoftware where ArpDisplayName='$Program'"
    

    Write-Host "->" $uninst_str.UninstallString
}

Function Read_registry_popups
{
param(
    [string]$reg_value
)
    $count = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            #$count = check_exececution_times "HKLM:\Software\PTPortugal" $countername
            $path = "HKLM:\Software\PTPortugal"
            try
            {
                #$a = Get-ItemProperty -Path "HKLM:\Software\PTPortugal" -Name "Count_w11_popup_24h2" -ErrorAction Stop
                $a = Get-ItemProperty -Path $path -Name $using:reg_value -ErrorAction Stop
                
                return $a.$using:reg_value
             }
             catch
             {
                
                return "ERR"
                
             }
        }

        #Write-Host $count.Count_w11_popup_24h2
        #Write-Host $count.$using:reg_value

    return $count

    

}