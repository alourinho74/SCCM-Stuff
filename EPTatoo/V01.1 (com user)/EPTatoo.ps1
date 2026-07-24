$win_dir = $env:windir
$strComputerName = $env:COMPUTERNAME

$logfile = $win_dir + "\temp\EPTatoo.log"

Write-Host $logfile

$workdir = "C:\windows\Temp\"

Function verify_logfile
{
    if (Test-Path $logfile)
    {
        
    }
    else
    {
        $logfile = New-Item -Path $win_dir"\temp\EPTatoo.log" -ItemType "file" -Force
        
    }

}

Function exit_script
{
param (
    [Parameter(Mandatory = $true)]
    [int]$intRC
    )

    [System.Environment]::Exit($intRC)
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
    [string]$color
)


    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf)", $LogLevel


    $Line = $Line -f $LineFormat

    Add-Content -Value $Line -Path $logfile
    Write-Host $Message -ForegroundColor $color
    

}

Function read-dateformat
{
    param (
    [Parameter(Mandatory = $true)]
    [string]$datetype
    )

    $txt = "Formato = " + $datetype

    $aux = $datetype[2]


    if ($aux -match '\/')
    {
        return $true
    }
    else 
    {
        return $false
    }
}

Function Read_registry_string
{
param (
    [Parameter(Mandatory = $true)]
    [string]$regvalue
    )
    $HKLM =2147483650
    $computer ='.'
    $reg = [WMIClass]"ROOT\DEFAULT:StdRegProv"
    $Key = "SOFTWARE\PTPortugal\Deploy"
    try
    {
        $results = $reg.GetStringValue($HKLM, $Key, $regvalue)
        return $results.sValue
    }
    catch
    {
        dolog -Message "Can't read registry value" -LogLevel 3 -color "Red"
        return $null
    }
    
}

Function check_wmi_instance
{
param (
    [Parameter(Mandatory = $true)]
    [string]$AdvIdKey
    )

    
    $advidslist = gwmi -Namespace root\cimv2 -Class EpTatoo

    foreach ($id in $advidslist)
    {
        if ($id.AdvertisementID -eq $AdvIdKey)
        {
            $txt = "Advertisement ID " + $AdvIdKey + " already exists in wmi. Exiting program"
            Dolog -Message $txt -color "Yellow"
            exit_script(10000)
        }
        
        
    }


    return $false
}

Function check_tatoo_reg
{
    $ErrorActionPreference = "stop"
    
    $registryPath = "HKLM:\SOFTWARE\PTPortugal\Deploy"

    Try 
    {
        Get-ItemProperty -Path $registryPath
        $txt = 'RegistryKey ' + $registryPath + ' Exists!'
        Dolog -Message $txt -color "Green"
    }
    Catch [System.Management.Automation.ItemNotFoundException]
    {
        $txt = "RegistryKey " + $registryPath + " does not exists. Exiting Script"
        Dolog -Message $txt -color "Red" -LogLevel 3
        exit_script 3
     }
     Catch
    {
        $txt = "RegistryKey " + $registryPath + " does not exists. Exiting Script"
        Dolog -Message $txt -color "Red" -LogLevel 3
        exit_script 3
     }

     Finally { $ErrorActionPreference = "Continue" } 
}

