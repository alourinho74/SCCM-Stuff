Function parse_log_file
{
param(
    [Parameter(Mandatory = $false)]
    [string]$filename,
    [Parameter(Mandatory = $false)]
    [int]$tail,
    [Parameter(Mandatory = $false)]
    [int]$line_number
    )


    $check_file = Test-Path -Path $filename

    if (!$check_file)
    {
        
        if ($filename -eq "\\$ComputerName\c$\windows\ccmsetup\logs\ccmsetup.log")
        {
            Dolog -Message "CCMSetup.log does not exist!!!!" -LogLevel 1 -color "Red"
        } 
        return $false    
    }
   
    #Write-Host "Tail = $tail" -ForegroundColor Green
    try
    {

        if ($line_number -eq 0)
        {
            $LastLogLine = Get-Content -Path $filename -Tail $tail    
        }
        else 
        {
            #Write-Host "line number = $line_number"
            $LastLogLine = Get-Content -Path $filename -Tail $tail| select-object -First 1 -Skip $line_number
           # write-host -$LastLogLine -ForegroundColor Green
        }

        #write-host $LastLogLine -BackgroundColor Red -ForegroundColor White

        #$LastLogLine = Get-Content -Path $filename -Tail $tail | %{
        $LastLogLine | Foreach-object{   
                $_ -match '\<\!\[LOG\[(?<Message>.*)?\]LOG\]\!\>\<time=\"(?<Time>.+)(?<TZAdjust>[+|-])(?<TZOffset>\d{2,3})\"\s+date=\"(?<Date>.+)?\"\s+component=\"(?<Component>.+)?\"\s+context="(?<Context>.*)?\"\s+type=\"(?<Type>\d)?\"\s+thread=\"(?<TID>\d+)?\"\s+file=\"(?<Reference>.+)?\"\>' | Out-Null
                [pscustomobject]
                @{
                    UTCTime = [datetime]::ParseExact($("$($matches.date) $($matches.time)$($matches.TZAdjust)$($matches.TZOffset/60)"),"MM-dd-yyyy HH:mm:ss.fffz", $null, "AdjustToUniversal")
                    LocalTime = [datetime]::ParseExact($("$($matches.date) $($matches.time)"),"MM-dd-yyyy HH:mm:ss.fff", $null)
                    FileName = $FileName
                    Component = $matches.component
                    Context = $matches.context
                    Type = $matches.type
                    TID = $matches.TID
                    Reference = $matches.reference
                    Message = $matches.message  
                }            
            }
            #Write-Host $LastLogLine -ForegroundColor Cyan
            #Write-Host $LastLogLine.message -ForegroundColor Cyan
            #read-host

            
        return $LastLogLine
    }
    catch 
    {
        $txt = "Unable to parse file " + $filename
        Dolog -message $txt -LogLevel 1 -color "Red"
        #Write-Host $txt
    }
}

