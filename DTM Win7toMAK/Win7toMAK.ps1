$win_dir = $env:windir
$strComputerName = $env:COMPUTERNAME

$logfile = "C:\Program Files\SCCMPKGLOGS\Win7-2-MAK.log"

#Write-Host $logfile

#$workdir = "C:\windows\Temp\"

Function verify_logfile
{
    if (Test-Path $logfile)
    {
        
    }
    else
    {
        $logfile = New-Item -Path $logfile -ItemType "file" -Force
        
    }

}

Function exit_script
{
param (
    [Parameter(Mandatory = $true)]
    [int]$intRC
    )
    $msg = "Exiting script with error code = " + $intRC
    
    if ($intrc -eq 0 -or $intRC -eq 3010)
    {
        Dolog -Message $msg -color "White"
    }
    else
    {
        Dolog -Message $msg -color "red"
    }
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

$DateTime = get-date -format u
$txt= "---------- PROCESSING WIN7 - Change KMS to MAK ----- " + $DateTime + " ----------"
dolog -Message $txt -color "White"

function Create-RegistryKeyValue
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )


}

Function create_signature()
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$path,
        [Parameter(Mandatory=$true)]
        [string]$key
    )


    $searchpattern = $path + $key

    $keyexists = Test-Path $searchpattern

    if (-not $keyexists)
    {
        dolog -Message "Key $searchpattern does not exist" -LogLevel 1 -color "White"
        try
        {
            New-Item -Path $path -Name $key –Force   
            dolog -Message "Successfully create Key $searchpattern" -LogLevel 1 -color "white"
        }
        catch
        {
            Dolog -Message "Error creating key $searchpattern" -LogLevel 3 -color "red"
            Exit_Script(3)
        }
    }
    else
    {
        dolog -Message "Key $searchpattern already exist" -LogLevel 2 -color "yellow"
        Exit_Script(10000)
    }


    Dolog -Message "Creating signature vaslues" -color "White"

    try
    {
        
        Set-ItemProperty -Path $searchpattern -Name "Comments" -Value "Ass. para efeitos SCCM Win7 to MAK Key" -Type string
        Set-ItemProperty -Path $searchpattern -Name "DisplayName" -Value "SCCM-DIT-Windows7-TO-MAK-1-0" -Type string
        Set-ItemProperty -Path $searchpattern -Name "DisplayIcon" -Value "c:\windows\System32\oemlogo.bmp" -Type string
        Set-ItemProperty -Path $searchpattern -Name "DisplayVersion" -Value "1.0" -Type string
        Set-ItemProperty -Path $searchpattern -Name "InstallDate" -Value $DateTime -Type string
        Set-ItemProperty -Path $searchpattern -Name "InstallLocation" -Value "%Windir%\System32\oemlogo.bmp" -Type string
        Set-ItemProperty -Path $searchpattern -Name "Publisher" -Value "Altice Portugal" -Type string
        Set-ItemProperty -Path $searchpattern -Name "UninstallString" -Value "." -Type string

        Set-ItemProperty -Path $searchpattern -Name "NoModify" -Value 1 -Type dword
        Set-ItemProperty -Path $searchpattern -Name "NoRemove" -Value 1 -Type dword
        Set-ItemProperty -Path $searchpattern -Name "NoRepair" -Value 1 -Type dword

        Dolog -Message "Finish creating signature" -color "Green"
        EXit_script (0)
    }
    catch
    {
        Dolog -Message "Error creating signature" -LogLevel 3 -color "red"
        EXit_script (3)
    }
}

Function Activate_ESU_key
{
    param (
    [Parameter(Mandatory = $true)]
    [string]$ESUACtivationKey
    )

    try
    {
        Dolog -message "Activating Windows" -color "White"
        Dolog -Message "Using command line: cscript c:\windows\System32\slmgr.vbs /ato <<ACTIVATION KEY>>" -color "White"
        $ActKey = cscript c:\windows\System32\slmgr.vbs /ato $ESUACtivationKey  >> "C:\Windows\Temp\Win7-2-MAK.log"
        $R = CMD /C ECHO %ERRORLEVEL%

        $ActKey=[string]$ActKey

        $status_ok = $ActKey -match 'Product activated successfully.'
        $status_notok = $ActKey -match 'Error: product not found.'
  
        if ($status_ok)
        {
            Dolog "Successefully activated product!" -color "green"
        }
        elseif ($status_notok)
        {
            Dolog "<< Product key not found!!!!!>>" -color "Red"
            Exit_Script(1)
        }
        else
        {
            $txt = "Error activating Product key -> "  + $ipk
            Dolog -Message $txt  -color "red"
            Exit_Script(1)
        }
    }
    catch
    {
        Dolog -message "Unknown problem activating windows" -color "Red"
        Exit_Script(3)    
    }
}

