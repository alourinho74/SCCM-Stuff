Function Check_Disk
{
    $SmartList = "1;Read Error Rate","2;Throughput Performance","3;Spin-Up Time","4;Start/Stop Count","5;Reallocated Sectors Count","6;Read Channel Margin",
                    "7;Seek Error Rate","8;Seek Time Performance","9;Power-On Hours","10;Spin Retry Count","11;Recalibration Retries or Calibration Retry Count",
                    "12;Power Cycle Count","13;Soft Read Error Rate","22;Current Helium Level","167;Write_Protect_Mod","168;SATA_Phy_Error_Count","169;Bad_Block_Rate",
                    "170;Available Reserved Space","171;SSD Program Fail Count","172;SSD Erase Fail Count","173;SSD Wear Leveling Count","174;Unexpected Power Loss Count",
                    "175;Power Loss Protection Failure","176;Erase Fail Count","177;Wear Range Delta","179;Used Reserved Block Count Total",
                    "180;Unused Reserved Block Count Total","181;Program Fail Count Total or Non-4K Aligned Access Count",
                    "182;Erase Fail Count","183;SATA Downshift Error Count or Runtime Bad Block","184;End-to-End error / IOEDC","185;Head Stability","186;Induced Op-Vibration Detection",
                    "187;Reported Uncorrectable Errors","188;Command Timeout","189;High Fly Writes","190;Temperature Difference or Airflow Temperature","191;G-sense Error Rate",
                    "192;Power-off Retract Count, Emergency Retract Cycle Count (Fujitsu), or Unsafe Shutdown Count",
                    "193;Load Cycle Count or Load/Unload Cycle Count (Fujitsu)","194;Temperature or Temperature Celsius","195;Hardware ECC Recovered","196;Reallocation Event Count",
                    "197;Current Pending Sector Count","198;(Offline) Uncorrectable Sector Count","199;UltraDMA CRC Error Count","200;Multi-Zone Error Rate / Write Error Rate (Fujitsu)",
                    "201;Soft Read Error Rate or TA Counter Detected","202;Data Address Mark errors or TA Counter Increased","203;Run Out Cancel",
                    "204;Soft ECC Correction","205;Thermal Asperity Rate","206;Flying Height","207;Spin High Current","208;Spin Buzz","209;Offline Seek Performance",
                    "210;Vibration During Write","218;CRC_Error_Count","211;Vibration During Write","212;Shock During Write",
                    "220;Disk Shift","221;G-Sense Error Rate","222;Loaded Hours","223;Load/Unload Retry Count","224;Load Friction",
                    "225;Load/Unload Cycle Count","226;Load 'In'-time","227;Torque Amplification Count","228;Power-Off Retract Cycle",
                    "230;GMR Head Amplitude (magnetic HDDs), Drive Life Protection Status (SSDs)","231;Life Left (SSDs) or Temperature","232;Endurance Remaining or Available Reserved Space",
                    "233;Media Wearout Indicator (SSDs) or Power-On Hours","234;Average erase count AND Maximum Erase Count","235;Good Block Count AND System(Free) Block Count",
                    "240;Head Flying Hours or 'Transfer Error Rate' (Fujitsu)","241;Total LBAs Written","242;Total LBAs Read","243;Total LBAs Written Expanded","244;Total LBAs Read Expanded",
                    "245;Max_Erase_Count","246;Total_Erase_Count","249;NAND Writes (1GiB)","250;Read Error Retry Rate","251;Minimum Spares Remaining","252;Newly Added Bad Flash Block","254;Free Fall Protection"
    $SmartColl = @()
    $SmartList | % { $SmartColl += [pscustomobject]@{ ID = $_.split(";")[0];  AttrName = $_.split(";")[1] } }
    $WKS = $ComputerName
    $DiskS = Get-WmiObject -Namespace root\cimv2 -Class Win32_DiskDrive  -ComputerName $WKS
    $MSFTDisk = Get-WmiObject -Namespace root\Microsoft\Windows\Storage -Class MSFT_PhysicalDisk -ComputerName $WKS -ErrorAction SilentlyContinue
    $SmartS = Get-WmiObject -Namespace root\WMI -Class MSStorageDriver_FailurePredictData -ComputerName $WKS  -ErrorAction SilentlyContinue
    $ThreshS = Get-WmiObject -Namespace root\WMI -Class MSStorageDriver_FailurePredictThresholds -ComputerName $WKS  -ErrorAction SilentlyContinue

                # write-host ("-"*140)
                # Write-host -ForegrouxndColor Blue $WKS

    foreach ( $dsk in $DiskS)
    {
        # $dsk.Serialnumber
        # "$dsk.PNPDeviceID"
        $Modelo =  ($dsk.Model)
        $NumSer = $dsk.SerialNumber 
        $DskSize = "{0:n2}" -f ($dsk.size /1GB)
        if ( $MSFTDisk )
        {
            foreach ( $MS in $MSFTDisk )
            {
                # if ( $MS )
                if ( $MS.SerialNumber -eq  "$($dsk.Serialnumber)".trim() )
                {
                    <#  
                    BusType : 0 - Unknown 1 - SCSI 2 - ATAPI 3 - ATA  4 - 1394 5 - SSA 6 - Fibre Channel 7 - USB
                    8 - RAID 9 - iSCSI 10 - SAS 11 - SATA 12 - SD 13 - MMC 14 - Virtual 15 - File Backed Virtual
                    16 - Storage Spaces 17 - NVMe
                                
                    MediaType : 0 - Unspecified 3 - HDD 4 - SSD
                    #>
                
                    switch ( $MS.BusType ) 
                    {
                        "0" { $Bus = "Unknown" }
                        "1" { $Bus = "SCSI" }
                        "2" { $Bus = "ATAPI" }
                        "3" { $Bus = "ATA" }
                        "4" { $Bus = "1394" }
                        "7" { $Bus = "USB" }
                        "8" { $Bus = "RAID" }
                        "9" { $Bus = "iSCSI" }
                        "10" { $Bus = "SAS" }
                        "11" { $Bus = "SATA" }
                        "12" { $Bus = "SD" }
                        "13" { $Bus = "MMC" }
                        "14" { $Bus = "Virtual" }
                        "17" { $Bus = "NVMe" }
                    }
                    switch ( $MS.MediaType ) 
                    {
                        "0" { $MediaType = "Unspecified" }
                        "3" { $MediaType = "HDD" }
                        "4" { $MediaType = "SSD" }
                    }
                }
            }
        }
                    
        write-host ("-"*140)

        #$txt =  ("{0,-50}{1,-53}{2,10}{3,12}{4,13}" -f "Modelo", "Num Serie", "Size", "Disk Type", "Bus")
        #Dolog -Message $txt -LogLevel 1 -color "White"

        write-host -ForegroundColor Blue ("{0,-50}{1,-53}{2,10}{3,12}{4,13}" -f "Modelo", "Num Serie", "Size", "Disk Type", "Bus")
        # write-host ("-"*140)
        # "{0,-10}{1,-98}{2,9}{3,11}{4,10}"

        write-host ("{0,-50}{1,-53}{2,10}{3,12}{4,13}" -f $Modelo, $NumSer, ($DskSize + " GB"), $MediaType, $Bus)
        #write-host ("-"*140)
        foreach ( $Smart1 in $SmartS )
        {
            # PNPDeviceID         : SCSI\DISK&VEN_WDC&PROD_WD5000BPKX-80HPJ\4&2B20B219&0&010000
            # InstanceName        : SCSI\Disk&Ven_WDC&Prod_WD5000BPKX-80HPJ\4&2b20b219&0&010000_0
            # $inst = "$($Smart.InstanceName)" -replace '\\','' 
            # $PNP = "$($dsk.PNPDeviceID)" -replace '\\','' 
            # write-host "$Inst" "$PNP"
            # if ( ( "$Inst" -match  "$PNP"  )  )
            if ( "$( "$($Smart1.InstanceName)" -replace '\\','' )" -match  "$("$($dsk.PNPDeviceID)" -replace '\\','' )"  )
            {
                $Thresh = $ThreshS | ? { $("$($_.InstanceName)" -replace '\\','') -eq $( "$($Smart1.InstanceName)" -replace '\\','' )}
                Get-DiskStatus $Smart1 $Thresh
                # "$($Smart.InstanceName)"
            }
        }
    }
    write-host ("-"*140)
}