Function handel_error
{
param (
    [Parameter(Mandatory = $true)]
    [string]$Errortxt
)

    switch ($Errortxt)
    {
        "not enough disk space" 
        {
            Write-Host $Errortxt -ForegroundColor Cyan
        }
        "MSI: Could not open key: HKEY_LOCAL_MACHINE\Software\" 
        {
            Write-Host $Errortxt -ForegroundColor Cyan
        }
        
        "0x80070643"
        {
            #repair_ccmsetup
            mof_comp
            break
        }
        
        "0x8007042c"
        {
            Full_repair
            break
        }
        "0x80041013"
        {
            Full_repair
            break
        }
        "0x80072ee5"
        {
            Full_repair
            break
        }
        "MAXDRIVE or MAXDRIVESPACE" 
        {
            repair_ccmsetup
            break
        }
        "Next retry in 10 minute(s)..."
        {
            Dolog -Message "Possible problem with agent Setup" -loglevel 2 -color "Red"
            While( -not ( ($choice = (Read-Host "Proceed with repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Full_repair
                break
            }
        }
        "[Found Microsoft Application Root Cert]"
        {
            Dolog -Message "Possible problem with agent Setup" -loglevel 2 -color "Red"
            While( -not ( ($choice = (Read-Host "Proceed with repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Full_repair
                break
            }
        }


        "0x80004005"
        {
            Dolog -Message "Possible problem with agent Setup" -loglevel 2 -color "Red"
            While( -not ( ($choice = (Read-Host "Proceed with repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Full_repair
                break
            }
        }
        
        "0x80073712"
        {
            Dolog -Message "Possible problem with system files" -loglevel 2 -color "Red"
            While( -not ( ($choice = (Read-Host "Proceed with repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                
                <#
                Dolog -Message "Running DISM /Online /Cleanup-Image /RestoreHealth" -LogLevel 1 -color "White"
                psexec \\$ComputerName "cmd" "/c DISM /Online /Cleanup-Image /RestoreHealth"  2>$null

                Dolog -Message "sfc /scannow" -LogLevel 1 -color "White"
                psexec \\$ComputerName "cmd" "/c sfc /scannow"  2>$null
                break
                #>
                $DoLogDef = ${function:DoLog}
                
                Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    Set-Item Function:DoLog $Using:DoLogDef
                    
                    DoLog -Message "Running DISM /Online /Cleanup-Image /RestoreHealth" -LogLevel 1 -color "White" -access_type "local"
                    DISM /Online /Cleanup-Image /RestoreHealth

                    DoLog -Message "sfc /scannow" -LogLevel 1 -color "White" -access_type "local"
                    sfc /scannow
                }

            }
        }
        
        "0x80240438"
        {
            $DoLogDefinition = ${function:DoLog}
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                ${function:DoLog} = $using:DoLogDefinition

                $result = [PSCustomObject]@{
                    ProxyType   = $null
                    ProxyServer = $null
                    BypassList  = $null
                    }

                $output = netsh winhttp show proxy

                if ($output -match "Direct access")
                {
                    $result.ProxyType = "Direct"
                    Dolog -Message "No WinhttpProxy Configured" -loglevel 1 -color "green"
                }
                else 
                {
                    foreach ($line in $output) 
                    {
                        if ($line -match "Proxy Server") 
                        {
                            $ActualProxy = $result.ProxyServer = ($line -split ":",2)[1].Trim()
                            Dolog -Message "Actual proxy server is: '$($ActualProxy)'" -loglevel 2 -color "Yellow"
                        }
                        elseif ($line -match "Bypass List")
                        {
                            $Bypasslist = $result.BypassList = ($line -split ":",2)[1].Trim()
                            Dolog "Bypass Proxy list is: '$($Bypasslist)'" -loglevel 2 -color "Yellow"
                        }
                    }
                    Dolog -message "Reseting Proxy Configuration..." -loglevel 1 -color "White"
                    $reset = netsh winhttp reset proxy

                    if ($reset -match "Direct access")
                    {
                        Dolog -message "Proxy Reseted Successfull" -loglevel 1 -color "White"
                    }
                }
    <#
                $proxy = "gateway.pt.zscaler.net:80"
                Dolog -Message "Possible problem with proxy configuration" -LogLevel 1 -color "White"
                Dolog -Message "Getting proxy Configuration... please wait" -LogLevel 1 -color  "White"
                psexec \\$ComputerName "cmd" "/c netsh winhttp show proxy > c:\windows\temp\proxy.txt" 2>$null
                #psexec \\$ComputerName "cmd" "/c netsh winhttp show proxy" 2>$null
                
                try 
                {
                    $get_proxy = Get-Content \\$ComputerName\c$\windows\temp\proxy.txt -Tail 3
                    
                    $check_proxy = $get_proxy[0].Contains($proxy)

                    if ($check_proxy -eq $true)
                    {
                        $check_proxy = $get_proxy[0] -split ":"
                        $config_proxy = ($check_proxy[1] + ":" + $check_proxy[2]).trim()

                        $txt = "Configured proxy is " + $config_proxy
                        Dolog -message $txt -LogLevel 1 -color "Green"
                    }
                    else 
                    {
                        #before netskope
                        #$txt = "Configured proxy is " + $get_proxy[0] + ". Changing to default proxy"
                        #Dolog -message $txt -LogLevel 1 -color "Yellow"
                        #psexec \\$ComputerName "cmd" "/c netsh winhttp set proxy gateway.pt.zscaler.net:80 ""*.corppt.com;*.telecom.pt;10.*;<local>"  2>$null
                        #after Netskope
                        Dolog -Message "No need to change proxy configurations" -loglevel 1 -color "Yellow"
                        break
                    }  
                }
                catch 
                {
                    Dolog -Message "Unable to read proxy configuration" -LogLevel 3 -color "Red"
                }
                
                
                #While( -not ( ($choice = (Read-Host "Change proxy configuration (y/n)?")) -match "y|n")){}
                #if ($choice -eq "Y" -or $choice -eq "y")
                #{
                #    Dolog -Message "Changing Proxy COnfiguration" -LogLevel 1 -color "White"
                #    psexec \\$ComputerName "cmd" "/c netsh winhttp set proxy gateway.pt.zscaler.net:80 ""*.corppt.com;*.telecom.pt;10.*;<local>"  2>$null
                #    break
                #}
                #>
            }
        }
        "0x80240439"
        {
            $DoLogDefinition = ${function:DoLog}
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                ${function:DoLog} = $using:DoLogDefinition
                
                $result = [PSCustomObject]@{
                    ProxyType   = $null
                    ProxyServer = $null
                    BypassList  = $null
                    }

                $output = netsh winhttp show proxy

                if ($output -match "Direct access")
                {
                    $result.ProxyType = "Direct"
                    Dolog -Message "No WinhttpProxy Configured" -loglevel 1 -color "green"
                }
                else 
                {
                    foreach ($line in $output) 
                    {
                        if ($line -match "Proxy Server") 
                        {
                            $ActualProxy = $result.ProxyServer = ($line -split ":",2)[1].Trim()
                            Dolog -Message "Actual proxy server is: '$($ActualProxy)'" -loglevel 2 -color "Yellow"
                        }
                        elseif ($line -match "Bypass List")
                        {
                            $Bypasslist = $result.BypassList = ($line -split ":",2)[1].Trim()
                            Dolog "Bypass Proxy list is: '$($Bypasslist)'"
                        }
                    }
                    Dolog -message "Reseting Proxy Configuration..." -loglevel 1 -color "White"
                    $reset = netsh winhttp reset proxy

                    if ($reset -match "Direct access")
                    {
                        Dolog -message "Proxy Reseted Successfull" -loglevel 1 -color "White"
                    }
                }
            }
        }
        "0x80244022"
        {
            Dolog -Message "Possible temporary problem connecting to wsus server...retrying" -LogLevel 1 -color "White"
            While( -not ( ($choice = (Read-Host "Retry connection to wsus server (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        "Failed to Add Update Source for WUAgent of type (2)"
        {
            While( -not ( ($choice = (Read-Host "Possible problem with agent policies. Repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Dolog -Message "Reseting Policies" -LogLevel 1 -color "White"
                update_policies $true
                #Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        
        "Unable to read existing WUA Group Policy object. Error = 0x80004005"
        {
            While( -not ( ($choice = (Read-Host "Possible problem with agent policies. Repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Dolog -Message "Reseting Policies" -LogLevel 1 -color "White"
                update_policies $true
                #Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        "0xc80003fd"
        {
            While( -not ( ($choice = (Read-Host "Possible problem with SoftwareDistribution Folder. Repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Dolog -Message "Reseting policies and C:\Windows\SoftwareDistribution" -LogLevel 1 -color "White"
                update_policies $true
                #Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        "0x8007000d"
        {
            While( -not ( ($choice = (Read-Host "Possible problem with SoftwareDistribution Folder. Repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Dolog -Message "Reseting policies and C:\Windows\SoftwareDistribution" -LogLevel 1 -color "White"
                update_policies $true
                #Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        "0x80080005"
        {
            While( -not ( ($choice = (Read-Host "Possible problem with SoftwareDistribution Folder. Repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Dolog -Message "Reseting policies and C:\Windows\SoftwareDistribution" -LogLevel 1 -color "White"
                update_policies $true
                #Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        "0x80070020"
        {
            While( -not ( ($choice = (Read-Host "Possible problem with SoftwareDistribution Folder. Repair (y/n)?")) -match "y|n")){}
            if ($choice -eq "Y" -or $choice -eq "y")
            {
                Dolog -Message "Reseting policies and C:\Windows\SoftwareDistribution" -LogLevel 1 -color "White"
                update_policies $true
                #Force_Trigger "{00000000-0000-0000-0000-000000000108}"
                break
            }
        }
        "0x80070422"
        {
            Dolog -Message "Possible problem with service windows update [always in disable]" -LogLevel 2 -color "Red"
            wua_disable
            break
        }
        "0x80041006"
        {
            Dolog -Message "Out Of Memory. Check bits jobs and delete" -LogLevel 2 -color "Yellow"
        }
    
        
    }
}
Function check_log_errorv2
{
param 
(
    [Parameter(Mandatory = $true)]
    [string]$filename,
    [Parameter(Mandatory = $true)]
    [string[]]$listerrors,
    [Parameter(Mandatory = $false)]
    [string]$searchtype
)

    $DateNow = Get-Date

    #Check if client is correctly installed
    if ($listerrors -eq "exiting with return code 0")
    {
        if ($searchtype -ne "setup")
        {
            $lastline = parse_log_file -filename $filename -tail 1 -line_number 0

            $NumberDaysLastCCmsetup = 60
            $LastCCMSetupDays = ($DateNow-$lastline.localtime).Days

            if ($lastline.Message -eq "CcmSetup is exiting with return code 0")
            {
                $txt = "SCCM reinstalled " + $LastCCMSetupDays + " days ago! CCMSetup Last Line = " + "[" + $lastline.Message + "] on [" + $lastline.localtime + "]"
                if ($LastCCMSetupDays -gt $NumberDaysLastCCmsetup)
                {    
                    Dolog -Message $txt -LogLevel 2 -color "Red"  
                }
                else
                {
                    Dolog -Message $txt -LogLevel 1 -color "Green"
                }
                return $true    
            }
            else 
            {
                #$LastCCMSetupDays = ($DateNow-$item.localtime).Days                   
                $txt = "SCCM reinstalled with errors " + $LastCCMSetupDays +  " days! CCMSetup Last Line = " + "[" + $lastline.Message + "] on [" + $lastline.localtime + "]"
                Dolog -Message $txt -LogLevel 2 -color "Red"  
                return $false  
            }
        }
        else
        {
            $lastline = parse_log_file -filename $filename -tail 1 -line_number 0

            $i=0
            $n_error=$listerrors.Count

            do 
            {
                $aux_error = $listerrors[$i]
                if ($lastline.Message -like "*$aux_error*")
                {
                    if ($listerrors[$i] -eq "exiting with return code 0")
                    {
                        return $true
                    }
                }
                else
                {
                    #Write-Host "Error $aux_error not found" -ForegroundColor Green  
                }
                $i++
            }
            while ($i -lt $n_error)
        }
    }

    elseif ($searchtype -eq "scan")
    {
        $lastline = parse_log_file -filename $filename -tail 1 -line_number 0
        if ($lastline.Message -eq "Successfully completed scan.")
        {
            return $true
        }
    }
    else 
    {
        #Setup Errors
        #$lastline = parse_log_file -filename $filename -tail 10
        $aux_file = Split-Path -Path $filename -Leaf -Resolve
        $count=1

        While ($count -le 50)
        {
            #$lastline = Get-Content -Path $filename -tail 10| select -First 1 -Skip $count

            $lastline = parse_log_file -filename $filename -tail 50 -line_number $count 
            $errosfound=$false
            if ($lastline -eq $false)
            {
                Write-Host "File not found"
                #ExitRC
                Exit
            }
            #Write-Host $lastline.message-ForegroundColor Black -BackgroundColor Yellow
            
            foreach ($error_txt in $listerrors)
            {
                #Write-Host $error_txt -ForegroundColor Black -BackgroundColor Cyan
                if ($errosfound -ne $true)
                {
                    $MinH = 24

                    $ErrorActionPreference = "SilentlyContinue"
                    #if(![string]::IsNUllOrEMpty($lastline.messsage))
                    #{
                    #}
                    #else 
                    #{
                        #Write-Host "ENTREI" -ForegroundColor Green
                        if ($lastline.message.Contains($error_txt))
                        {
                            #Write-Host "Há Erro" -BackgroundColor red -ForegroundColor White
                            $errosfound=$true
                            $loghours = ($DateNow-$lastline.localtime).Hours
                            if($loghours -lt $MinH)
                            {
                                $LastError = $lastline.localtime    
                            }
                            $txt = "Error [$error_txt] found on file $aux_file at $LastError [" + ([math]::Round(($DateNow-$LastError).TotalHours)) + "] hours ago"
                            Dolog -Message $txt -LogLevel 3 -color "Red"

                            handel_error $error_txt
                            $count = 51
                            break
                            
                        }
                    #}
                    
                }
                #Read-Host "<<ENTER>>"
            }
            #Read-Host "<<ENTER>>"
            $count++
        }
        $ErrorActionPreference = "Continue"
        if (($errosfound -eq $false) -and ($searchtype -ne "setup"))
        {
            Dolog -message "No known errors were found on file $aux_file" -LogLevel 1 -color "Green"
        }    
    }
}

