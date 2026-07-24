$listafile = $PSScriptRoot + "\" + "Computers.txt"


$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path 
#Write-Host "Current script directory is $ScriptDir"

$scriptexe = """" + $ScriptDir + "\run.ps1" + """"
#Write-Host $scriptexe

$hostnames = Get-Content $listafile

foreach ($i in $hostnames)
{
    Write-Host $i
    if (Test-Connection -count 1 -Quiet $i)
    {
        start-process powershell.exe -argument "-noexit -nologo -noprofile -command .\Run.ps1 $i"
    }
}
