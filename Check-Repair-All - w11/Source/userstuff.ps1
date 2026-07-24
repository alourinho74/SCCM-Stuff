Function GetUserInfo2
{
    $auxttributes = @("Name","Domain","lastLogonTimeStamp","whenCreated","OSName","ParentContainerDN")
    $domains = "PTPORTUGAL","PTCOM","PTPRIME","TMN","PTSI","PTPRO","PT-SGPS","PTIN","SAPO"

    $CorpDomain = ".corppt.com"

    $userlocked = $userlockdate = $userlogedin = $userlogindate = $userlogedinuserRDP = $null
    #$userlocked = get-wmiobject Win32_Process -Filter "Name = 'logonui.exe'"  -Computer $ComputerName -ErrorAction Stop
    #$userlocked = get-ciminstance -Class Win32_Process -Filter "Name = 'logonui.exe'"  -Computer $ComputerName -ErrorAction Stop
    $userlocked = get-ciminstance -CimSession $cimsession -Class Win32_Process -Filter "Name = 'logonui.exe'"  -ErrorAction Stop
    if ($userlocked)
    {   
        if($null -eq $userlocked[1])
        {
            #$userlockdate = ($userlocked.ConverttoDateTime($userlocked.CreationDate).ToString('dd MMM yyyy HH:mm:ss  tt'))
            $userlockdate = $userlocked.CreationDate
        }
        else
        {
            Dolog -Message "More than one user locked on computer" -LogLevel 2 -color "Red"
        }
    }

    #$userlogedin = get-wmiobject Win32_Process -Filter "Name = 'explorer.exe'"  -Computer $ComputerName -ErrorAction Stop
    $userlogedin = get-ciminstance -CimSession $cimsession -Class Win32_Process  -Filter "Name = 'explorer.exe'"  -ErrorAction Stop
    #$userlogedinuserRDP = get-wmiobject Win32_Process -Filter "Name = 'explorer.exe'"  -Computer $ComputerName | Invoke-WmiMethod -Name GetOwner #-ErrorAction Stop
    $userlogedinuserRDP = get-ciminstance -CimSession $cimsession -Class Win32_Process  -Filter "Name = 'explorer.exe'" | Invoke-CimMethod -MethodName GetOwner -ErrorAction Stop
    $userlogedinuserRDPUSerComDom = $userlogedinuserRDP.Domain+"\"+$userlogedinuserRDP.User
    if($userlogedin)
    {
        if($null -eq $userlogedin[1])
        {
            #$userlogindate = ($userlogedin.ConverttoDateTime($userlogedin.CreationDate).ToString('dd MMM yyyy HH:mm:ss  tt'))
            $userlogindate = $userlogedin.CreationDate
        }
        else
        {
            Dolog -Message "More than an explorer.exe on computer" -LogLevel 2 -color "Red"
        }
    }
    $userlogged = get-ciminstance -CimSession $cimsession -Class win32_computersystem  | Select-Object username
    if($userlogged.username)
    {
        $t = $userlogged.username.Split("\")
        $dom = $t[0].ToUpper()
        $username = $t[1]
        
        Foreach ($domain in $domains)
        {
            try
            {
                $ADUserInfo = Get-ADUser -server $domain$CorpDomain:389 $username -Properties mail    
                if ($ADUserInfo -ne $null ) 
                {
                    break
                }
                else 
                {
                    $aux++
                }
            }
            catch
            {
            }
        }           
    }   
    elseif  ($userlogedinuserRDP.User)
    {
        Foreach ($domain in $domains)
        {
            try
            { 
                $ADUserInfo = Get-ADUser -server $domain$CorpDomain:389 $userlogedinuserRDP.User -Properties mail  
                if ($ADUserInfo -ne $null ) 
                {
                    break
                }
                else
                {   
                    $aux++
                }
            }
            catch
            {
            }
        }
    }
    if  ($userlogged.username)
    {
        $txt = "Userloggedon " + $userlogged.username + " " + $ADUserInfo.GivenName + " " + $ADUserInfo.Surname + " " + $ADUserInfo.mail
        Dolog -Message $txt -LogLevel 1 -color "White"
    }
    elseif ( $userlogedin ) 
    {
        $txt = "User logged-on by RDP" + $userlogedinuserRDPUSerComDom + " " + $ADUserInfo.GivenName + " " + $ADUserInfo.Surname + " " + $ADUserInfo.mail
        Dolog -Message $txt -LogLevel 1 -color "White"
    }
    else
    {
        Dolog -Message "No user logged-on" -LogLevel 1 -color "White"
    }
    if ($userlockdate -and $userlogged.username)
    {
        $txt = "Computer locked in " + $userlockdate + " and logged on " + $userlogindate
        Dolog -Message $txt -LogLevel 1 -color "Yellow"
    }
    elseif ($userlogindate)
    {
        $txt = "Logged (Not Locked) since " + $userlogindate
        Dolog -Message $txt -LogLevel 2 -color "Red"
    }
}

Function GetUserInfo
{

    $auxttributes = @("Name","Domain","lastLogonTimeStamp","whenCreated","OSName","ParentContainerDN")
    $domains = "PTPORTUGAL","PTCOM","PTPRIME","TMN","PTSI","PTPRO","PT-SGPS","PTIN","SAPO"

    $CorpDomain = ".corppt.com"

    $userlocked = $userlockdate = $userlogedin = $userlogindate = $userlogedinuserRDP = $null

    #$dcomoption = New-CimSessionOption -Protocol Dcom
    #$cimsession = New-CimSession -ComputerName $ComputerName -SessionOption $dcomoption

    #$userlocked = Get-CimInstance Win32_Process -Filter "Name = 'logonui.exe'"  -Computer $ComputerName -ErrorAction Stop
    $userlocked = get-ciminstance -CimSession $cimsession -Class Win32_Process -Filter "Name = 'logonui.exe'" 
    if ($userlocked)
    {   
        if($userlocked[1] -eq $null)
        {
            #$userlockdate = ($userlocked.ConverttoDateTime($userlocked.CreationDate).ToString('dd MMM yyyy HH:mm:ss  tt'))
            $userlockdate = $userlocked.CreationDate
        }
        else
        {
            Dolog -Message "More than one user locked on computer" -LogLevel 2 -color "Red"
        }
    }

    #$userlogedinuserRDP = Get-CimInstance Win32_Process  -Filter "Name = 'explorer.exe'"  -Computer $ComputerName| Invoke-CimMethod -MethodName GetOwner -ErrorAction Stop
    $userlogedin =  get-ciminstance -CimSession $cimsession -class Win32_Process  -Filter "Name = 'explorer.exe'" -ErrorAction Stop
    $userlogedinuserRDP =  get-ciminstance -CimSession $cimsession -class Win32_Process  -Filter "Name = 'explorer.exe'"| Invoke-CimMethod -MethodName GetOwner -ErrorAction Stop
    $userlogedinuserRDPUSerComDom = $userlogedinuserRDP.Domain+"\"+$userlogedinuserRDP.User
    
    if($userlogedin)
    {
        if($null -eq $userlogedin[1])
        {
            #$userlogindate = ($userlogedin.ConverttoDateTime($userlogedin.CreationDate).ToString('dd MMM yyyy HH:mm:ss  tt'))
            $userlogindate = $userlogedin.CreationDate
        }
        else
        {
            Dolog -Message "More than an explorer.exe on computer" -LogLevel 2 -color "Red"
        }
    }




    #$userlogged = get-ciminstance -Class win32_computersystem -ComputerName $ComputerName | select username
    $userlogged = get-ciminstance -CimSession $cimsession  -Class win32_computersystem | Select-Object Username

    if($userlogged.username)
    {
        $t = $userlogged.username.Split("\")
        $dom = $t[0].ToUpper()
        $username = $t[1]
        
        Foreach ($domain in $domains)
        {
            try
            {
                $ADUserInfo = Get-ADUser -server $domain$CorpDomain:389 $username -Properties mail    
                if ($ADUserInfo -ne $null ) 
                {
                    break
                }
                else 
                {
                    $aux++
                }
            }
            catch
            {
            }
        }           
    }
    elseif  ($userlogedinuserRDP.User)
    {
        Foreach ($domain in $domains)
        {
            try
            { 
                $ADUserInfo = Get-ADUser -server $domain$CorpDomain:389 $userlogedinuserRDP.User -Properties mail  
                if ($ADUserInfo -ne $null ) 
                {
                    break
                }
                else
                {   
                    $aux++
                }
            }
            catch
            {
            }
        }
    }
    if  ($userlogged.username)
    {
        $txt = "Userloggedon " + $userlogged.username + " " + $ADUserInfo.GivenName + " " + $ADUserInfo.Surname + " " + $ADUserInfo.mail
        Dolog -Message $txt -LogLevel 1 -color "White"
    }
    elseif ( $userlogedin ) 
    {
        $txt = "User logged-on by RDP" + $userlogedinuserRDPUSerComDom + " " + $ADUserInfo.GivenName + " " + $ADUserInfo.Surname + " " + $ADUserInfo.mail
        Dolog -Message $txt -LogLevel 1 -color "White"
    }
    else
    {
        Dolog -Message "No user logged-on" -LogLevel 1 -color "White"
    }
    if ($userlockdate -and $userlogged.username)
    {
        $txt = "Computer locked in " + $userlockdate + " and logged on " + $userlogindate
        Dolog -Message $txt -LogLevel 1 -color "Yellow"
    }
    elseif ($userlogindate)
    {
        $txt = "Logged (Not Locked) since " + $userlogindate
        Dolog -Message $txt -LogLevel 2 -color "Red"
    }



}