Function get_sup
{
    try 
    {
        #$CCMUpdateCatalog = get-wmiobject -ComputerName $Computername -query "SELECT * FROM CCM_UpdateSource WHERE UniqueId='{312C0238-884C-49D7-9838-BB95883FA1B3}'" -namespace "ROOT\ccm\SoftwareUpdates\WUAHandler"
        $CCMUpdateCatalog = get-ciminstance -CimSession $cimsession -namespace "ROOT\ccm\SoftwareUpdates\WUAHandler" -query "SELECT * FROM CCM_UpdateSource WHERE UniqueId='{312C0238-884C-49D7-9838-BB95883FA1B3}'"

        #$cat = $CCMUpdateCatalog.ContentVersion
        #$sup = $CCMUpdateCatalog.ContentLocation
    }
    catch 
    {
        #Dolog -message "Unable to get Client Updates configuration" -LogLevel 3 -color "Red"
        #$cat = "0"
        #$sup = "---"
    }

    return $CCMUpdateCatalog

}
Function get_updates
{
    #$catalogver = 1794
    
    $wsusinfo = get_sup
    $cat = $wsusinfo.ContentVersion
    $sup = $wsusinfo.ContentLocation
    <#
    try 
    {
        $CCMUpdateCatalog = get-wmiobject -ComputerName $Computername -query "SELECT * FROM CCM_UpdateSource WHERE UniqueId='{312C0238-884C-49D7-9838-BB95883FA1B3}'" -namespace "ROOT\ccm\SoftwareUpdates\WUAHandler"
        $cat = $CCMUpdateCatalog.ContentVersion
        $sup = $CCMUpdateCatalog.ContentLocation
    }
    catch 
    {
        Dolog -message "Unable to get Client Updates configuration" -LogLevel 3 -color "Red"
        $cat = "0"
        $sup = "---"
    }
    #>
    #$sup = "SUP Server: " + $CCMUpdateCatalog.ContentLocation
     

    #if ($CCMUpdateCatalog.ContentVersion -ge $catalogver)
    if ($Cat -ge $catalogver)
    {
        $txt = "Catalog Version: " + $cat
        Dolog -Message $txt -LogLevel 1 -color "Green"
       #Dolog -Message $sup -LogLevel 1 -color "Green"
    }
    else
    {
        $txt = "Catalog Version: " + $cat
        Dolog -Message $txt -LogLevel 1 -color "Red"
       #Dolog -Message $sup -LogLevel 1 -color "Red"
    }

    
    if (($sup -eq "https://CKPSCC04.PTPORTUGAL.CORPPT.COM:8531") -or ($sup -eq "https://sccmcb.telecom.pt:8531"))
    {

        $restart_ccm_wua = $true

        $txt = "SUP server $sup. Proceed to restart services"
        Dolog -message $txt -loglevel 2 -color "Yellow"
        Restart_Services
        Dolog -message "Forcing new Update Scan" -LogLevel 1 -color "White"
        Force_Trigger "{00000000-0000-0000-0000-000000000113}"
        
        
        Dolog -message "Waiting for scan results" -LogLevel 1 -color "White"
        $waittime = do_timeout -timeout 300 -RetryInterval 5 -Filename $wuahandler  -Search_string "Successfully completed scan."
        $restart_ccm_wua = $true
        if($waittime -eq $true)
        {
            Dolog -Message "Scan took more than 2 minutes to complete. The action timeout" -LogLevel 2 -color "Yellow"
        }
        else
        {
            Dolog -Message "Fininsh scanning Windows Updates" -LogLevel 1 -color "Green"
        }
        
    }
    else 
    {
        Dolog -message "SUP server $sup" -loglevel 1 -color "Green"
    }

     #Date Last Scan
     $LastScan = $null
     try 
     {
        <#
        get-wmiobject -ComputerName $Computername -query "SELECT * FROM CCM_UpdateStatus" -namespace "root\ccm\SoftwareUpdates\UpdatesStore" | 
        
        % { 
            if ($_.ScanTime -gt $ScanTime) 
            { 
                $ScanTime = $_.ScanTime 
            } 
        }
        #$LastScan = ([System.Management.ManagementDateTimeConverter]::ToDateTime($ScanTime));
        $LastScan
        $txt =  "Last Scan " + $LastScan.ToString("dd/MM/yyyy HH:mm:ss")
        Dolog -Message $txt -loglevel 1 -color "White"
        #>
        $allscans = get-ciminstance -CimSession $cimsession -namespace "root\ccm\SoftwareUpdates\UpdatesStore" -query "SELECT * FROM CCM_UpdateStatus"
        foreach ($Scan in $allscans)
        {
            if ($Scan.ScanTime -gt $ScanTime)
            {
                $ScanTime = $scan.ScanTime
            }
        }
        $txt =  "Last WUA Scan = " + $ScanTime
        Dolog -Message $txt -loglevel 1 -color "White"
       
    }   
    catch
    {
       Dolog -Message  "Last Scan Date/Time Inválido" -loglevel 1 -color "Red"
    }   
     # Updates missing?

     #$UpdateMissing = @(get-wmiobject -ComputerName $Computername -query "SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0" -namespace "ROOT\ccm\ClientSDK").count
     $UpdateMissing = @(get-ciminstance -CimSession $cimsession -namespace "ROOT\ccm\ClientSDK" -query "SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0").Count
     if ($UpdateMissing -eq 0) 
     {
        $txt = "Updates Missing " + $UpdateMissing
        Dolog -message $txt -loglevel 1 -color "Green"
     }
     else
     {
        $txt = "Updates Missing " + $UpdateMissing
        Dolog -Message $txt -LogLevel 1 -color "Red"
    }

    #Which Updates
    #$UpdateMissingListAll = get-wmiobject -ComputerName $Computername -query "SELECT * FROM CCM_UpdateStatus WHERE status = 'Missing'" -namespace "root\ccm\SoftwareUpdates\UpdatesStore"
    $UpdateMissingListAll = get-ciminstance -CimSession $cimsession -namespace "root\ccm\SoftwareUpdates\UpdatesStore" -query "SELECT * FROM CCM_UpdateStatus WHERE status = 'Missing'"
    #$UpdateMissingList = get-wmiobject -ComputerName $Computername  -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK"
    $UpdateMissingList = get-ciminstance -CimSession $cimsession -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK"
    #get-ciminstance -CimSession $cimsession -Class MSFT_PhysicalDisk -Namespace Root\Microsoft\Windows\Storage -ErrorAction SilentlyContinue | Select-Object Model, MediaType
    foreach ($UpdateMissingLists in $UpdateMissingList)
    {
        $txt = $UpdateMissingLists.ArticleID  + " - " + $UpdateMissingLists.Name 
        
        if ($UpdateMissingLists.ExclusiveUpdate -eq $True)
        {
            $txt = $txt + " Available "
        }
        else
        {
            $txt = $txt + " Force "
        }
        if ($UpdateMissingLists.Deadline)
        {
            #$txt = $txt + ($UpdateMissingLists.ConvertToDateTime($UpdateMissingLists.Deadline)).ToUniversalTime() 
            $txt = $txt + $UpdateMissingLists.Deadline
            
            if ($txt -contains "Force") 
            {
                Dolog -Message $txt -LogLevel 1 -color "Red"
            }
            else
            {
                Dolog -Message $txt -LogLevel 1 -color "Green"
            }
        }
        else
        {
            $txt = $txt + "No Date"
            dolog -Message $txt -LogLevel 1 -color "Yellow"
        }    
    }
           
    # Installing updates
   # $CCMUpdate = get-wmiobject -ComputerName $ComputerName -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK"
    $CCMUpdate = get-ciminstance -CimSession $cimsession -namespace "ROOT\ccm\ClientSDK" -query "SELECT * FROM CCM_SoftwareUpdate"
    $InstallingUpdate = if(@($CCMUpdate | Where-Object { $_.EvaluationState -eq 2 -or $_.EvaluationState -eq 3 -or $_.EvaluationState -eq 4 -or $_.EvaluationState -eq 5 -or $_.EvaluationState -eq 6 -or $_.EvaluationState -eq 7 -or $_.EvaluationState -eq 11 }).length -ne 0) 
    {
        $true
    }
    else
    {   
        $false
    }
    if ($InstallingUpdate -eq 'True') 
    {
        $txt = "Installing Updates? " + $InstallingUpdate
        Dolog -Message $txt -color "Yellow" -LogLevel 2
    } 
    else 
    {
        $txt = "Installing Updates? " + $InstallingUpdate
        Dolog -Message $txt -color "White" -LogLevel 1
    }

    #$ret_value = "$cat,$sup,$LastScan"
    #$ret_value = "$($cat),$($sup),$($ScanTime)"
   # write-host $ret_value -ForegroundColor DarkGreen
    $waittime=$null

    $script:obj = [PSCustomObject]@{
        'cat' = $cat
        'sup' = $sup
        'scandate' = $ScanTime
    }
    return $obj

    #return $ret_value
    

}
Function get_office_channel
{

    $hklm = 2147483650
    $reg = [wmiclass]"\\$computername\root\default:StdRegprov"
    $key = "SOFTWARE\Microsoft\Office\ClickToRun\Configuration\"

    $AudienceDatakey = "AudienceData"
    $UpdateChannelkey = "UpdateChannel"
    $UnmanagedUpdateUrlkey = "UnmanagedUpdateUrl"
    $regkey= "CDNBaseUrl"

   
    $AudienceData = ($reg.GetStringValue($hklm,$key,$AudienceDatakey)).svalue
    $txt = "Office 365 AudienceData is: " + $AudienceData
    Dolog -Message $txt -LogLevel 1 -color "White"
    
    $UpdateChannel = ($reg.GetStringValue($hklm,$key,$UpdateChannelkey)).svalue
    $UpdateChannel = get_office_specs ($UpdateChannel)
    $aux = $UpdateChannel -split ','
    $txt = "Office 365 UpdateChannel is: " +  $aux[0] + " = " + $aux[1]
    Dolog -Message $txt -LogLevel 1 -color "White"

    $UnmanagedUpdateUrl = ($reg.GetStringValue($hklm,$key,$UnmanagedUpdateUrlkey)).svalue
    $UnmanagedUpdateUrl = get_office_specs ($UnmanagedUpdateUrl)
    $aux = $UnmanagedUpdateUrl -split ','
    $txt = "Office 365 UnmanagedUpdateUrl is: " +  $aux[0] + " = " + $aux[1]
    Dolog -Message $txt -LogLevel 1 -color "White"

    $cdn = ($reg.GetStringValue($hklm,$key,$regkey)).svalue
    $cdn = get_office_specs ($cdn)
    $aux = $cdn -split ','
    $txt = "Office 365 CDNBaseUrl is: " +  $aux[0] + " = " + $aux[1]
    Dolog -Message $txt -LogLevel 1 -color "White"

    return $aux[2]

}
 
