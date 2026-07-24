Function repair_bits
{
    $StartTime = (Get-Date).AddDays(-2)
    $ServiceBits = "Bits"


    $bitserrros = Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $ComputerName -FilterHashtable @{
        LogName="system" 
        ProviderName="Microsoft-Windows-Bits-Client"
        ID="16392"
        StartTIme=$StartTime
    }
    Dolog -Message "Getting last 24 hours bits errors" -LogLevel 1 -color "White"

    if ($bitserrros)
{
    #Copy-Item .\Aux_Scripts\recover_bits.cmd \\$computername\c$\windows\Temp -Force
    #Move-Item -path \\$computername\c$\ProgramData\Microsoft\Network\ -Destination \\$computername\c$\ProgramData\Microsoft\Network\Downloader\old_qmgr.jfm -Force -PassThru
    Dolog -Message "Renaming c:\ProgramData\Microsoft\Network\Downloader Folder" -LogLevel 1 -color "White"
    try 
    {
        Move-Item -path \\$computername\c$\ProgramData\Microsoft\Network\Downloader -Destination \\$computername\c$\ProgramData\Microsoft\Network\old.Downloader -Force -PassThru    
        Dolog -Message "successfully renamed c:\ProgramData\Microsoft\Network\Downloader Folder " -LogLevel 1 -color "Green"
    }
    catch 
    {
        Dolog -Message "Error renaming c:\ProgramData\Microsoft\Network\Downloader Folder" -LogLevel 3 -color "Red"    
    }
    
    #psexec -s \\$ComputerName c:\windows\temp\recover_bits.cmd 2>$null
    if($ServiceBits)
    {
        if ($ServiceBits.Status -ne "Running")
        {
            $ServiceBits | Set-Service -startuptype "Manual" -Status Running -PassThru
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
        Dolog -Message "Bits Servive does not exists!!"   -LogLevel 3 -color "Red"
    }
}

}

function check_bits
{
    $StartTime = (Get-Date).AddDays(-2)

    Dolog -Message "Getting last 24 hours bits errors" -LogLevel 1 -color "White"

    $bitserrros = Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $ComputerName -FilterHashtable @{
        LogName="system" 
        ProviderName="Microsoft-Windows-Bits-Client"
        ID="16392"
        StartTIme=$StartTime
    }


    if ($bitserrros)
    {
        Dolog -message "Possible problem with Bits Service" -LogLevel 2 -color "Yellow"
        return $false
    }
    else
    {
        Dolog -message "Bits Service is OK" -LogLevel 2 -color "Yellow"
        return $true
    }
}
