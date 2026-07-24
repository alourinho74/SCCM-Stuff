Function check_dism_sfc
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Error_code
    )

    Dolog -message " " -loglevel 1 -color "White"
    Dolog -message "Check Problems with SCCM Windows Updates Log Files" -loglevel 1 -color "Cyan"

    switch ($Error_code) 
    {
        ("0x800705B4","0x800706BA")
        { 
            Dolog -Message "Found error $Error_code on file" -loglevel 3 -color "Red"
            $dism=$true
        }
        "0x800704C7"
        { 
            Dolog -Message "Found error $Error_code on file" -loglevel 3 -color "Red"
            $dism=$true
        }
        Default {$dism=$false}
    }
    
    if ($dism -eq $true)
    {
        while( -not ( ($choice= (Read-Host "Proceed to repair with dism and sfc /scannow? (Y/N)")) -match "y|n")){}
        if ($choice -eq "y" -or $choice -eq "y")
        {
            return $true      
        }
        
    }
    else 
    {
        Dolog "No definied action for the error"  -loglevel 2 -color "Yellow"
        return $false
    }

}
Function Find_ISST_Audio_Error
{
    param (
    [Parameter(Mandatory = $true)]
    [string]$linebefore,
    [Parameter(Mandatory = $true)]
    [string]$LastLine,
    [Parameter(Mandatory = $false)]
    [string]$setuptrue
    )

    $error_Exists = $false
    $searchstr = @("ISST Audio","Conexant HD Audio","Conexant SmartAudio HD","Synaptics HD Audio")

    #write-host "->" $setuptrue -ForegroundColor Magenta

    foreach ($err in $searchstr)
    {
        $errorfound = Select-String -Pattern $err -InputObject $linebefore
        if ($errorfound)
        {
            
            $strtxt = $LastLine -split '\\'
            $inffile = $strtxt[$strtxt.Length-1]
            
            $inffile = $inffile.Replace("cat","inf")
            
            $txt = "Found " + $err + " Driver Problem" 
            Dolog -Message $txt -LogLevel 3 -color "Red"
            if (Test-Path "\\$computername\c$\windows\inf\$inffile")
            {
                Dolog -Message "Uninstalling Driver $inffile" -LogLevel 3 -color "Red"
                psexec -d \\$ComputerName pnputil.exe -d $inffile -f
                $error_Exists = $true
            }
            else
            {
                Dolog -Message "File $inffile already uninstalled or missing!" -LogLevel 3 -color "Red" 
                $error_Exists = $true  
            }

            if ($setuptrue -ne "")
            {
                While( -not ( ($Continue = (Read-Host "Kill Setup Proccesses and try angain (y/n)?")) -match "y|n")){}
                if ($Continue -eq "N" -or $Continue -eq "n")
                {
                    Dolog -Message "Will not try to run setup again" -LogLevel 2 -color "Yellow"
                }
                else 
                {
                    try 
                    {
                        Dolog "Trying to kill setuphost.exe processes" -LogLevel 1 -color "White"
                        kill_proccess -proc_name "setuphost.exe" -waitseconds 2
                        Dolog "setuphost.exe terminated" -LogLevel 1 -color "Green"
                    }
                    catch 
                    {
                        Dolog "Error terminating setuphost.exe" -LogLevel 3 -color "Red"
                    }

                    try 
                    {
                        Dolog "Trying to kill wuauclt.exe processes" -LogLevel 1 -color "White"
                        kill_proccess -proc_name "wuauclt.exe" -waitseconds 2
                        Dolog "wuauclt.exe terminated" -LogLevel 1 -color "Green"
                    }
                    catch 
                    {
                        Dolog "Error terminating setuphost.exe" -LogLevel 3 -color "Red"
                    }

                    try 
                    {
                        Dolog "Trying to kill WindowsUpdateBox.exe processes" -LogLevel 1 -color "White"
                        kill_proccess -proc_name "WindowsUpdateBox.exe" -waitseconds 2
                        Dolog "WindowsUpdateBox.exe terminated" -LogLevel 1 -color "Green"
                    }
                    catch 
                    {
                        Dolog "Error terminating wuauclt.exe" -LogLevel 3 -color "Red"
                    }
                }
            }
            return $true
        }
        
    }
    #$errorfound = Select-String -Pattern $searchstr -InputObject $linebefore

    if ($error_Exists -eq $false)
    {
        return $false
    }


}

