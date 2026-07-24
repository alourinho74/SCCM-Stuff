Add-Type -Assembly PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

[xml]$XAML_Menu = @"
<Window Name="Get_App"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Altice Portugal - Check if an App is installed" Height="550" Width="900" Background="Black" ResizeMode="NoResize">
    <Grid>
        <DataGrid x:Name="DataGrid_values" VerticalAlignment="Top" Height="400" Width="998" Margin="5,100,5,80" IsReadOnly="True"/>
        <TextBox x:Name="Textbox_appname" HorizontalAlignment="Left" Margin="5,445,0,0" TextWrapping="Wrap" Text="-- Double Click to Enter Application to search --" VerticalAlignment="Top" Width="380" Height="26" FontSize="14"/>
        <Button x:Name="Button_Search" Content="Search" HorizontalAlignment="Left" Margin="400,445,0,0" VerticalAlignment="Top" Width="50" Height="26"/>
        <Button x:Name="Button_Export" Content="Export" HorizontalAlignment="Left" Margin="725,445,0,0" VerticalAlignment="Top" Width="50" Height="26"/>
        <Button x:Name="Button_Close" Content="Close" HorizontalAlignment="Left" Margin="825,445,0,0" VerticalAlignment="Top" Width="50" Height="26"/>
        <Image x:Name="form_image" HorizontalAlignment="Left" Height="75" Width="75" Margin="5,10,0,0" VerticalAlignment="Top" Source="$($PSScriptRoot)\Logo.jpg" Visibility="Visible"/>
        <Label x:Name="Label_Header" Content="Check if an Application is installed" HorizontalAlignment="Left" Margin="100,55,0,0" VerticalAlignment="Top" Width="380" Height="35" FontSize="20" Foreground="White"/>
        <ProgressBar x:Name="ProgressBar_Exec" HorizontalAlignment="Left" Height="20" Margin="5,480,0,0" VerticalAlignment="Top" Width="870" Background="White"/>
    </Grid>
</Window>
"@

$Reader = (New-Object System.Xml.XmlNodeReader $XAML_Menu)
try {
    $Window = [Windows.Markup.XamlReader]::Load($Reader)    
}
catch {
    Write-Host "Error loading form"
}


