$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 5)
$RunspacePool.Open()

$ScriptBlock = { Get-Random }

$Runspaces = @()
(1..5) | ForEach-Object {
    $Runspace = [powershell]::Create().AddScript($ScriptBlock)
    $Runspace.RunspacePool = $RunspacePool
    $Runspaces += New-Object PSObject -Property @{
        Runspace = $Runspace
        State = $Runspace.BeginInvoke()
    }
}

while ( $Runspaces.State.IsCompleted -contains $False) { Start-Sleep -Milliseconds 10 }

$Results = @()

$Runspaces | ForEach-Object {
    $Results += $_.Runspace.EndInvoke($_.State)
    Write-Host $Results
}