Function regkeyExist
{

    $ErrorActionPreference = "stop"
    
    $registryPath = "HKLM:\SOFTWARE\PTPortugal\Deploy"

    Try 
    {
        Get-ItemProperty -Path $registryPath
        $txt = 'RegistryKey ' + $registryPath + ' Exists!'
        Dolog -Message $txt -color "Green"
        Dolog -Message "Proceding to get values" -color "Green"

        try 
        {
             $AdvertisementID = Read_registry_string "AdvertisementID"

             $aux = check_wmi_instance $AdvertisementID

             if (-not $aux)
             {
             

                 $AdvertisementIDtxt = "Adv ID = " + $AdvertisementID
                 if ($AdvertisementID -eq "" -or $AdvertisementID -eq $null)
                 {
                    $AdvertisementID = ""
                    $AdvertisementIDtxt = "Adv ID not Defined"
                    Dolog -Message $AdvertisementIDtxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $AdvertisementIDtxt -color "Green"
                 }

                 $ClientVersion = Read_registry_string 'Client Version'
                 $ClientVersiontxt = "Client Version = " + $ClientVersion
                 if ($ClientVersion -eq "" -or $ClientVersion -eq $null)
                 {
                    $ClientVersion = ""
                    $ClientVersiontxt = "Client version = not defined"
                    Dolog -Message $ClientVersiontxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $ClientVersion -color "Green"
                 }

                 $Computername = Read_registry_string "Computername"
                 $Computernametxt = "Computername = " + $Computername
                 if ($Computername -eq "" -or $Computername -eq $null)
                 {
                    $Computername = ""
                    $Computernametxt = "Computername = not defined"
                    Dolog -Message $Computernametxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $Computernametxt -color "Green"
                 }

                 $InstallationType = Read_registry_string "Installation Type"
                 $InstallationTypetxt = "Installation Type = " + $InstallationType
                 if ($InstallationType -eq "" -or $InstallationType -eq $null)
                 {
                    $InstallationType = ""
                    $InstallationTypetxt = "InstallationType = not defined"
                    Dolog -Message $InstallationTypetxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $InstallationTypetxt -color "Green"
                 }

                 $InstalledBeginTime = Read_registry_string "Installed BeginTime"
                 

                 
                 if (! $InstalledBeginTime)
                 {
                    $InstalledBeginTimeGMT = "19700101000001.000000+060"
                    $InstalledBeginTimetxt = "Installation Begin Time = " + $InstalledBeginTimeGMT
                    Dolog -Message $InstalledBeginTimetxt -color "red" -LogLevel 3
                 }
                 else
                 {
                    $date_fomat = read-dateformat $InstalledBeginTime

                    if ($date_fomat)
                    {
                        $txt = "Date format like dd/M/yyyy = " + $InstalledBeginTime
                        Dolog -Message $txt -LogLevel 1 -color "White"
                        $dateconv = [datetime]::ParseExact($InstalledBeginTime,”dd/M/yyyy HH:mm:ss”,$null);
                    }
                    else
                    {
                        $txt = "Formato yyyy/M/dd " + $InstalledBeginTime
                        Dolog -Message $txt -LogLevel 1 -color "White"
                        $dateconv = [datetime]::ParseExact($InstalledBeginTime,”yyyy/M/dd HH:mm:ss”,$null);
                    }
                    $objScriptTime = New-Object -ComObject WbemScripting.SWbemDateTime
                    $objScriptTime.SetVarDate($dateconv)
                    $InstalledBeginTimeGMT = $objScriptTime.Value
                    $InstalledBeginTimetxt = "Installation Begin Time = " + $InstalledBeginTimeGMT
                    Dolog -Message $InstalledBeginTimetxt -color "Green"
                 }

                 $InstalledEndTime = Read_registry_string "Installed EndTime"
                 
                 
                 if (! $InstalledEndTime)
                 {
                    $InstalledEndTimeGMT = "19700101000001.000000+060"
                    $InstalledEndTimetxt = "Installation End Time = " + $InstalledEndTimeGMT
                    Dolog -Message $InstalledEndTimetxt -color "red" -LogLevel 3
                 }
                 else
                 {
                    $date_fomat = read-dateformat $InstalledEndTime

                    if ($date_fomat)
                    {
                        $txt = "Formato dd/M/yyyy " + $InstalledEndTime
                        Dolog -Message $txt -LogLevel 1 -color "White"
                        $dateconv = [datetime]::ParseExact($InstalledEndTime,”dd/M/yyyy HH:mm:ss”,$null)
                    }
                    else
                    {
                        $txt = "Formato yyyy/M/dd " + $InstalledEndTime
                        Dolog -Message $txt -LogLevel 1 -color "White"
                        $dateconv = [datetime]::ParseExact($InstalledEndTime,”yyyy/M/dd HH:mm:ss”,$null);
                    }
                    $objScriptTime = New-Object -ComObject WbemScripting.SWbemDateTime
                    $objScriptTime.SetVarDate($dateconv)
                    $InstalledEndTimeGMT = $objScriptTime.Value
                    $InstalledEndTimetxt = "Installation End Time = " + $InstalledEndTimeGMT
                    Dolog -Message $InstalledEndTimetxt -color "Green"
                 }

                 $LoggedUser = Read_registry_string "Logged User"
                 $LoggedUsertxt = "Logged User = " + $LoggedUser
                 if ($LoggedUser -eq "" -or $LoggedUser -eq $null)
                 {
                    $LoggedUser = ""
                    $LoggedUsertxt = "Logged User = not defined"
                    Dolog -Message $LoggedUsertxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $LoggedUsertxt -color "Green"
                 }



                 $MediaType = Read_registry_string "Media Type"
                 $MediaTypetxt = "Media Type = " + $MediaType
                 if ($MediaType -eq "" -or $MediaType -eq $null)
                 {
                    $MediaType = ""
                    $MediaTypetxt = "Media Type = not defined"
                    Dolog -Message $MediaTypetxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $MediaTypetxt -color "Green"
                 }

                 $Organization = Read_registry_string "Organization"
                 $Organizationtxt = "Organization = " + $Organization
                 if ($Organization -eq "" -or $Organization -eq $null)
                 {
                    $Organization = ""
                    $Organizationtxt = "Organization = not defined"
                    Dolog -Message $Organizationtxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $Organizationtxt -color "Green"
                 }

                 $PrevOperatingSystem = Read_registry_string "PrevOperating System"
                 $PrevOperatingSystemtxt = "Previous Operating System = " + $PrevOperatingSystem
                 if ($PrevOperatingSystem -eq "" -or $PrevOperatingSystem -eq $null)
                 {
                    $PrevOperatingSystem = ""
                    $PrevOperatingSystemtxt = "Previous Operating System = not defined"
                    Dolog -Message $PrevOperatingSystemtxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $PrevOperatingSystemtxt -color "Green"
                 }

                 $TaskSequenceName = Read_registry_string "Task Sequence Name"
                 $TaskSequenceNametxt = "Task Sequence Name = " + $TaskSequenceName
                 if ($TaskSequenceName -eq "" -or $TaskSequenceName -eq $null)
                 {
                    $TaskSequenceName = ""
                    $TaskSequenceNametxt = "Task Sequence Name = not defined"
                    Dolog -Message $TaskSequenceNametxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $TaskSequenceNametxt -color "Green"
                 }

                 $TaskSequenceversion = Read_registry_string "Task Sequence version"
                 $TaskSequenceversiontxt = "Task Sequence Version = " + $TaskSequenceversion
                 if ($TaskSequenceversion -eq "" -or $TaskSequenceversion -eq $null)
                 {
                    $TaskSequenceversion = ""
                    $TaskSequenceversiontxt = "Task Sequence Version = not defined"
                    Dolog -Message $TaskSequenceversiontxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $TaskSequenceversiontxt -color "Green"
                 }

                 $TSSequence = Read_registry_string "TSSequence"
                 $TSSequencetxt = "Task Sequence = " + $TSSequence
                 if ($TSSequence -eq "" -or $TSSequence -eq $null)
                 {
                    $TSSequence = ""
                    $TSSequencetxt = "Task Sequence = not defined"
                    Dolog -Message $TSSequencetxt -color "Yellow" -LogLevel 2
                 }
                 else
                 {
                    Dolog -Message $TSSequencetxt -color "Green"
                 }
             
                #Code to find if TSSequenceTime has a space char
                 $TSSequenceTime = Read_registry_string "TSSequence Time"

                 if ($TSSequenceTime)
                 {
                    #has a space
                    $aux_key = $true
                 }
                 else
                 {
                    #does not have a space
                    $aux_key = $false
                 }

                 if ($aux_key)
                 {
                    $TSSequenceTime = Read_registry_string "TSSequence Time"
                 }
                 else
                 {
                    $TSSequenceTime = Read_registry_string "TSSequenceTime"
                 }

                 if (! $TSSequenceTime)
                 {
                    $TSSequenceTimeGMT = '19700101000001.000000+060'
                    $TSSequenceTimetxt = "Task Sequence Time = " + $TSSequenceTimeGMT
                    Dolog -Message $TSSequenceTimetxt -color "red" -LogLevel 3
                 }
                 else
                 {
                    $date_fomat = read-dateformat $TSSequenceTime
                    if ($date_fomat)
                    {
                        $txt = "Formato dd/M/yyyy " + $TSSequenceTime
                        Dolog -Message $txt -LogLevel 1 -color "White"
                        $dateconv = [datetime]::ParseExact($TSSequenceTime,”dd/M/yyyy HH:mm:ss”,$null)
                    }
                    else
                    {
                        $txt = "Formato yyyy/M/dd " + $TSSequenceTime
                        Dolog -Message $txt -LogLevel 1 -color "White"
                        $dateconv = [datetime]::ParseExact($TSSequenceTime,”yyyy/M/dd HH:mm:ss”,$null);
                    } 
                    $objScriptTime = New-Object -ComObject WbemScripting.SWbemDateTime
                    $objScriptTime.SetVarDate($dateconv)
                    $TSSequenceTimeGMT = $objScriptTime.Value
                    $TSSequenceTimetxt = "Task Sequence Time = " + $TSSequenceTimeGMT
                    Dolog -Message $TSSequenceTimetxt -color "Green"
                 }

                 
                 Dolog -Message "Try to insert data to wmi...." -color "White"
                 try
                 {
                    Set-WmiInstance -Path \\.\root\cimv2:eptatoo -Arguments @{AdvertisementID=$AdvertisementID;ClientVersion=$ClientVersion;Computername=$Computername;InstallationType=$InstallationType;InstalledBeginTime=$InstalledBeginTimeGMT;InstalledEndTime=$InstalledEndTimeGMT;LoggedUser=$LoggedUser;MediaType=$MediaType;Organization=$Organization;PrevOperatingSystem=$PrevOperatingSystem;TaskSequenceName=$TaskSequenceName;TaskSequenceversion=$TaskSequenceversion;TSSequence=$TSSequence;TSSequenceTime=$TSSequenceTimeGMT}
                    Dolog -Message "Data sucessfully inserted to cimv2\EpTatoo...." -color "White"
                 }
                 catch
                 {
                    $txt = "Error inserting data to WMI -> " + $Error[0]
                    Dolog -Message "Error inserting data to cimv2\EpTatoo...." -color "Red"
                    Exit_Script 3
                 }
                 
                 
               }
             else
             {
                $txt = "Advertisement ID " + $AdvertisementID + " already existis!. Proceding without updating wmi"
                dolog -Message $txt -color "yellow" -LogLevel 2
             }
        }
        Catch [System.Management.Automation.PSArgumentException]
        {
            "Registry Key Property missing" 
        }
        Catch [System.Management.Automation.ItemNotFoundException]
        {
            "Registry Key itself is missing" 
        }

        Finally { $ErrorActionPreference = "Continue" }

     }
     Catch [System.Management.Automation.ItemNotFoundException]
     {
        $txt = "RegistryKey " + $registryPath + " does not exists"
        Dolog -Message $txt -color "Red" -LogLevel 3
        exit_script 3
     }

     Finally { $ErrorActionPreference = "Continue" } 


}