Function get_office_specs
{
    param(
        [string]$key
    )

    switch($key) 
    {
         #Monthly Enterprise Channel
        "http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6"
        {
            $channel = "MEC"
            $description = "Monthly Enterprise Channel"
        }
        #Current Channel
        "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"
        {
            $channel = "CC"
            $description = "Current Channel"
        }
        #Current Channel Preview
        "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be" 
        {
            $channel = "CCP"
            $description = "Current Channel Preview"
        }
        #Semi-Annual Enterprise Channel
        "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" 
        {
            $channel = "SAEC"
            $description = "Semi-Annual Enterprise Channel"
        }
        #Semi-Annual Enterprise Channel (Preview)
        "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf" 
        {
            $channel = "SACP"
            $description = "Semi-Annual Enterprise Channell (Preview)"
        }
        #Beta Channel
        "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f" 
        {
            $channel = "BETA"
            $description = "Beta Channel"
        } 
        default 
        {
            $channel = $null
            $description = "Unknown Channel"
        }
    }

    $aux = $key + "," + $description + "," + $channel
    return $aux
    
}

Function working_get_office_channel
{

    $hklm = 2147483650
    $reg = [wmiclass]"\\$computername\root\default:StdRegprov"
    $key = "SOFTWARE\Microsoft\Office\ClickToRun\Configuration\"
    $regkey= "CDNBaseUrl"

    $cdn=($reg.GetStringValue($hklm,$key,$regkey)).svalue

    switch($cdn) 
    {
         #Monthly Enterprise Channel
        "http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6"
        {
            $channel = "MEC"
            $description = "Monthly Enterprise Channel"
        }
        #Current Channel
        "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"
        {
            $channel = "CC"
            $description = "Current Channel"
        }
        #Current Channel Preview
        "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be" 
        {
            $channel = "CCP"
            $description = "Current Channel Preview"
        }
        #Semi-Annual Enterprise Channel
        "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" 
        {
            $channel = "SAEC"
            description = "Semi-Annual Enterprise Channel"
        }
        #Semi-Annual Enterprise Channel (Preview)
        "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf" 
        {
            $channel = "SACP"
            description = "Semi-Annual Enterprise Channell (Preview)"
        }
        #Beta Channel
        "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f" 
        {
            $channel = "BETA"
            $description = "Beta Channel"
        } 
        default 
        {
            $channel = $null
            $description = "Unknown Channel"
        }
    }

    $txt = "Office 365 is in " + $description
    Dolog -Message $txt -LogLevel 1 -color "White"
    return $channel
    
}
Function get_office
{
    $o365 = "%365%"
    $o2016 = "Microsoft Office Professional Plus 2016"
    $o2013 = "Microsoft Office Professional Plus 2013"
    $o2007 = "Microsoft Office Professional Plus 2007"

    
    try
    {
        #$office = Get-WmiObject -ComputerName $ComputerName -Namespace "ROOT\cimv2\sms" -Query "SELECT * FROM SMS_InstalledSoftware WHERE ARPDIsplayname like '$o2016' OR ARPDIsplayname like '$o2013' OR ARPDIsplayname like '$o2007' OR ARPDIsplayname like '$o365'" | Select-Object ARPDIsplayname,ProductVersion
        $office = get-ciminstance -CimSession $cimsession -Namespace "ROOT\cimv2\sms" -Query "SELECT * FROM SMS_InstalledSoftware WHERE ARPDIsplayname like '$o2016' OR ARPDIsplayname like '$o2013' OR ARPDIsplayname like '$o2007' OR ARPDIsplayname like '$o365'" | Select-Object ARPDIsplayname,ProductVersion
        #Write-Host "office = " $office -ForegroundColor Cyan
    }
    catch
    {
        return "NO"
    }
    
    if ($office -match "365")
    {  
        foreach ($i in $office)
        {
            $ver = $i.ProductVersion
            return $ver
        }
         
    }
    elseif ($office -match "2016")
    {
        return "2016"
    }
    elseif ($office -match "2013")
    {
        return "2013"
    }
    elseif ($office -match "2007")
    {
        return "2007"
    }
    else
    {
        return "NO"
    }   
}