$DataGrid_values = $Window.FindName('DataGrid_values')
$Textbox_appname = $Window.FindName('Textbox_appname')
$Button_Search = $Window.FindName("Button_Search")
$Button_Export = $Window.FindName("Button_Export")
$Button_Close = $Window.FindName("Button_Close")
$ProgressBar_Exec = $Window.FindName("ProgressBar_Exec")
$csv_file = "$($env:TEMP)\temp.csv"
Function Export_data
{
    Write-Host $csv_file
    $dlg = New-Object 'Microsoft.Win32.SaveFileDialog'
    $dlg.DefaultExt = ".csv"
    $dlg.Filter = "Csv files (.csv)|*.csv" 
    $result = $dlg.ShowDialog()

    if ($result) 
    {
        $filename = $dlg.FileName;
        Copy-Item -Path $csv_file -Destination $filename -Force
    }
}
Function Get_App
{
    $script:app_name = $Textbox_appname.text.ToString()
    $app_name = $app_name.trim()

    Write-Host $app_nameapp -ForegroundColor Magenta

    $DataGrid_values.IsReadOnly

    $script:input_file =  "$($PSScriptRoot)\list.txt"
    
    New-Item -ItemType File -Path $csv_file -Force

    $script:allhostnames = Get-content -Path $input_file
    $script:total_hosts = (Get-content $input_file).Length
    Write-Host $total_hosts

    $Columns=@(
        'Hostname'
        'Application Name'
        'Application Version'
        'Install Date'
    )

    $DataTable=New-Object System.Data.DataTable
    [void]$DataTable.Columns.AddRange($Columns)

    Add-Content $csv_file ("Hostname,Application Name,Application Version,Install Date")

    $hosts_apps = @()
    $j=0
    foreach ($strHostname in $allhostnames)
    {
        #$j++
        if ($strHostname -ne "")
        {
            if (Test-Connection -count 1 -Quiet $strHostname)
            {
                try 
                {
                    Write-Host $strHostname
                    Write-Host $app_name
                    #$app_sign = Get-CimClass -computername $strHostname -Namespace "ROOT\cimv2\sms" -ClassName "sms_installedSoftware" -Query "Select ArpDisplayname,ProductVersion,InstallDate From sms_installedSoftware where ArpDisplayname like '%app_name%'" -ErrorAction Stop
                    $app_sign = Get-WmiObject -Computer $strHostname -Class SMS_InstalledSoftware -Namespace "root/cimv2/sms" | Where-Object {$_.ARPDisplayName -match $app_name}

                    $aux = $app_sign
                
                    
                    Write-Host $aux.ArpDisplayName  -ForegroundColor Yellow
                    Write-Host $aux.count  -ForegroundColor Green
                }
                catch {
                    Write-Host "catch"
                }

               


                if (($app_sign).count -ge 2)
                {
                    for ($i = 0; $i -le ($app_sign).count -1; $i++) 
                    {
                        $object = New-Object -TypeName PSObject
                        $object | Add-Member -Name 'Hostname' -MemberType Noteproperty -Value $strHostname
                        $object | Add-Member -Name 'Application Name' -MemberType Noteproperty -Value $app_sign.ArpDisplayname[$i]
                        $object | Add-Member -Name 'Application Version' -MemberType Noteproperty -Value $app_sign.ProductVersion[$i]
                        $object | Add-Member -Name 'Install Date' -MemberType Noteproperty -Value $app_sign.InstallDate[$i]
                        $hosts_apps += $object
                        
                        try 
                        {
                            $DateStr = [DateTime]::new((([wmi]"").ConvertToDateTime($app_sign.InstallDate[$i])).Ticks, 'Local')
                             
                        }
                        catch
                        {
                            $DateStr = ""
                        }
                        $DataTable.Rows.Add($strHostname,$app_sign.ArpDisplayname[$i],$app_sign.ProductVersion[$i],$DateStr)
                        $line = "$($strHostname),$($app_sign.ArpDisplayname[$i]),$($app_sign.ProductVersion[$i]),$($DateStr)"
                        Add-Content $csv_file $line
                        
                    } 
                }
                elseif (($app_sign).count -eq 1)
                {
                    $object = New-Object -TypeName PSObject
                    $object | Add-Member -Name 'Hostname' -MemberType Noteproperty -Value $strHostname
                    $object | Add-Member -Name 'Application Name' -MemberType Noteproperty -Value $app_sign.ArpDisplayname
                    $object | Add-Member -Name 'Application Version' -MemberType Noteproperty -Value $app_sign.ProductVersion
                    $object | Add-Member -Name 'Install Date' -MemberType Noteproperty -Value $app_sign.InstallDate
                    $hosts_apps += $object
                    
                    try 
                    {
                        $DateStr = [DateTime]::new((([wmi]"").ConvertToDateTime($app_sign.InstallDate)).Ticks, 'Local')
                        
                    }
                    catch
                    {
                        $DateStr = ""
                    }
                    $DataTable.Rows.Add($strHostname,$app_sign.ArpDisplayname,$app_sign.ProductVersion,$DateStr)
                    $line = "$($strHostname),$($app_sign.ArpDisplayname),$($app_sign.ProductVersion),$($DateStr)"
                    Add-Content $csv_file $line
                }
                else
                {
                    $DataTable.Rows.Add($strHostname,"Not Installed","","")
                    $line = "$($strHostname),Not Installed,,"
                    Add-Content $csv_file $line
                }
                #Write-Host $services -ForegroundColor Yellow
                #Write-Host $object -ForegroundColor Cyan
                $DataGrid_values.ItemsSource=$DataTable.DefaultView 
            }
            else 
            {
                $DataTable.Rows.Add($strHostname,"Not Responding","","")
                Add-Content $csv_file "$($strHostname),Not Responding,,"
            }
                        
           # Write-Host $j
            $ProgressBar_Exec.Dispatcher.Invoke([action]{
                $ProgressBar_Exec.value = $j
            }, "Normal")
        }
    }
    #$DataGrid_values.ItemsSource=$DataTable.DefaultView 
    $DataGrid_values.Columns[0].Width = '170'
    $DataGrid_values.Columns[1].Width = '450'
    $DataGrid_values.Columns[2].Width = '105'
    $DataGrid_values.Columns[3].Width = '144'    
}


$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$myIconPath = Join-Path $scriptPath 'Logo.jpg'

$Window.add_Loaded({
    $Window.Icon = $myIconPath
})

$Textbox_appname.Add_MouseDoubleClick({
    $Textbox_appname.text = ""
})

$Button_Close.Add_Click({
    $Window.Close()
})

$Button_Search.add_click({
    Get_App
})

$Button_Export.add_click({
    Export_data
})

$Window.ShowDialog() | Out-Null



