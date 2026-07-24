Param (
[Parameter(Mandatory=$true, Position=1)]
[string]$menu_action,

[Parameter(Mandatory=$false, Position=2)]
[int]$Hours_without_restart,

[Parameter(Mandatory=$false, Position=3)]
[int]$Restart_Time_Out,

[Parameter(Mandatory=$false, Position=4)]
[int]$restartMaxPostpone,

[Parameter(Mandatory=$false, Position=5)]
[string]$restartDescriptions,

[Parameter(Mandatory=$false, Position=6)]
[string]$restart_Action,

[Parameter(Mandatory=$false, Position=7)]
[string]$Abort_Action

)

$win_dir = $env:windir
$strComputerName = $env:COMPUTERNAME

$logfile = New-Item -Path $win_dir"\temp\RestartDTM.log" -ItemType "file" -Force


$workdir = "C:\windows\Temp\"
$EventLogSource = 'RestartDTM'$EventLogApplication = 'Application'

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

}

Function handelEventlogSource
{

    Set-StrictMode -Version 2.0
    [bool]$ApplicationEventLogExists = [System.Diagnostics.EventLog]::Exists($EventLogApplication )    [bool]$MyEventLogSourceExists = [System.Diagnostics.EventLog]::SourceExists($EventLogSource)
    
    if(!$MyEventLogSourceExists)    {
        $text = "About to create event log source " + $EventLogSource        Dolog -message $text -color "White"        New-EventLog -LogName $EventLogApplication -Source $EventLogSource
        
        $text = "Finished create event log source " + $EventLogSource        Dolog -message $text -color "White"    }

}

Function Force_restart()
{
    param(
        [string]$msg_text
    )
    
    $timeOut = ($Restart_Time_Out*60)
    $restartMaxPostponehours = ($restartMaxPostpone*60) 

    If ( (Get-Process "ShutdownTool" -ErrorAction SilentlyContinue) ) 
    {
        $ExitRC = 10002
        Dolog -Message 'Already running ShutdownTool' -LogLevel 2 -color "Yellow"
        Write-EventLog -LogName $EventLogApplication -Source $EventLogSource -EventID $ExitRC -EntryType Error -Message "Already running ShutdownTool."
        [System.Environment]::Exit($ExitRC)
    }
    else
    {
        If ((Test-Path ".\Files\ShutdownTool.exe") -eq $false) 
        {
            $ExitRC = 10003
            Dolog -Message 'Cant find ShutdownTool.exe' -LogLevel 3 -color "Red"
            Write-EventLog -LogName $EventLogApplication -Source $EventLogSource -EventID $ExitRC -EntryType Error -Message "Cant find ShutdownTool.exe."
            [System.Environment]::Exit($ExitRC)
        }
        else 
        {

            $text = "Calling restart with ShutdownTool with timeout= " + $Restart_Time_Out + " minutes and maximum postpone time of " + $restartMaxPostpone + "hours"
            DOlog -Message $text -color "White"

            $commandline = ".\files\ShutdownTool.exe"

            if ($Abort_Action -eq "y")
            {
                $param = "/d:""$restartDescriptions"" /t:$timeOut /m:$restartMaxPostponehours /$restart_Action"

            } 
            else
            {
                $param = "/d:""$restartDescriptions"" /t:$timeOut /m:$restartMaxPostponehours /$restart_Action /c"
            }
            
            $text = "Process in memory...Waiting for user action to restart computer"
            $msg_text = $msg_text + "." + $text

            Dolog -Message $text -color "White"
            Write-EventLog -LogName $EventLogApplication -Source $EventLogSource -EventID 0 -EntryType Information -Message $msg_text
            $ExitRC = (Start-Process -FilePath $commandline -ArgumentList $param -Wait -PassThru).ExitCode
            $text = "Scripted terminated with return code " + $ExitRC
            
            
            
            
            if ($ExitRC -ne 0)
            {
                Write-EventLog -LogName $EventLogApplication -Source $EventLogSource -EventID $ExitRC -EntryType Error -Message "DTM Restart Script Failed to execute."
            }
            Dolog -Message $text -color "White"
            [System.Environment]::Exit($ExitRC)
        }
    }

}
function Get-SystemUptime            
{
    try
    {          
        $operatingSystem = Get-WmiObject Win32_OperatingSystem                
        return [Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LastBootUpTime)            
    }
    catch
    {
        $Exception = $_
        $text = "Can not connect to machine wmi. Error " + $Exception.Exception.Message
        Dolog -Message $text -LogLevel 3 -color "red"
        [System.Environment]::Exit($Exception.Errorcode)
    }
}