Function Get_Office_arch
{
    param (
    [Parameter(Mandatory = $true)]
    [string]$version
    )

    $hklm = 2147483650
    $reg = [wmiclass]"\\$computername\root\default:StdRegprov"
    $key = "SOFTWARE\Microsoft\Office\$version\Outlook\"
    $value = "Bitness"

    $Bitness = ($reg.GetStringValue($hklm, $key, $value)).svalue

    if (-not $Bitness )
    {
        $key = "SOFTWARE\WOW6432Node\Microsoft\Office\$version\Outlook\"
        $value = "Bitness"

        $Bitness = ($reg.GetStringValue($hklm, $key, $value)).svalue
    }

    return $Bitness
}

Function get_uninstall_keys
{
    param (
    [Parameter(Mandatory = $true)]
    [string]$key,
    [Parameter(Mandatory = $true)]
    [string]$value,
    [Parameter(Mandatory = $true)]
    [string]$version,
    [Parameter(Mandatory = $true)]
    [string]$kbflag
    )

    $hklm = 2147483650
    $reg = [wmiclass]"\\$computername\root\default:StdRegprov"
    $subkeys = $reg.EnumKey($hklm, $key)
    $count=0
    $order_signatures=@()
    $monthminus1 = $false

    foreach ($i in $subkeys.sNames)
    {
        $fullkey = $key + "\" + $i
        $registry_value = ($reg.GetStringValue($hklm, $fullkey, $value)).svalue
    
        $order_signatures += $registry_value   
    }

    $order_signatures = $order_signatures | select -Unique

    if ($version -eq "15.0")
    {
        #$Offices = ("KB4504728")
        #$Offices_last = ("KB5001993","KB5001983")
        #$Offices = ("KB5002007","KB5001958","KB4484108","KB5002014")
        #$Offices_last = ("KB4504728")
        $Offices = $Offices15
        $Offices_last = $Offices15_last
    }
    if ($version -eq "16.0")
    {
        #$Offices = ("KB4504718")
        #$Offices_last = ("KB5001977","KB5001979","KB5001949","KB5001971","KB5001980")

        #$Offices = ("KB4484467","KB5002005","KB5001997","KB4484103","KB5002003")
        #$Offices_last = ("KB4504718")
        $Offices = $Offices16
        $Offices_last = $Offices16_last
    }
    
    $kbinstalled = $false
    foreach ($signature in $order_signatures)
    {

        foreach ($kb in $Offices)
        {
            #write-host $signature " --> " $kb -ForegroundColor Magenta
            if ($signature -match $kb)
            {
                $count++
                
                #write-host $kb " found!! -> " $signature -ForegroundColor Green
                $aux = $signature -match $kbflag
                if ($aux -eq $true)
                {
                    $kbinstalled = $true
                }
            }
            #else 
            #{
            #    write-host $kb " nao dá" -ForegroundColor Red
            #    Write-Host $signature -ForegroundColor Cyan
            #    Write-Host ""
            #}
            #read-host "press Enter"
        }
    }

    $txt = "Total number of office updates this month is " + $Offices.count + ". Total Installed updates is " + $count  
    if ($count -eq $Offices.count)
    {
        $txt = $txt + ". All installed"
        Dolog -Message $txt -LogLevel 1 -color "Green"
    }
    else
    {
        $txt = $txt + ". Some of this month office updates are missing"
        Dolog -Message $txt -LogLevel 3 -color "Red"

        if ($count -eq 0)
        {
            $monthminus1 = $true
            Dolog -Message "Checking last month office updates..." -LogLevel 1 -color "Gray"
            #$Offices_last
            foreach ($signature in $order_signatures)
            {
                foreach ($kb in $Offices_last)
                {
                    if ($signature -match $kb)
                    {
                        $count++
                        write-host $signature
                        $aux = $signature -match $kbflag
                        if ($aux -eq $true)
                        {
                            $kbinstalled = $true
                        }
                    }
                }
            }
            $txt = "Total number of office updates last month is " + $Offices_last.count + ". Total Installed updates is " + $count 
            if ($count -eq $Offices_last.count)
            {
                $txt = $txt + ". All installed"
                Dolog -Message $txt -LogLevel 1 -color "Green"
            }
            else 
            {
                $txt = $txt + ". Some Updates are missing!!"
                Dolog -Message $txt -LogLevel 1 -color "Red"
            }
        }
        else
        {
            $txt = $txt + ". Some Updates are missing!!"
            Dolog -Message $txt -LogLevel 1 -color "Red"
        }

    }

    return $kbinstalled
}