Function Install_ESUkey
{
    $key = "W2MKH-RPW2T-PWWH7-GQ4GC-R22GH"

    try
    {
        Dolog -message "Installing ESU Product key" -color "White"
        Dolog -Message "Using command line: c:\windows\System32\slmgr.vbs /ipk <<KEY>>" -color "White"
        $ipk = cscript c:\windows\System32\slmgr.vbs /ipk $key  >> "C:\Windows\Temp\Win7-2-MAK.log"
        $ipk=[string]$ipk

        $status_ok = $ipk -match 'successfully.'
        $status_notok = $ipk -match 'The Software Licensing Service reported that the product key is invalid'

        if ($status_ok)
        {
            Dolog "Successefully installed ESU key" -color "green"
        }
        elseif ($status_notok)
        {
            Dolog "The ESU key is invalid" -color "red"
            Exit_Script(-1073418160)
        }
        else
        {
            $txt = "Error installing ESU key -> "  + $ipk
            Dolog  -Message $txt -color "red"
            Exit_Script(3)
        } 
        
    }
    catch
    {
        Dolog -message "Unknown problem installing ESU Key" -color "Red"    
    }
}

Function Get_Activation_ID
{

    try
    {
        Dolog -Message "Reading Activation ID code" -color "White"
        Dolog -Message "Using command line: cscript c:\windows\System32\slmgr.vbs /dlv" -color "White"
        $dlv = cscript c:\windows\System32\slmgr.vbs /dlv >> "C:\Windows\Temp\Win7-2-MAK.log"
        $activationIDfull = $dlv | Select-String -Pattern "Activation ID:"
        $activationIDfull = $activationIDfull -split ": "
        $activationIDfull = $activationIDfull[1]

        Activate_ESU_key $activationIDfull
        
    }
    catch
    {
        Dolog -message "Unknown problem getting activation ID" -color "Red"
        Exit_Script(3)   
    }
}

Function Verify_status
{
    Dolog -Message "Verifying activation parameters" -color "White"
    try
    {
        Dolog -Message "Using command line: cscript c:\windows\System32\slmgr.vbs /dlv" -color "White"
        $name = cscript c:\windows\System32\slmgr.vbs /dlv >> "C:\Windows\Temp\Win7-2-MAK.log"
        $licence_status = $name

        $namefull = $name | Select-String -Pattern "Name: "
        $namefull = $namefull -split ": "
        $namefull = $namefull[1]

        $namefull_ok = $namefull -match 'Client-ESU-Year1 add-on'

        if ($namefull -match 'Client-ESU-Year1 add-on')
        {
            $name = $true
        }
        else
        {
            $name = $false
        }
        
        $licence_statusfull = $licence_status| Select-String -Pattern "License Status: "
        $licence_statusfull = $licence_statusfull -split ": "
        $licence_statusfull = $licence_statusfull[1]
        
        $licence_statusfull_ok = $licence_statusfull -match 'Licensed'
        
        if ($licence_statusfull -match 'Licensed')
        {
            $licence = $true
        }
        else
        {
            $licence = $false
        }

        if ($name -and $licence)
        {
            Dolog -Message "Script verification was successfully - Windows Activated with MAK key!" -color "Green"
            create_signature "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" "SCCM-DIT-Windows7-TO-MAK"
            #Exit_script (0)
        }
        else
        {
            Dolog -Message "<< Error activating windows >>" -color "Red"
            $txt = "Name: " + $namefull
            Dolog -Message $txt -color "Red"
            $txt = "Licence: " + $licence_statusfull
            Dolog -Message $txt -color "Red"
            Exit_script (1)
        }
    }
    catch
    {
        Dolog -message "Unknown problem verifying activation status" -color "Red"
        Exit_script (3)
    }
}

Function Remove_KMS_Cofig
{
    try
    {
        Dolog -message "Removing KMS Configuration" -color "White"
        Dolog -Message "Using command line: cscript c:\windows\System32\slmgr.vbs /upk" -color "White"
        $upk = cscript c:\windows\System32\slmgr.vbs /upk
        $upk=[string]$upk

        $status_ok = $upk -match 'successfully.'
        $status_notok = $upk -match 'Error:'

        if ($status_ok)
        {
            Dolog "Successefully removed KMS configuration" -color "green"
        }
        elseif ($status_notok)
        {
            $txt = "Error removing KMS configuration. " + $upk
            Dolog  -Message $txt -color "red"
            Exit_Script(-1073418160)
        }
        else
        {
            $txt = "Error removing KMS configuration -> "  + $upk
            Dolog  -Message $txt -color "red"
            Exit_Script(3)
        } 
        
    }
    catch
    {
        Dolog -message "Unknown problem installing ESU Key" -color "Red"    
    }
}


Function pre-configure
{

    Dolog -Message "Change proxy" -color "White"
    netsh winhttp set proxy lon3.sme.zscaler.net:80 "*.corppt.com;*.telecom.pt;10.*;<local>" >> "C:\Windows\Temp\Win7-2-MAK.log"

    net stop WinHttpAutoProxySvc >> "C:\Windows\Temp\Win7-2-MAK.log"
    net start WinHttpAutoProxySvc >> "C:\Windows\Temp\Win7-2-MAK.log"

    net stop sppsvc >> "C:\Windows\Temp\Win7-2-MAK.log"
    del %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0 /ah >> "C:\Windows\Temp\Win7-2-MAK.log"
    del %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0 /ah >> "C:\Windows\Temp\Win7-2-MAK.log"
    del %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat >> "C:\Windows\Temp\Win7-2-MAK.log"
    del %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat >> "C:\Windows\Temp\Win7-2-MAK.log"
    net start sppsvc >> "C:\Windows\Temp\Win7-2-MAK.log"
    
}
#Remove_KMS_Cofig
pre-configure

Install_ESUkey

Get_Activation_ID

Verify_status

