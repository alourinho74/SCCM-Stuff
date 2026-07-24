$ComputerName = "etvmwda0101"

#Start-Process pwsh.exe -ArgumentList '-file',".\Aux_Scripts\testes.ps1 $ComputerName"

Invoke-Command -FilePath Aux_Scripts\repairwua.ps1 -ArgumentList $ComputerName -ComputerName $ComputerName