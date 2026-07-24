function parseInfFile{
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String] $Inputfile
    )


if ($Inputfile -eq ""){
    Write-Error "Ini File Parser: No file specified or selected to parse."
    Break
}
else{
 
    $ContentFile = Get-Content $Inputfile
    # commented Section
    $COMMENT_CHARACTERS = ";"
    # match section header
    $HEADER_REGEX = "\[+[A-Z0-9._ %<>/#+-]+\]" 
 
        $OccurenceOfComment = 0
        $ContentComment   = $ContentFile | Where { ($_ -match "^\s*$COMMENT_CHARACTERS") -or ($_ -match "^$COMMENT_CHARACTERS")  }  | % { 
            [PSCustomObject]@{ Comment= $_ ; 
                 Index = [Array]::IndexOf($ContentFile,$_) 
            }
            $OccurenceOfComment++
        }
 
        $COMMENT_INI = @()
        foreach ($COMMENT_ELEMENT in $ContentComment){
            $COMMENT_OBJ = New-Object PSObject
            $COMMENT_OBJ | Add-Member  -type NoteProperty -name Index -value $COMMENT_ELEMENT.Index
            $COMMENT_OBJ | Add-Member  -type NoteProperty -name Comment -value $COMMENT_ELEMENT.Comment
            $COMMENT_INI += $COMMENT_OBJ
        }
 
        $CONTENT_USEFUL = $ContentFile | Where { ($_ -notmatch "^\s*$COMMENT_CHARACTERS") -or ($_ -notmatch "^$COMMENT_CHARACTERS") } 
        $ALL_SECTION_HASHTABLE      = $CONTENT_USEFUL | Where { $_ -match $HEADER_REGEX  } | % { [PSCustomObject]@{ Section= $_ ; Index = [Array]::IndexOf($CONTENT_USEFUL,$_) }}
        #$ContentUncomment | Select-String -AllMatches $HEADER_REGEX | Select-Object -ExpandProperty Matches
 
        $SECTION_INI = @()
        foreach ($SECTION_ELEMENT in $ALL_SECTION_HASHTABLE){
            $SECTION_OBJ = New-Object PSObject
            $SECTION_OBJ | Add-Member  -type NoteProperty -name Index -value $SECTION_ELEMENT.Index
            $SECTION_OBJ | Add-Member  -type NoteProperty -name Section -value $SECTION_ELEMENT.Section
            $SECTION_INI += $SECTION_OBJ
        }
 
        $INI_FILE_CONTENT = @()
        $NBR_OF_SECTION = $SECTION_INI.count
        $NBR_MAX_LINE   = $CONTENT_USEFUL.count
 
        #*********************************************
        # select each lines and value of each section 
        #*********************************************
        for ($i=1; $i -le $NBR_OF_SECTION ; $i++){
            if($i -ne $NBR_OF_SECTION){
                if(($SECTION_INI[$i-1].Index+1) -eq ($SECTION_INI[$i].Index )){        
                    $CONVERTED_OBJ = @() #There is nothing between the two section
                } 
                else{
                    $SECTION_STRING = $CONTENT_USEFUL | Select-Object -Index  (($SECTION_INI[$i-1].Index+1)..($SECTION_INI[$i].Index-1)) | Out-String
                    try
                    {
                        $CONVERTED_OBJ = convertfrom-stringdata -stringdata $SECTION_STRING
                    }
                    catch
                    {
                    }
                    #$CONVERTED_OBJ = convertfrom-stringdata -stringdata $SECTION_STRING
                }
            }
            else{
                if(($SECTION_INI[$i-1].Index+1) -eq $NBR_MAX_LINE){        
                    $CONVERTED_OBJ = @() #There is nothing between the two section
                } 
                else{
               
                    $SECTION_STRING = $CONTENT_USEFUL | Select-Object -Index  (($SECTION_INI[$i-1].Index+1)..($NBR_MAX_LINE-1)) | Out-String
                    
                }
            }
            $CURRENT_SECTION = New-Object PSObject
            $CURRENT_SECTION | Add-Member -Type NoteProperty -Name Section -Value $SECTION_INI[$i-1].Section
            $CURRENT_SECTION | Add-Member -Type NoteProperty -Name Content -Value $CONVERTED_OBJ
            $INI_FILE_CONTENT += $CURRENT_SECTION
        }
     return $INI_FILE_CONTENT
    }
}
    
Function handle_inf
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String] $Inputfile
    )

    $inftrue = Test-Path  $Inputfile

    if(!$inftrue)
    {
        #$aux = $Inputfile.Split("\")
        #$finaltxt = "$infprovider,$infDriverver,$infDriverDate,$device,$infCatalogFile,$infClass"
        $finaltxt = "--","--","--","Does not exist. Already uninstalled!","--","--"
        return $finaltxt
        
        
    }
    else
    {
        
    
        $result = parseInfFile $Inputfile

        if ($result.section -eq '[Version]')
        {
            $infprovider =  $result.content.Provider
            $infClass = $result.content.Class
            $infDriverVersion = $result.content.DriverVer
            $infDriverVersion2 = $result.content.DriverVer.Split(",")
            $infDriverDate = ($infDriverVersion2[0]).Trim()
            $infDriverver = ($infDriverVersion2[1]).Trim()
            
            if ($result.content."CatalogFile.NT")
            {
                $infCatalogFile = $result.content."CatalogFile.NT"
            }
            if ($result.content.CatalogFile)
            {
                $infCatalogFile = $result.content.CatalogFile
            }
            if ($result.content."CatalogFile.ntx86")
            {
                $infCatalogFile = $result.content."CatalogFile.ntx86"
            }
            if ($result.content."CatalogFile.ntamd64")
            {
                $infCatalogFile = $result.content."CatalogFile.ntamd64"
            }

            
            #if ($result.content.DriverVer)
            #{
            #    $infCatalogFile = $result.content.DriverVer
            #}
        }
        
        if ($result.section -eq '[Strings]')
        {
            $infMfg =  $result.content.Mfg
            $infDeviceDesc = $result.content.DeviceDesc
            $infname = $result.content.Name
            $infClassGUID = $result.content.ClassGUID
            #$infCatalogFile = $result.content.CatalogFile

            switch ($infCatalogFile)
            {
                "prnms001.cat" {$device = "Microsoft XPS Document Writer v4"}
                "prnms009.cat" {$device = "Microsoft Print To PDF"}
                "wirelessbuttondriver64.cat" {$device = "Wireless Button"}
                "CougarPoint.cat" {$device = "Yellow-bang removal and brands Intel(R) devices"}
                "hpqaccx64.cat" {$device = "HP ACCELEROMETER driver"}
                "hpqaccamd64.cat" {$device = "HP ACCELEROMETER driver"}
                "hpqaccx86.cat" {$device = "HP ACCELEROMETER driver"}
                "chdrt.cat" {$device = "Conexant Function Driver for High Definition Audio Device"}
                "snp2uvc.cat" {$device = "USB Video Class Device INF"}
                "IvyBridge.cat" {$device = "Yellow-bang removal and brands Intel(R) devices"}
                "ich78usb.cat" {$device = "Intel(R) 82801 USB devices"}
                "SPUVCB.cat" {$device = "SunplusIT HP HD Webcam [Fixed]"}
                "Lynxpoint-HRefresh.cat" {$device = "yellow-bang removal and brands Intel(R) devices"}
                default {$device = "Unknown - $infCatalogFile"}
            }
        }

        $finaltxt = "$infprovider,$infDriverver,$infDriverDate,$device,$infCatalogFile,$infClass"
        return $finaltxt
    }
} 
    