Function UpTime()
{
param(
)
    
    $boot = Get-SystemUptime
    $Now=(GET-DATE)

    $hours = (NEW-TIMESPAN –Start $boot –End $Now).Hours
    $n_days = (NEW-TIMESPAN –Start $boot –End $Now).Days

    $text = "Last Restart = " + $boot
    Dolog -Message $text -color "White"

    $text = "Days without Restart = " + $n_days
    Dolog -Message $text -color "White"

    $text = "Hours without Restart = " + $hours
    Dolog -Message $text -color "White"

    if (restart_pending)
    {
        $text = "There is a restart pending operation. Exiting without restart"
        Dolog -Message $text -color "Red"  
        $exitRC = 10001
        Write-EventLog -LogName $EventLogApplication -Source $EventLogSource -EventID $ExitRC -EntryType Warning -Message "DTM Restart Script did not execute, because there is a reboot operation pending."
        [System.Environment]::Exit($exitRC) 
    }

    if ($n_days -ge 1)
    {
        $hours = ($n_days * 24) + $hours
    }
    
    
    if ($hours -ge $Hours_without_restart)
    {
        $text = "The computer does not restart since " + $hours + " hours. Is outside the window of " + $Hours_without_restart + " hours without restart"
        DoLog -Message $text -color "Red"
        #Force_restart $hours $text
        Force_restart $text
    }
    else
    {
        $text = "The computer does not restart since " + $hours + " hours. Restart is within the control Window of " + $Hours_without_restart + " hours"
        DoLog -Message $text -color "Green"
        $ExitRC = 10000
        Write-EventLog -LogName $EventLogApplication -Source $EventLogSource -EventID $ExitRC -EntryType Warning -Message $text
        [System.Environment]::Exit($ExitRC)
    }
}


Function restart_pending
{

    # Local HKLM
    $HKLM = [UInt32] "0x80000002"
    $wmiRegistry = [WMIClass] "\\.\root\default:StdRegProv"
 
    #Default
    $PendingReboot = $false
 <#
    # CBS - Reboot Required ?
    $RegSubKeysCBS = $wmiRegistry.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
    if ($RegSubKeysCBS.sNames -contains "RebootPending") { 
        Dolog -Message 'Component Based Servicing have a reboot pending' -LogLevel 3 -color "Red"
        $PendingReboot = $true
    }
                             
    # Windows Update - Reboot Required?
    $RegistryWUAU = $wmiRegistry.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
    if ($RegistryWUAU.sNames -contains "RebootRequired") {
        Dolog -Message 'Windows Update have a reboot required' -LogLevel 3 -color "Red"
        $PendingReboot = $true
    }
 
    ## Pending FileRenameOperations ?
    $RegSubKeySM = $wmiRegistry.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
    If ($RegSubKeySM.sValue) {
        #$RegSubKeySM.sValue | ForEach-Object { 
            #If ($_.Trim() -ne '') {
                Dolog -Message 'Pending FileRename operation' -LogLevel 3 -color "Red"
            #}
       # }
        $PendingReboot = $true
    }
 #>
    # ConfigMgr - Pending reboot ?
    TRY {
        $CCMClientSDK = Invoke-WmiMethod -NameSpace "ROOT\ccm\ClientSDK" -Class "CCM_ClientUtilities" -Name "DetermineIfRebootPending" -ErrorAction Stop
 
        If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
            Dolog -Message 'ConfigMgr have reboot pending' -LogLevel 3 -color "Red"
            $PendingReboot = $true
        }
    } CATCH {
        Dolog -Message 'Cant talk to ConfigMgr Agent' -LogLevel 3 -color "Red"
    }
 
    $text = "Pending reboot: " + $($PendingReboot)
    Dolog -Message $text -LogLevel 3 -color "Red"
    Return $PendingReboot
}

Function menu()
{
param (

    [int]$action
)
    $text = "starting restart routine on " + $strcomputername
    Dolog  -Message $text -color "white"

    switch ($action)
    {
        #Display restart Popup if boottime is upper than parameter
        1 {UpTime}
        #Display restart Popup if there is a pending restart
        2 {if (restart_pending) {Force_restart ""}}
    }

}

handelEventlogSource

menu $menu_action