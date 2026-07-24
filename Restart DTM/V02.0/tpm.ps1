function get_tpm_status
{

    Write-Host $computername -ForegroundColor Red
    try
    {
        #$tpm = Get-WmiObject -class Win32_Tpm -namespace root\CIMV2\Security\MicrosoftTpm -ComputerName $computername
        $tpm = get-tpm

        if ($tpm.TpmPresent -eq $false)
        {
            Write-Host "NO TPM"

            try
            {
                Write-Host "Bit Locker suspended until next restart"
                
                $OS = Get-WMiobject -Class Win32_operatingsystem -ComputerName .

                Suspend-BitLocker -MountPoint "$($os.systemdrive)"
            }
            catch
            {
                Write-Host "Unable to Suspend Bitlocker"
            }
            return $false
        }
        else
        {
            write-host "TPM"
            
            return $true
        }
    }
    catch
    {
        write-host "Unable to query" -ForegroundColor red
        return $false
    }



}



#get_tpm_status "td80003332"
#get_tpm_status "td00825300"
#get_tpm_status "ET00826071"

get_tpm_status