Function Get_service_status
{

}

Function check_monthly_updates
{
    param
    (
        [Parameter(Mandatory = $true)]
        #[string]$osbuild,
        $osbuild,
        [Parameter(Mandatory = $true)]
        #[string]$oscaption
        $oscaption
    ) 

    $values = get_updates

    #Write-Host $values -ForegroundColor DarkCyan
    
    #$cat = $values.split(",")[0]
    #$sup = $values.split(",")[1]
    #$scandate = $values.split(",")[2]

    $cat = $values.cat
    $sup = $values.sup
    $scandate = $values.scandate


    switch ($osbuild) 
    {
        7601 #WIn7
        {   
            $CU = $win7
            $net_frmw = $dotnet_w7
            $net_last = $dotnet_w7_last
        } #
        9600 #WIn8
        {
            $CU = $WIn8
            $net_frmw = $dotnet_w8
            $net_last = $dotnet_w8_last
        } 
        
        #14393 {$CU = $Win101607} #Win 10 1607 EOL
        #15063 {$CU = $Win101703} #Win 10 1703 EOL
        #16299 {$CU = $Win101709} #Win 10 1709 EOL
        #17134 {$CU = $Win101803} #Win 10 1803 EOL
        #17763 {$CU = $Win101809} #Win 10 1809 (LTSC)
        #18362 {$CU = $Win101903}  #Win 10 1903 EOL
        #18363 {$CU = $Win101909}  #Win 10 1909 EOL
        #19041 {$CU = $Win102004}  #Win 10 20H1 EOL
        #19042 {$CU = $Win1020H2}  #Win 10 20H2 EOL
        #19043 {$CU = $Win1021H2}  #Win 10 21H1 EOL
        #22000 {$CU = $Win1121H2}  #Win 10 21H2 EOL
        17763
        {
            $CU = $Win101809
            $net_frmw = $dotnet_w10_1809
            $net_last = $dotnet_w10_1809_last    
        }
        18363 #Win 10 1909
        {
            $CU = $Win101909
            $net_frmw = $dotnet_w10_1909
            $net_last = $dotnet_w10_1909_last
        } 
        19041 #Win 10 2004
        {
            $CU = $Win102004
            $net_frmw = $dotnet_w10_higher20H2
            $net_last = $dotnet_w10_higher20H2_last
        } 
        19042 # Win 10 20H2
        {
            $CU = $Win1020H2
            $net_frmw = $dotnet_w10_20H2
            $net_last = $dotnet_w10_20H2_last
        } 
        
        19043 #Win 10 21H1
        {
            $CU = $Win1021H1
            $net_frmw = $dotnet_w10_21H1
            $net_last = $dotnet_w10_21H1_last
        }
        19044 #Win 10 21H2
        {
            if ($oscaption -match "LTSC")
            {
                $CU = $Win1021H2_LTSC
                $net_frmw = $dotnet_w10_21H2_LTSC
                $net_last = $dotnet_w10_21H2_last_LTSC
            }
            else 
            {
                $CU = $Win1021H2
                $net_frmw = $dotnet_w10_21H2
                $net_last = $dotnet_w10_21H2_last
            }
            
        }
        19045 #Win 10 22H2
        {
            $CU = $Win1022H2
            $net_frmw = $dotnet_w10_21H2
            $net_last = $dotnet_w10_22H2_last
        }  
        22000  #Win 11 21H2
        {
            $CU = $Win1121H2
            $net_frmw = $dotnet_w11_higher21H2
            $net_last = $dotnet_w11_higher21H2_last
        }
        22621  #Win 11 22H2
        {
            $CU = $Win1122H2
            $net_frmw = $dotnet_w11_higher22H2
            $net_last = $dotnet_w11_higher22H2_last
        }
        22631   #Win 11 23H2
        {
            $CU = $Win1123H2
            $net_frmw = $dotnet_w11_higher23H2
            $net_last = $dotnet_w11_higher23H2_last
        }
        26100   #Win 11 24H2
        {
            $CU = $Win1124H2
            $net_frmw = $dotnet_w11_higher24H2
            $net_last = $dotnet_w11_higher24H2_last
        }
		26200   #Win 11 25H2
        {
            $CU = $Win1125H2
            $net_frmw = $dotnet_w11_higher25H2
            $net_last = $dotnet_w11_higher25H2_last
        }

        

    #}
        default {}
    }

    $ltsc = $false

    if ($osbuild -eq 17763)
    {
        #$ltsc = $oscaption -match 'LTS'
        if ($oscaption -match "LTSC")
        {
            $ltsc = $true
        }
        
    }

    if ($osbuild -eq 19044)
    {
        #$ltsc = $oscaption -match 'LTS'
        if ($oscaption -match "LTSC")
        {
            $ltsc = $true
        }
        
    }

    Dolog -Message "Cumulative Update Information" -LogLevel 1 -color "Gray"
    if (($osbuild -le 17763) -and ($ltsc -eq $false))
    {
        $CU="KB5003171"
    }

    try
    {
        $kb=get-hotfix -id $CU -ComputerName $Computername -ErrorAction SilentlyContinue

        $cuid = $kb.HotFixID

        #if (($osbuild -le 17763) -and ($ltsc -eq $false))
        if (($osbuild -le 18363) -and ($ltsc -eq $false))
        {
            $txt = "Windows version " + $osbuild + " reached EOL. The last Cumulutative Update is $CU and was installed on " + ($kb.InstalledOn).tostring("dd-MM-yyyy")
            $EOL = $true
        }
        #elseif (($osbuild -le 17763) -and ($ltsc -eq $true))
        elseif (($osbuild -le 18363) -and ($ltsc -eq $true))
        {
            $txt = "Windows version " + $osbuild + " is LTSC. The last Cumulutative Update is $CU and was installed on " + ($kb.InstalledOn).tostring("dd-MM-yyyy")
            $EOL = $false
        }
        else 
        {
            $txt = $kb.HotFixID + " " + " Installed (!!) on " + ($kb.InstalledOn).tostring("dd-MM-yyyy")
            $EOL = $false
        }
        Dolog -Message $txt -LogLevel 1 -color "Green"
    }
    catch 
    {
        #Write-Host "entrei no catch" -ForegroundColor Magenta
        #if (($osbuild -le 17763) -and ($ltsc -eq $true))
        #{
        #    $txt = "Windows version " + $osbuild + " reached EOL. The last Cumulutative Update is $CU and WAS NOTinstalled!"
        #    $EOL = $true
        #}
        #else 
        #{
        $txt = $CU + " " + "NOT! Installed"
        $EOL = $false
        #}
        
        Dolog -Message $txt -LogLevel 2 -color "Red"
    }

    Dolog -Message "Office and Others Information" -LogLevel 1 -color "Gray"
    
    $office = get_office
    #write-host $office

    if ($office -ne "NO")
    {
        if ($office.substring(0,3) -eq "15." -or $office.substring(0,3) -eq "16.")
        {
            $o365version = $office.substring(0,3)
            $officestr = "365"
        }

        switch ($office)
        {
            "2016" {
                #$kboffice = "KB5002005" 
                $kboffice = $office2016_last
                $lastmonth_office_ver = $office2016_last_month
                $officestr = "2016"
                $ver = "16.0"}
                
            "2013" {
                #$kboffice = "KB5002007"
                $kboffice = $office2013_last
                $lastmonth_office_ver = $office2013_last_month
                $officestr = "2013"
                $ver = "15.0"}
            "2007" {
                #$kboffice = "KB4018353"
                $kboffice = $office2007_last
                $lastmonth_office_ver = $office2007_last
                $officestr = "2007"
                $ver = "12.0"} 
            "2010" {
                #$kboffice = "KB4504738"
                $kboffice = $office2010_last
                $lastmonth_office_ver = $office2010_last
                $officestr = "2010"
                $ver = "14.0"}
        }
    }
    
    if (($office -eq "2013") -or ($office -eq "2007") -or ($office -eq "2016"))
    {
        $office_updated = $kboffice

        $arch = Get_Office_arch $ver

        if ($arch -eq "x86")
        {
            $kbcontrol = get_uninstall_keys "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" "DisplayName" $ver $kboffice
        }
        elseif ($arch -eq "x64")
        {
            $kbcontrol = get_uninstall_keys "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" "DisplayName" $ver $kboffice
        }
        else
        {
            Write-Host "Não conseguiu"
        }

        if ($kbcontrol -eq $true)
        {
            $office_installed = $kboffice

        }
        else 
        {
            $office_installed = "--------"   
        }
    }
    elseif ($o365version -eq "16.")
    {
        $office_channel = get_office_channel
        $arch = Get_Office_arch "16.0"

        $office_installed = [System.Version]$office

        if ($office_channel -eq "MEC")
        {
            $office_updated  = $o365_monthly
            $lastmonth_office_ver = $o365_monthly_last
            

            if ([System.Version]$office -ge [System.Version]$o365_monthly)
            {
                $txt = "Office 365 is v" + $office + ". Is Updated"
                Dolog -Message $txt -LogLevel 1 -color "Green"
            }
            elseif ([System.Version]$office -eq [System.Version]$o365_monthly_last)
            {
                $txt = "Office 365 is v" + $office + ". Is last month Update!"
                Dolog -Message $txt -LogLevel 1 -color "Yellow"
            }
            else 
            {
                $txt = "Office 365 is v" + $office + ". Is outdated!!!"
                Dolog -Message $txt -LogLevel 3 -color "Red"    
            }
        }
        elseif ($office_channel -eq "CC")
        {
            $office_updated = $o365_current
            $lastmonth_office_ver = $o365_current_last
            if ([System.Version]$office -ge [System.Version]$o365_current)
            {
                $txt = "Office 365 is v" + $office + ". Is Updated"
                Dolog -Message $txt -LogLevel 1 -color "Green"
            }
            elseif ([System.Version]$office -eq [System.Version]$o365_current_last)
            {
                $txt = "Office 365 is v" + $office + ". Is last month Update!"
                Dolog -Message $txt -LogLevel 1 -color "Yellow"
            }
            else 
            {
                $txt = "Office 365 is v" + $office + ". Is outdated!!!"
                Dolog -Message $txt -LogLevel 3 -color "Red"    
            }
        }
        else 
        {
            $txt = "This channel " + $office_channel + " is not supported"
            Dolog -Message $txt -LogLevel 3 -color "Red"
        }
    
    }
    elseif ($o365version -eq "15.")
    {
        $office_updated = [System.Version]$o365_C2R_v15
        $office_installed = [System.Version]$office
        $lastmonth_office_ver = $o365_C2R_v15_last
        $arch = Get_Office_arch "15.0"

        if ([System.Version]$office -ge [System.Version]$o365_C2R_v15)
        {
            $txt = "Office 365 is v" + $office + ". Is Updated"
            Dolog -Message $txt -LogLevel 1 -color "Green"
        }
        elseif ([System.Version]$office -eq [System.Version]$o365_C2R_v15_last)
        {
            $txt = "Office 365 is v" + $office + ". Is last month Update!"
            Dolog -Message $txt -LogLevel 1 -color "Yellow"
        }
        else 
        {
            $txt = "Office 365 is v" + $office + ". Is outdated!!!"
            Dolog -Message $txt -LogLevel 3 -color "Red"    
        }
    }
    else 
    {
        Dolog -Message "Can not get Office version"     -LogLevel 2 -color "Yellow"
    }

    $kbl = (Get-Hotfix -Computername $ComputerName | Sort-Object installedon -ErrorAction SilentlyContinue)[-1]

    $lastkb = $kbl.HotFixID
    $lastkbinstalldate = ($kbl.InstalledOn).tostring("dd-MM-yyyy")
    $txt = "Last KB" + " " + $lastkb  + " Installed on " + " " + $lastkbinstalldate
    Dolog -Message $txt -LogLevel 1 -color "Yellow"

    #.net Update Status
    try 
    {
        #Write-Host "NETFRAMEWORK A PESQUISAR = $net_frmw" -ForegroundColor Cyan
        $kbfrmw=get-hotfix -id $net_frmw -ComputerName $Computername -ErrorAction SilentlyContinue
        $cuidfrmw= $kbfrmw.HotFixID
        $cuidfrmw_installdate = ($kbfrmw.InstalledOn).tostring("dd-MM-yyyy")
    }
    catch {   
    }

    #Write-Host "1 " $cuidfrmw -ForegroundColor Magenta

    if (!($cuidfrmw))
    {
        #write-host "entrei"
        try 
        {
            #Write-Host "NETFRAMEWORK ANTIGO A PESQUISAR = $net_last" -ForegroundColor DarkRed
            $kbfrmw=get-hotfix -id $net_last -ComputerName $Computername -ErrorAction SilentlyContinue
            $cuidfrmw = $kbfrmw.HotFixID    
            $cuidfrmw_installdate = ($kbfrmw.InstalledOn).tostring("dd-MM-yyyy")





        }
        catch {  
        }
    }

    #Write-Host "2 " $cuidfrmw -ForegroundColor Magenta
    
    
    if ($cuidfrmw -eq $net_frmw)
    {
        $net_frmw_status = "Green"
    }
    elseif ($cuidfrmw -eq $net_last) 
    {
        $net_frmw_status = "Red"   
    }
    else 
    {
        $net_frmw_status = "Red"   
    }
    
    #Malicious
    try 
    {

        $Malicious_version = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\RemovalTools\MRT').version

        }
        <#
        $updates = get-ciminstance -CimSession $cimsession -Query "Select *  From win32_reliabilityRecords  WHERE ProductName like '%KB890830%'  and Message like 'Installation Success%'"

        Write-Host "---"
        Write-Host $updates -ForegroundColor DarkYellow
        Write-Host "---"
        
        $UpdatesSorted = $updates | Sort-Object RecordNumber |Select-Object -last 1
        $name = $UpdatesSorted.productname
        
        $data = $UpdatesSorted.TimeGenerated
        $data = ([System.Management.ManagementDateTimeConverter]::ToDateTime($data)).ToString("dd-MM-yyyy")
        $Malicious_date = $data

        $pos = $name.IndexOf(" - ")
        $Malicious_version = $name.Substring($pos+4)
        $Malicious_version = $Malicious_version.Substring(0,5)

        #$data = ([System.Management.ManagementDateTimeConverter]::ToDateTime($data)).ToString("dd-MM-yyyy")
        $txt =  "Last Malicious installed --> " + $name + " on " + $Malicious_date
        dolog -Message $txt -LogLevel 1 -color "Cyan"
        #>
    }
    catch
    {
        Dolog -Message "Can't get last Windows Malicious Software Removal Tool" -LogLevel 1 -color "Cyan"
    }

    $wsusinfo = get_sup
    #$cat = $wsusinfo.ContentVersion
    $sup = $wsusinfo.ContentLocation
    #write-host "### = " $cuid -ForegroundColor Magenta

    <#
    $aux1 = "Office " + $officestr + " Update Status"
    $t = ("-"*208)
    $aux1 = "|         " + $aux1
    $header1 = "{0,-82}{1,-36}{2,-46}{3,-26}{4,-18}" -f "                           Wsus Data","|          Cumulative Update",$aux1,"|Last Update Status","|Malicious"
    $header2 = "{0,-15}{1,-45}{2,-20}{3,6}{4,15}{5,16}{6,15}{7,20}{8,8}{9,12}{10,10}{11,23}" -f "Cat. Version","Sup Server","Last Scan","|EOL","Monthly CU","Installed?","|Monthly Build","Build Installed","Status","|Last KB","Date","|Last Malicious"
    Write-Host $t
    Write-Host $header1 -ForegroundColor Cyan
    Write-Host $t
    Write-Host $header2 -ForegroundColor Magenta
    Write-Host $t



    Write-Host -ForegroundColor white -NoNewline ("{0,-15}{1,-45}{2,-22}" -f $cat,$sup,$scandate)
    if ($EOL -eq $true)
    {
        Write-Host -ForegroundColor Red -NoNewline ("{0,-9}" -f "|YES")
    }
    else 
    {
        Write-Host -ForegroundColor Green -NoNewline ("{0,-9}" -f "|NO")
    }
    
    Write-Host -ForegroundColor white -NoNewline ("{0,-16}" -f $CU)
    if ($cuid -eq $CU)
    {
        Write-Host -ForegroundColor Green -NoNewline ("{0,-11}" -f "YES")
    }
    else 
    {
        Write-Host -ForegroundColor Red -NoNewline ("{0,-11}" -f "NO")
    }

    
    $auxoffice_updated = "|" + $office_updated
    Write-Host -ForegroundColor White -NoNewline ("{0,-19}" -f $auxoffice_updated)
    #Write-Host -ForegroundColor Yellow -NoNewline ("{0,-17}" -f $office_installed)
    if ($office_installed -ge $office_updated)
    {
        Write-Host -ForegroundColor Green -NoNewline ("{0,-17}{1,-10}" -f $office_installed,"OK")
    }
    else 
    {
        Write-Host -ForegroundColor Red -NoNewline ("{0,-17}{1,-10}" -f $office_installed,"OUTDATED")
    }
    $lastkb = $kbl.HotFixID
    $lastkbinstalldate = ($kbl.InstalledOn).tostring("dd-MM-yyyy")
    $lastkb = "|" +  $lastkb
    Write-Host -ForegroundColor White -NoNewline ("{0,-14}" -f $lastkb)
    Write-Host -ForegroundColor White -NoNewline ("{0,-12}" -f $lastkbinstalldate)
    $Malicious_date = "|" + $Malicious_date
    Write-Host -ForegroundColor White ("{0,-12}" -f ,$Malicious_date)

    #>
   ##############################
    $t = ("-"*133)
    $lensup = $sup.Length
    $len = $lensup + 15
    
    Write-Host $t
    $header1 = "{0,35}" -f "Windows Updates Status" 
    Write-Host $header1 -ForegroundColor Cyan

    #Write-Host  "Service" -NoNewline
    #$writeaux = "{0,18}" -f ": stopped"
    #Write-Host $writeaux

    Write-Host "Catalog Version" -NoNewline
    $writeaux = "{0,3}" -f ": "  
    write-host $writeaux -nonewline
    $writeaux = "{0,1}" -f $cat
    if ($Cat -ge $catalogver)
    {
        
        Write-Host $writeaux -ForegroundColor Green
    }
    else
    {
        Write-Host $writeaux -ForegroundColor Red
    }
    

    Write-Host "SUP"  -NoNewline
    $writeaux = "{0,$len}" -f ": $sup"
    Write-Host $writeaux

    Write-Host "Last Scan"  -NoNewline
    $writeaux = "{0,28}" -f ": $scandate"
    Write-Host $writeaux
    Write-Host $t

    Write-Host $t
    $header1 = "{0,35}" -f "Software Updates" 
    Write-Host $header1 -ForegroundColor Cyan

    #$writeaux = "{0,-30}{1,-38}{2,-30}{3,-25}" -f "      Operating System","           Office $officestr","      .Net Framework","       Mallicious"
    $writeaux = "{0,-30}{1,-38}{2,-30}{3,-25}" -f "      Operating System","           Office $officestr ($arch)","      .Net Framework","       Mallicious"
    Write-Host $writeaux -ForegroundColor Magenta

    $writeaux = "{0,-30}{1,-38}{2,-30}{3,-25}" -f "Monthly        : $CU","Monthly Build   : $office_updated","Monthly         : $net_frmw","Monthly         : KB890830 (v$Malicious)"
    Write-Host $writeaux



    Write-Host -NoNewline "Last Installed : "
    if ($cuid -eq $CU)
    {
        Write-Host -ForegroundColor Green -NoNewline ("{0,-13}" -f $cuid)
        $cu_status = "YES"
    }
    else 
    {
        Write-Host -ForegroundColor Red -NoNewline ("{0,-13}" -f $cuid)
        $cu_status = "NO"
    }

    Write-Host -NoNewline "Last Installed  : "
    #if ($office_installed -eq $office_updated)
    if ($office_installed -ge $office_updated)
    {
        Write-Host -ForegroundColor Green -NoNewline ("{0,-20}" -f $office_installed)
        $office_updated = "YES"
    }  
    elseif ($office_installed -eq $lastmonth_office_ver)
    {
        Write-Host -ForegroundColor Yellow -NoNewline ("{0,-20}" -f $office_installed)
        $office_updated = "NO"
    }
    else 
    {
        Write-Host -ForegroundColor Red -NoNewline ("{0,-20}" -f $office_installed)   
        $office_updated = "NO"
    }

    Write-Host -NoNewline "Last Installed  : "
    Write-Host -ForegroundColor $net_frmw_status  -NoNewline ("{0,-12}" -f $cuidfrmw)

    Write-Host -NoNewline "Last Installed  : "
    if ($Malicious_version -eq $Malicious_ID)
    {
        Write-Host -ForegroundColor Green ("{0,-10}" -f "KB890830 (v$Malicious)")
        $Malicious_status = "YES"  
    }
    elseif ($Malicious_version -eq $Malicious_Last_ID) 
    {
        Write-Host -ForegroundColor Yellow ("{0,-30}" -f "KB890830 (v$Malicious_last)")
        $Malicious_status = "NO"  
    }
    else
    {
        Write-Host -ForegroundColor Red ("{0,-30}" -f "KB890830 (>=2 months)")
        $Malicious_status = "NO"
    }

    
    if (!($kb.InstalledOn))
    {
        $install_cu_date = "----"   
    }
    else 
    {
        $install_cu_date = ($kb.InstalledOn).tostring("dd-MM-yyyy")    
    }
    
    Write-Host -NoNewline "Date Installed : "
    Write-Host -nonewline ("{0,-51}" -f $install_cu_date)
    
    Write-Host -NoNewline "Date Installed  : "
    Write-Host -nonewline ("{0,-12}" -f $cuidfrmw_installdate)

    Write-Host -NoNewline "Date Installed  : "
    Write-Host  ("{0,-4}" -f  $data)
    

    Write-Host -NoNewline "EOL            : "
    if ($EOL -eq $true)
    {
        Write-Host -ForegroundColor Red -NoNewline ("{0,-30}" -f "YES")
    }
    else 
    {
        Write-Host -ForegroundColor Green -NoNewline ("{0,-30}" -f "NO")
    }

    write-host ""
    write-host $t
}