Function create_class
{

    $ErrorActionPreference = "stop"

    try
    {
        $newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null); 

        $newClass["__CLASS"] = "EPTatoo"; 

        $newClass.Qualifiers.Add("Static", $true)

        $newClass.Properties.Add("AdvertisementID",[System.Management.CimType]::String, $false)
        $newClass.Properties["AdvertisementID"].Qualifiers.Add("Key", $true)
        $newClass.Properties["AdvertisementID"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("ClientVersion",[System.Management.CimType]::String, $false)
        $newClass.Properties["ClientVersion"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("Computername",[System.Management.CimType]::String, $false)
        $newClass.Properties["Computername"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("InstallationType",[System.Management.CimType]::String, $false)
        $newClass.Properties["InstallationType"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("InstalledBeginTime",[System.Management.CimType]::DateTime, $false)
        $newClass.Properties["InstalledBeginTime"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("InstalledEndTime",[System.Management.CimType]::DateTime, $false)
        $newClass.Properties["InstalledEndTime"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("LoggedUser",[System.Management.CimType]::String, $false)
        $newClass.Properties["LoggedUser"].Qualifiers.Add("Read", $true)


        $newClass.Properties.Add("MediaType",[System.Management.CimType]::String, $false)
        $newClass.Properties["MediaType"].Qualifiers.Add("Read", $true)


        $newClass.Properties.Add("Organization",[System.Management.CimType]::String, $false)
        $newClass.Properties["Organization"].Qualifiers.Add("Read", $true)


        $newClass.Properties.Add("PrevOperatingSystem",[System.Management.CimType]::String, $false)
        $newClass.Properties["PrevOperatingSystem"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("TaskSequenceName",[System.Management.CimType]::String, $false)
        $newClass.Properties["TaskSequenceName"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("TaskSequenceversion",[System.Management.CimType]::String, $false)
        $newClass.Properties["TaskSequenceversion"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("TSSequence",[System.Management.CimType]::String, $false)
        $newClass.Properties["TSSequence"].Qualifiers.Add("Read", $true)

        $newClass.Properties.Add("TSSequenceTime",[System.Management.CimType]::DateTime, $false)
        $newClass.Properties["TSSequenceTime"].Qualifiers.Add("Read", $true)


        $newClass.Put()

        Dolog -Message 'Sucessfully create class EpTatoo' -LogLevel 1 -color "Green"
    }
    catch [System.Management.ManagementObject]
    {
        $txt= "Error Creating class EPTatoo" + $error[0].Exception
        Dolog -Message $txt -LogLevel 3 -color "Red"
        exit_script 3
    }
    Finally { $ErrorActionPreference = "Continue" } 

}
Function check_class_exist
{
param (
    [Parameter(Mandatory = $true)]
    [string]$class,
    [Parameter(Mandatory = $true)]
    [string]$namespace
    )

    $ErrorActionPreference = "stop"
    Dolog -Message "Verifying if class EPtatoo already exists" -color "White"

    try
    {
        $eptatoo = Get-WmiObject -Namespace 'ROOT\cimv2' -Class 'EpTatoo' 
        Dolog -Message 'Class Cimv2\EpTatoo already exists!' -LogLevel 1 -color "Green"
    }

    catch [System.Management.ManagementException]
    {

        $txt= "Error connecting to " + $error[0].Exception
        Dolog -Message $txt -LogLevel 3 -color "Red"
        Dolog -Message 'Class cimv2\EpTatoo does not exist' -color "Yellow"
        dolog -message "Trying to create the new class" -color white
        create_class  
    }
    catch
    {

        $txt= "Error connecting to " + $error[0].Exception
        Dolog -Message $txt -LogLevel 3 -color "Red"
        Dolog -Message 'Class cimv2\EpTatoo does not exist' -color "Yellow"
        dolog -message "Trying to create the new class" -color white
        create_class  
    }
    

    
    Finally { $ErrorActionPreference = "Continue" }

    
}

$DateTime = get-date -format u
$txt= "---------- PROCESSING EPTATOO ON " + $DateTime + " ----------"
dolog -Message $txt -color "White"
verify_logfile

check_tatoo_reg

check_class_exist "ROOT\cimv2" -class "EPTatoo"

regkeyExist