function fn18
{
    param (
    [Parameter(Mandatory = $true)]
    [string]$fn18_Action,
    [Parameter(Mandatory = $false)]
    [xml]$xml_file
    )

    

    if ($fn18_Action -eq "Hardware") 
    {
        $18xmlfile = (Get-ChildItem ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\*18.xml')  | sort LastWriteTime | select -last 1).name
        #Write-Host $18xmlfile -ForegroundColor Magenta

        [xml]$18xml = Get-Content ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\' + $18xmlfile)
        #Write-Host $18xml -ForegroundColor yellow
        foreach ($i in $18xml.CompatReport.Hardware.HardwareItem)
        {
            if($i.CompatibilityInfo.BlockingType -eq "Hard")
            {
                Dolog -message "Check Hardware Problems" -loglevel 1 -color "Cyan"
                Dolog -message " " -loglevel 1 -color "White"
                Dolog  -message "Found a hardware problem!" -LogLevel 3 -color "Red"
                $txt = "Tile: " + $i.CompatibilityInfo.Title
                Dolog -message $txt -LogLevel 1 -color "White"

                $txt = "Message: " + $i.CompatibilityInfo.Message
                Dolog -message $txt -LogLevel 1 -color "White"
                
                $txt = "Link: " + $i.Link.Target
                Dolog -message $txt -LogLevel 1 -color "White"
            }

        }
    }


    if ($fn18_Action -eq "Devices") 
    {
        #$InfNone = (Get-WmiObject -ComputerName $ComputerName -Class Win32_PnPSignedDriver | Where-Object Infname -eq $null ).DeviceID
        #$CCMUpdateCatalog = get-ciminstance -CimSession $cimsession -namespace "ROOT\ccm\SoftwareUpdates\WUAHandler" -query "SELECT * FROM CCM_UpdateSource WHERE UniqueId='{312C0238-884C-49D7-9838-BB95883FA1B3}'"
        $InfNone = (get-ciminstance -CimSession $cimsession -ClassName Win32_PnPSignedDriver | Where-Object Infname -eq $null ).DeviceID
        foreach ($i in  $18xml.CompatReport.DriverPackages.DriverPackage ) 
        {  
            
            if($i.BlockMigration -eq "True")
            {

                #$DEV = (Get-WmiObject -ComputerName $ComputerName Win32_PnPSignedDriver -filter "InfName=""$($I.Inf)""")
                #$CCMUpdateCatalog = get-ciminstance -CimSession $cimsession -namespace "ROOT\ccm\SoftwareUpdates\WUAHandler" -query "SELECT * FROM CCM_UpdateSource WHERE UniqueId='{312C0238-884C-49D7-9838-BB95883FA1B3}'"
                $DEV = (get-ciminstance -CimSession $cimsession  -ClassName Win32_PnPSignedDriver -filter "InfName=""$($I.Inf)""")
                $input_file = "\\$computername\c$\Windows\Inf\" + $I.inf
                $result = handle_inf $input_file

                
                    
                $finaltxt = $result.split(",")
                $infProvider = $finaltxt[0]
                $infDrvVersion = $finaltxt[1]
                $InfDrvDate = $finaltxt[2]
                $InfDeviceName = $finaltxt[3]
                $infDeviceFile = $finaltxt[4]
                $infDeviceClass = $finaltxt[5]
                
                if ( $DEV )
                {
                    #Write-Host $result -ForegroundColor cyan
                    $DEV | % {
                        $txt = "{0,-12}{1,-7}{2,-7}{3,-25}{4,-18}{5,-15}{6,-50}{7,-20}{8}" -f $I.Inf, $I.BlockMigration, $I.HasSignedBinaries,$infProvider,$infDrvVersion,$InfDrvDate,$InfDeviceName,$infDeviceFile,$infDeviceClass
                        Dolog -Message $txt -LogLevel 1 -color "White"
                    
                    }
                }
                else
                {
                    #Write-Host $result -ForegroundColor yellow
                    $Script:DevName = ""
                    $InfNone | % { 
                        $X = ($_.replace('\','\\'))
                        if ( (Get-Content ("\\$ComputerName\C$\Windows\inf\" + $I.Inf) -EA SilentlyContinue ) -match "$X" )
                        {
                            $Script:DevName = "$X"
                        }
                    }
                    $txt = "{0,-12}{1,-7}{2,-7}{3,-25}{4,-18}{5,-15}{6,-50}{7,-20}{8}" -f $I.Inf, $I.BlockMigration, $I.HasSignedBinaries,$infProvider,$infDrvVersion,$InfDrvDate,$InfDeviceName,$infDeviceFile,$infDeviceClass
                    Dolog -Message $txt -LogLevel 1 -color "White"
                }
            }
        }
    }
    

    if ($fn18_Action -eq "Programs") 
    {
        #$line = ("-"*180)
        #Dolog -message $line -loglevel 1 -color "White"
        $18xmlfile = (Get-ChildItem ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\*18.xml')  | sort LastWriteTime | select -last 1).name
        #Write-Host $18xmlfile -ForegroundColor Magenta

        [xml]$18xml = Get-Content ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\' + $18xmlfile)
        #Write-Host $18xml -ForegroundColor yellow
        foreach ($i in  $18xml.CompatReport.Programs.Program) 
        {
            if ($i.CompatibilityInfo.BlockingType -eq "hard")
            {
                Dolog -message " " -loglevel 1 -color "White"
                Dolog -message "Check Problems with Programs" -loglevel 1 -color "Cyan"
                Dolog -message " " -loglevel 1 -color "White"
                Dolog -Message "Found Blocking Software" -LogLevel 3 -color "Red"
                $txt = $i.name + " is preventing windows to migrate!"
                Dolog -Message $txt -LogLevel 1 -color "Yellow"
                uninstall -program $i.name
            }
            
        }
    }

    
    if ($fn18_Action -eq "xml21")
    {
        
        $21xmlfile = (Get-ChildItem ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\*21.xml')  | sort LastWriteTime | select -last 1).name
        #Write-Host $21xmlfile -ForegroundColor yellow
        if ($21xmlfile)
        {
            [xml]$21xml = Get-Content ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\' + $21xmlfile)
            
            foreach ($i in $21xml.CompatReport.Hardware.HardwareItem)
            {
                if ($i.CompatibilityInfo.BlockingType -eq "Hard")
                {
                    Dolog -message " " -loglevel 1 -color "White"
                    Dolog -Message "Found Blocking Problem" -LogLevel 3 -color "Red"
                    Dolog -message $i.Action.Name -LogLevel 1 -color "Yellow"
                }

            }
        }
        

    }
    
}

Function read_setupdiag_registry
{
    #$computername = "td02008449"
    #$ErrorActionPreference = "silentcontinue"
    #Invoke-Command -Computer $computername -ScriptBlock {Get-ItemProperty -Path: HKLM:SYSTEM\Setup\setupdiag\results\ -Name TimeOutValue}
    $setupdiagdata=Invoke-Command -Computer $ComputerName -ScriptBlock {Get-ItemProperty -Path: HKLM:SYSTEM\Setup\setupdiag\results\ -ErrorAction SilentlyContinue}
    #$h

    if ($setupdiagdata)
    {
        if ($setupdiagdata.DateTime)
        {
            $linha = "Data              :" + $setupdiagdata.DateTime
            Dolog -message $linha -color "White"
        }
        else
        {
            $linha = "Data              :" + "N/A"
            Dolog -message $linha -color "White"    
        }

        if ($setupdiagdata.FailureData)
        {
            $linha = "Failure Data      :" + $setupdiagdata.FailureData
            Dolog -message $linha -color "White"
        }
        else
        {
            $linha = "Failure Data      :" + "N/A"
            Dolog -message $linha -color "White"    
        }

        if ($setupdiagdata.Remediation)
        {
            $linha = "Remediation       :" + $setupdiagdata.Remediation
            Dolog -message $linha -color "White"
        }
        else
        {
            $linha = "Remediation       :" + "N/A"
            Dolog -message $linha -color "White"    
        }

        if ($setupdiagdata.FailureDetails)
        {
            $linha = "Failure Details   :" + $setupdiagdata.FailureDetails
            Dolog -message $linha -color "White"
        }
        else
        {
            $linha = "Failure Details   :" + "N/A"
            Dolog -message $linha -color "White"    
        }
        
        #Dolog -message  -color "White"
        #Dolog -message  -color "White"
        #Dolog -message  -color "White"
    }
    else
    {
        Dolog -message "SetupDiag Registry Keys does not exists" -color "Yellow"
    }   
}
Function Feature_update
{
    $PantherDir = "\\"+$ComputerName+"\c$\$"+"WINDOWS.~BT\Sources\Panther"
    $WinDir = "\\"+$ComputerName+"\c$\Windows\"
    $aux_error=$false
    $SetupactWin10Log = $PantherDir+"\setupact.log"
    $SetuperrWin10Log = $PantherDir+"\setuperr.log"
    $fileformat = $true
    $setupactlog = "\\$ComputerName\" + 'c$\$WINDOWS.~BT\Sources\Panther\setupact.log'

    $setupdiagresultsxml =  "\\$ComputerName\" + 'c$\Windows\Logs\SetupDiag\setupdiagresults.xml'

    $uninst = "\\$Computername\c$\Windows\Temp\uninsinf.cmd"
    $uninstlog = "\\$Computername\c$\Windows\Temp\uninsinf.log"
    New-Item -path $uninst -force |out-null
    New-Item -path $uninstlog -force |out-null 

    if (Test-Path $setupdiagresultsxml -ErrorAction SilentlyContinue)
    {
        Dolog -Message "C:\Windows\Logs\SetupDiag\Setupdiagresults.xml Exists!!!!" -LogLevel 2 -color "Yellow"
        Dolog -message " " -loglevel 1 -color "White"
        [xml]$setupdiag = Get-Content $setupdiagresultsxml

        if ($setupdiag.SetupDiag.LogErrorLine)
        {
            Dolog -message $setupdiag.SetupDiag.LogErrorLine -loglevel 1 -color "White"
        }
        if ($setupdiag.SetupDiag.ProfileName)
        {
            Dolog -message $setupdiag.SetupDiag.ProfileName -loglevel 1 -color "White"
        }
        
        if ($setupdiag.SetupDiag.FailureDetails)
        {
            Dolog -message $setupdiag.SetupDiag.FailureDetails -loglevel 1 -color "White"
        }
        
        if ($setupdiag.SetupDiag.Remediation)
        {
            Dolog -message $setupdiag.SetupDiag.Remediation -loglevel 1 -color "White"
        }
        
        Dolog -message " " -loglevel 1 -color "White"
    }
    

    if (Test-Path $SetuperrWin10Log -ErrorAction SilentlyContinue)
    {
        $FirstXLogLine = (Get-Content -Path $SetupactWin10Log -First 1).Split(",")                        
        $LastXLogLine = (Get-Content -Path $SetupactWin10Log -Tail 1).Split(",")
        $FirstXErrLogLine = (Get-Content -Path $SetuperrWin10Log -First 1).Split(",")
        $LastXErrLogLine = (Get-Content -Path $SetuperrWin10Log -Tail 1).Split(",")
        $LastXErrLogLine = (Get-Content -Path $SetuperrWin10Log -Tail 1).Split(",")
        
        #Write-Host $FirstXLogLine -ForegroundColor Magenta
        #Write-Host $LastXLogLine -ForegroundColor Magenta
        #Write-Host $FirstXErrLogLine -ForegroundColor Magenta
        #Write-Host $LastXErrLogLine -ForegroundColor Magenta
        try 
        {
            $FirstLogLineDate = [datetime]::parseexact($FirstXLogLine[0], 'yyyy-MM-dd HH:mm:ss', $null)                                                
            $FirstLogErrLineDate = [datetime]::parseexact($FirstXErrLogLine[0], 'yyyy-MM-dd HH:mm:ss', $null)
            $LastLogLineDate = [datetime]::parseexact($LastXLogLine[0], 'yyyy-MM-dd HH:mm:ss', $null)
            $LastLogErrLineDate = [datetime]::parseexact($LastXErrLogLine[0], 'yyyy-MM-dd HH:mm:ss', $null)    
        }
        catch 
        {
            
            $fileformat = $false
        }
        
        if ($fileformat -eq $false)
        {
            #Dolog -Message "Format of file setupact.log or setuperr.log is not correct. Cannot continue automatic debug" -LogLevel 3 -color "Red"
            Dolog -Message "Format of file setupact.log or setuperr.log is not correct." -LogLevel 3 -color "Red"
            #exit
        }
        
        #$ProcessActiveWin10FU = Get-WmiObject win32_process -ComputerName $ComputerName -filter "name='WindowsUpdateBox.exe'" |  Select-Object @{Name='CreationDate'; Expression={ [System.Management.ManagementDateTimeConverter]::ToDateTime($_.CreationDate)}},name,processId,@{Name='WorkingSet (MB)';Expression={($_.WorkingSetSize/1MB)}},commandLine
        #$CCMUpdateCatalog = get-ciminstance -CimSession $cimsession -namespace "ROOT\ccm\SoftwareUpdates\WUAHandler" -query "SELECT * FROM CCM_UpdateSource WHERE UniqueId='{312C0238-884C-49D7-9838-BB95883FA1B3}'"
        $ProcessActiveWin10FU = get-ciminstance -CimSession $cimsession -ClassName "win32_process"  -filter "name='WindowsUpdateBox.exe'" |  Select-Object @{Name='CreationDate'; Expression={ [System.Management.ManagementDateTimeConverter]::ToDateTime($_.CreationDate)}},name,processId,@{Name='WorkingSet (MB)';Expression={($_.WorkingSetSize/1MB)}},commandLine

        if ($ProcessActiveWin10FU)
        {
            $txt = "Process started at " + $ProcessActiveWin10FU.CreationDate
            Dolog -message $txt -LogLevel 1 -color "White"
            #Write-Host $txt -ForegroundColor White
            $txt = "Setup, running at " + ($LastLogLineDate-$FirstLogLineDate).Hours + "h" + ($LastLogLineDate-$FirstLogLineDate).Minutes + "m"
            Dolog -message $txt -LogLevel 1 -color "White"
            #Write-Host $txt -ForegroundColor White

            While( -not ( ($Continue = (Read-Host "Continue debugging Feature Updates Errors (y/n)?")) -match "y|n")){}
            if ($Continue -eq "N" -or $Continue -eq "n")
            {
                exit
            }
        }
        $t = ("-"*180)
        $header = "{0,-25}{1,-25}{2,-7}{3}" -f "Info", "Date", "Message", ""
        Dolog -Message $t -LogLevel 1 -color "White"
        Dolog -Message $header -LogLevel 1 -color "White"
        
        $txt = "{0,-25}{1,-25}{2,-7}{3}" -f "First log line in ", $FirstLogLineDate, "",""
        Dolog -Message $txt -LogLevel 1 -color "White"
        #Write-Host $txt 

        $txt = "{0,-25}{1,-25}{2,-7}{3}" -f "First error in ", $FirstLogErrLineDate, $FirstXErrLogLine[1],""
        Dolog -Message $txt -LogLevel 1 -color "White"
        #Write-Host $txt 

        $txt = "{0,-25}{1,-25}{2,-7}{3}" -f "Last error in ", $LastLogErrLineDate, $LastXErrLogLine[1],""
        Dolog -Message $txt -LogLevel 1 -color "White"
        #Write-Host $txt 

        $txt = "{0,-25}{1,-25}{2,-7}{3}" -f "Last log line in ", $LastLogLineDate, $LastXLogLine[1],""
        Dolog -Message $txt -LogLevel 1 -color "White"
        Dolog -Message " " -LogLevel 1 -color "White"
        #Write-Host $txt
        #Write-Host ""

        $aux_h = ($LastLogLineDate-$FirstLogLineDate).Hours
        $aux_m = ($LastLogLineDate-$FirstLogLineDate).Minutes
        $aux = "" + $aux_h + "h"+ $aux_m + "m" + ""
        $txt = "{0,-25}{1,-25}{2,-7}{3}" -f "Setup last ", $aux, "",""
        Dolog -Message $txt -LogLevel 1 -color "White"
        #Write-Host $txt

        Dolog -Message $t -LogLevel 1 -color "White"
        Dolog -message "Check  Setup Diag Registry Keys" -color "Cyan"

        read_setupdiag_registry

        Dolog -Message $t -LogLevel 1 -color "White"

        
        #Used to happen in Windows 10 migrations
        #commented for win11
        <#
        Dolog -message "Check if ISST Audio Error is present" -LogLevel 1 -color "Yellow"
        $maxnumlines=100
        for ($i=$maxnumlines;$i -ge 1;$i--)
        {

            $LastLogLine = (Get-Content -Path $SetupactWin10Log -Tail $i).Split(",")  
            if ($i -ge 2)
            {
                $LastLogLineminus1 = (Get-Content -Path $SetupactWin10Log -Tail ($i-1)).Split(",")
                
                if ($LastLogLineminus1[1] -ne $null)
                {
                    $aux_error = Find_ISST_Audio_Error -linebefore $LastLogLine[1] -LastLine $LastLogLineminus1[1] -setuptrue $ProcessActiveWin10FU
                    if ($aux_error -eq $true)
                    {
                        break
                    }
                }          
                
            }
        }
        if ($aux_error -eq $false)
        {
            Dolog -Message "ISST Audio Error not found" -LogLevel 1 -color "Green"
        }
        
        #>
        $Err_18 = Get-ChildItem $PantherDir -File -Filter *18.xml
       
        $filters = @('BlockMigration="True"', 'BlockingType="Hard"')
        foreach ( $file in $Err_18)
        {
            
            #$Err18Content = Get-Content $PantherDir\$file | Select-String -pattern $filters
            $Err18Content = Get-Content $file | Select-String -pattern $filters
        }

        $Error18Split = (($Err18Content -Split('<DriverPackage Inf="')) -Split '" BlockMigration="True') -match '.inf'
            
        foreach ($errortxt in $Error18Split)
        {
            
            if ($errortxt -like "*.inf")
            {
                if (Test-Path $WinDir"Inf\"$errortxt)
                {
                    $IHaveInf = $True
                }
            }
            if ($errortxt -like '*BlockingType="Hard"*')
            {
                $hardblock = $true
            }
        }

        if($hardblock -eq $True)
        {
            #$line = ("-"*170) 
            #Dolog -Message $line -LogLevel 1 -color "White"
            #Write-Host "ENTREI" -ForegroundColor Magenta
            fn18 -fn18_Action "Hardware" 
            fn18 -fn18_Action "Programs"
        }

        if($IHaveInf -eq $True)
        {
            #write-host "INF" -foreground magenta
            $18xmlfile = (Get-ChildItem ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\*18.xml')  | sort LastWriteTime | select -last 1).name

            [xml]$18xml = Get-Content ("\\$ComputerName" + '\c$\$WINDOWS.~BT\Sources\Panther\' + $18xmlfile)
                    
                            Dolog -message " " -loglevel 1 -color "White"
                            Dolog -message "Check Problems with Device Drivers" -loglevel 1 -color "Cyan"


            $t = ("-"*170) 
            
            $r = "{0,-12}{1,-7}{2,-7}{3,-25}{4,-18}{5,-15}{6,-50}{7,-20}{8}" -f "InfName", "Block", "Signed", "Manufacturer", "DriverVersion", "Driver Date", "DeviceName","Driver File" ,"Driver Class"
            Dolog -Message $t -LogLevel 1 -color "White"
            Dolog -Message $r -LogLevel 1 -color "White"
            Dolog -Message $t -LogLevel 1 -color "White"

                            

            fn18 -fn18_Action "Devices" -xml_file $18xml
            $t = ("-"*170)
            Dolog -Message $t -LogLevel 1 -color "White"

            $InfUninst = Read-Host "Uninstall Blocking DriverPackages?((N)/(1 a 1)/(All))"
            
            $InisTot = @()
            
            foreach ($InfFile in $Error18Split)
            {
                $InisTot += $InfFile
                if ($InfFile -like "*.inf")
                {
                    if ((Test-Path $WinDir"Inf\"$InfFile) -AND !(Test-Path $WinDir"Inf\"$InfFile".bck"))
                    {
                        if ( $InfUninst -eq "1")
                        {
                            $1to1 = Read-Host "Uninstall $InfFile ? (y/n)"
                            if($1to1 -eq "y" -or $1to1 -eq "y")
                            {
                                try 
                                {
                                    $txt = "Psexec pnptil Uninst " + $InfFile + " started"
                                    Dolog -Message $txt -LogLevel 1 -color "White"
                                    psexec -d \\$ComputerName pnputil.exe -d $InfFile -f 2>$null    
                                }
                                catch 
                                {
                                    Dolog -Message "Error psexec pnputil" -LogLevel 2 -color "Red"
                                }
                            }
                        }
                        Add-Content "pnputil -d $InfFile -f >>c:\windows\temp\uninsinf.log" -Path $uninst
                    }
                    #else
                    #{
                    #    $txt = $InfFile + " does not exists or already renamed"
                    #    Dolog -Message $txt -LogLevel 2 -color "Red"
                    #}
                }
            }
            #if ( $InfUninst -eq "All")
            #{
            #    $txt = "About to run command psexec... " + $PSexecArgument  
            #    Dolog -Message $txt -LogLevel 1 -color "White"
            #    psexec -s \\$ComputerName c:\windows\temp\uninsinf.cmd
            #}
            
            
        }

        
        #Dolog -Message $t -LogLevel 1 -color "White"

        fn18 -fn18_Action "xml21"

        #$ErrLogLine_2 = (Get-Content -Path $SetuperrWin10Log -Tail 1).Split(",")

        if (Test-Path $SetuperrWin10Log)
        {
            $setup_error = (get-content -Path $SetuperrWin10Log).Split("=").Trim() | Select-Object -Last 1
            if ($setup_error -ne "")
            {
                $godism = check_dism_sfc $setup_error    
            }
            
        }
        
        #$setup_error = (get-content -Path $SetuperrWin10Log).Split("=").Trim() | Select-Object -Last 1
        #$godism = check_dism_sfc $setup_error

        if ($godism -eq $true)
        {
            Add-Content "DISM /Online /Cleanup-Image /RestoreHealth" -Path $uninst
            Add-Content "sfc /scannow" -Path $uninst
            Add-Content "pause" -Path $uninst
        }

        if ($InfUninst -eq "All" -or $godism -eq $true)
        {
            $txt = "About to run command psexec to uninstall conflicting drivers and/or run dism.exe"  
            Dolog -Message $txt -LogLevel 1 -color "White"
            $argument = "-s \\$ComputerName c:\windows\temp\uninsinf.cmd"
            Start-Process -filepath "psexec.exe" -ArgumentList $argument
        }
        if ($godism -eq $true)
        {
            Dolog "Dism and sfc are running. This will take a while. At the end, please restart sccm/wuagent services" -loglevel 1 -color "White"
            Remove-Item -Path \\$computername\c$\windows\logs\dism\dism.log -Force
            Remove-Item -Path \\$computername\c$\windows\logs\cbs\cbs.log -Force
            if (Test-Path $setupactlog)
            {
                $filesize = (Get-Item $setupactlog).Length/1MB
                

                if ($filesize -le 10)
                {
                    cmtrace.exe "\\$ComputerName\c$\windows\ccm\logs\ccmexec.log" "\\$ComputerName\c$\windows\ccm\logs\PolicyAgent.log" "\\$ComputerName\c$\windows\ccm\logs\Execmgr.log" "\\$ComputerName\c$\windows\logs\Dism\dism.log" "\\$ComputerName\c$\windows\logs\Cbs\cbs.log" "\\$ComputerName\c$\windows\ccm\logs\WUAHandler.log" $setupactlog      
                    exit
                }
                else 
                {
                    cmtrace.exe "\\$ComputerName\c$\windows\ccm\logs\ccmexec.log" "\\$ComputerName\c$\windows\ccm\logs\PolicyAgent.log" "\\$ComputerName\c$\windows\ccm\logs\Execmgr.log" "\\$ComputerName\c$\windows\logs\Dism\dism.log" "\\$ComputerName\c$\windows\logs\Cbs\cbs.log" "\\$ComputerName\c$\windows\ccm\logs\WUAHandler.log"
                    exit
                }
            }
        }
        
    }

}

