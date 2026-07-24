Function Verify_status
{
        $name = cscript c:\windows\System32\slmgr.vbs /dlv >> "C:\Windows\Temp\Win7-2-MAK.log"

        $licence_status = $name

        $namefull = $name | Select-String -Pattern "Name: "
        $namefull = $namefull -split ": "
        $namefull = $namefull[1]
        $namefull >> "C:\Windows\Temp\Win7-2-MAK.log"
        Write-Host $namefull
        $namefull_ok = $namefull -match 'Client-ESU-Year1 add-on'

        $licence_statusfull = $licence_status| Select-String -Pattern "License Status: "
        $licence_statusfull = $licence_statusfull -split ": "
        $licence_statusfull = $licence_statusfull[1]
        Write-Host $licence_statusfull
        $licence_statusfull >> "C:\Windows\Temp\Win7-2-MAK.log"

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
            #Dolog -Message "Script verification was successfully - Windows Activated with MAK key!" -color "Green"
            #create_signature "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" "SCCM-DIT-Windows7-TO-MAK"
            #Exit_script (0)
            echo "OK" >> "C:\Windows\Temp\Win7-2-MAK.log"

        }
        else
        {
            echo "NOT OK" >> "C:\Windows\Temp\Win7-2-MAK.log"
            #Dolog -Message "<< Error activating windows >>" -color "Red"
            #$txt = "Name: " + $namefull
            #Dolog -Message $txt -color "Red"
            #$txt = "Licence: " + $licence_statusfull
            #Dolog -Message $txt -color "Red"
            #Exit_script (1)
        }
        
}
Function Activate_ESU_key
{
  
    $ActKey = cscript c:\windows\System32\slmgr.vbs /ato 77db037b-95c3-48d7-a3ab-a9c6d41093e0  >> "C:\Windows\Temp\Win7-2-MAK.log"
    echo "-> " $LASTEXITCODE >> "C:\Windows\Temp\Win7-2-MAK.log"
    

        
}

Function Install_ESUkey
{
    $key = "W2MKH-RPW2T-PWWH7-GQ4GC-R22GH"
    #$key = "W2MKH-RPW2T-PWWH7-GQ4GC-R22DD"
    cscript c:\windows\System32\slmgr.vbs /ipk $key  >> "C:\Windows\Temp\Win7-2-MAK.log"
    #$LASTEXITCODE >> "C:\Windows\Temp\Win7-2-MAK.log"
    
    if ($LASTEXITCODE -eq 0)   
    {
       echo "sucesso. RC=" $LASTEXITCODE >> "C:\Windows\Temp\Win7-2-MAK.log"
    }
    else
    {
        echo "Erro. RC=" $LASTEXITCODE >> "C:\Windows\Temp\Win7-2-MAK.log"
    }

}
Function pre-configure
{

    
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

#cscript c:\windows\System32\slmgr.vbs /upk  > "C:\Windows\Temp\Win7-2-MAK.log"

pre-configure

Install_ESUkey

Activate_ESU_key

Verify_status