function Get-DiskStatus
{
    $smart = $ARGS[0]
    $Thresh = $ARGS[1]

    if ($smart.VendorSpecific.Length -gt 0)
    {
        $smart = @($smart)
        $Thresh = @($Thresh)
    }

    
    #write-host ("-"*140)
    #Write-host  -ForegroundColor Blue ("{0,-5}{1,-95}{2,-7}{3,-7}{4,-7}{5,-10}"  -f "ID", "AttrName", "Value", "Worst", "Thresh", "RawValue")
    
    $t =  ("-"*140)
    $h =  ("{0,-5}{1,-95}{2,-7}{3,-7}{4,-7}{5,-10}"  -f "ID", "AttrName", "Value", "Worst", "Thresh", "RawValue")

    DOlog -Message $t -LogLevel 1 -color "White"
    DOlog -Message $h -LogLevel 1 -color "White"
    
    #write-host ("-"*140)
    # $smart.Length
    for ($n = 0; $n -lt $smart.Length ; $n++) 
    {
        # $result = @()
        for ($i = 2; $i -lt ( $smart[$n].VendorSpecific.Length - 200 ); $i += 12) 
        {
            if ( ($smart[$n].VendorSpecific[$i] ) -ne "0" )
            {
                $AttrID = $smart[$n].VendorSpecific[$i];
                $AttrName = ( $SmartColl  | where ID -eq $smart[$n].VendorSpecific[$i] ).AttrName;
                if ( $AttrName -eq $null ) 
                { 
                    $AttrName  = "Unknown_Attribute" 
                }
                $AttrValue = $smart[$n].VendorSpecific[$i+3];
                $WorstValue = $smart[$n].VendorSpecific[$i+4];
                $ThreshValue = $Thresh[$n].VendorSpecific[$i+1];
                $Raws = ( $smart[$n].VendorSpecific[($i+5)] + $smart[$n].VendorSpecific[($i+6)] * 256  + 
                    $smart[$n].VendorSpecific[($i+7)] * 256 * 256 + $smart[$n].VendorSpecific[($i+8)] * 256 * 256 * 256 );
                if ( $AttrID -eq 190 )
                {  
                    $Temp = "(Min/Max $($smart[$n].VendorSpecific[($i+7)])/$($smart[$n].VendorSpecific[($i+8)]))"
                    $Raws = "$( $smart[$n].VendorSpecific[($i+5)] + $smart[$n].VendorSpecific[($i+6)] * 256 ) $Temp"
                }
                if ( $AttrID -eq 173 ) 
                {  
                    $Raws = "$($smart[$n].VendorSpecific[($i+5)]) (Average $($smart[$n].VendorSpecific[($i+7)]))"
                }
                if ( $AttrID -eq 194 ) 
                {
                    if ( $($smart[$n].VendorSpecific[($i+7)]) -eq 0 -and $($smart[$n].VendorSpecific[($i+9)]) -eq 0 )
                    {
                        $Raws = "$( $smart[$n].VendorSpecific[($i+5)] + $smart[$n].VendorSpecific[($i+6)] * 256 )"
                    }
                    else 
                    {
                        $Temp = "(Min/Max $($smart[$n].VendorSpecific[($i+7)])/$($smart[$n].VendorSpecific[($i+9)]))"
                        $Raws = "$( $smart[$n].VendorSpecific[($i+5)] + $smart[$n].VendorSpecific[($i+6)] * 256 ) $Temp"
                    }
                }
                $Lin = "{0,-5}{1,-95}{2,-7}{3,-7}{4,-7}{5,-10}"  -f $AttrID, $AttrName, $AttrValue, $WorstValue, $ThreshValue, $Raws
                if ( $AttrID -eq 5 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin "}
                }
                elseif ( $AttrID -eq 10 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 184 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 187 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 188 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 196 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 197 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 198 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                elseif ( $AttrID -eq 201 -and $Raws -ne 0 )
                {
                    $Lin = @{ ForegroundColor = "Red";	Object = "$Lin " }
                }
                else
                {
                    $Lin = @{ ForegroundColor = "Green"; Object = $Lin }
                }
                Write-host @Lin               
            }
        }
    }
}