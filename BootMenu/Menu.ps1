Add-Type -Assembly PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

[xml]$XAML_Menu = @"
<Window Name="Form_ConnectDialog"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Menu Triggers" Height="300" Width="500" Background="PapayaWhip" ResizeMode="NoResize">
    <Grid>
        <Label x:Name="Lable_Hostname" Content="Enter Hostname"  HorizontalAlignment="Left" Margin="20,40,0,0" VerticalAlignment="Top"/>
        <Button x:Name="Button_Ok" Content="Validate" HorizontalAlignment="Left" Margin="381,234,0,0" VerticalAlignment="Top" Height="20"/>
        <Label x:Name="Lable_Apps" Content="Choose Applications" HorizontalAlignment="Left" Margin="20,120,0,0" VerticalAlignment="Top" Width="145" Grid.ColumnSpan="2"/>
        <CheckBox x:Name="CheckBox_7zip" Content="7-Zip" HorizontalAlignment="Left" Margin="25,150,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="CheckBox_Acrobat" Content="Acrobat Reader" HorizontalAlignment="Left" Margin="25,179,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="CheckBox_Powershell7" Content="Powershell 7" HorizontalAlignment="Left" Margin="25,210,0,0" VerticalAlignment="Top"/>
        <TextBox x:Name="Textbox_Hostname" HorizontalAlignment="Left" Margin="20,70,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120"/>
        <Image x:Name="form_image" HorizontalAlignment="Left" Height="112" Width="142" Margin="330,20,0,0" VerticalAlignment="Top" Source="$($PSScriptRoot)\dummy-logo-03.jpg"/>
    </Grid>
</Window>
"@

$Reader = (New-Object System.Xml.XmlNodeReader $XAML_Menu)
$Window = [Windows.Markup.XamlReader]::Load($Reader)
$Button_Ok = $Window.FindName('Button_Ok')
$Textbox_Hostname = $Window.FindName('Textbox_Hostname')
$CheckBox_7zip = $Window.FindName("CheckBox_7zip")
$CheckBox_Acrobat = $Window.FindName("CheckBox_Acrobat")
$CheckBox_Powershell7 = $Window.FindName("CheckBox_Powershell7")


$Button_Ok.Add_Click({
    $Window.Hide()
    $script:hostname = $Textbox_Hostname.Text.ToString()
   
})

$CheckBox_7zip.Add_Click({
    if($CheckBox_7zip.isChecked) {
        $script:7zip = $true
    }
})

$CheckBox_Acrobat.Add_Click({
    if($CheckBox_Acrobat.isChecked) {
        $script:acrobat = $true
    }
})

$CheckBox_Powershell7.Add_Click({
    if($CheckBox_Powershell7.isChecked) {
        $script:pshell = $true
    }
})

#
# Get Local Script Path
#
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#
# Append our path and image filename together
#
$myIconPath = Join-Path $scriptPath 'icon.ico'
$myIconPath = Join-Path $scriptPath 'dummy-logo-03.jpg'

#
# Add a Loaded Event to load our custom icon and set the Icon property of our Window.
#
$Window.add_Loaded({
    $Window.Icon = $myIconPath
})

$Window.ShowDialog() | Out-Null

$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$TSEnv.Value("OSDComputerName") = "$hostname"
$TSEnv.Value("TS_APP_7ZIP") = "$7zip"
$TSEnv.Value("TS_APP_ACROBAT") = "$acrobat"
$TSEnv.Value("TS_APP_PSHELL") = "$pshell"

write-host "Hostname = $($hostname)"
Write-Host "7-zip = $($7zip)"
Write-Host "Acrobat = $($acrobat)"
Write-Host "PowerShell = $($pshell)"