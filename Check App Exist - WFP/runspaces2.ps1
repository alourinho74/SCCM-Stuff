Function New-ProgressBar {

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    $syncHash = [hashtable]::Synchronized(@{})
    $newRunspace =[runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $newRunspace
    $syncHash.Activity = ''
    $syncHash.PercentComplete = 0
    $newRunspace.ApartmentState = "STA"
    $newRunspace.ThreadOptions = "ReuseThread"
    $data = $newRunspace.Open() | Out-Null
    $newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    $PowerShellCommand = [PowerShell]::Create().AddScript({
        [xml]$xaml = @"
        &lt;Window
            xmlns=&quot;http://schemas.microsoft.com/winfx/2006/xaml/presentation&quot;
            xmlns:x=&quot;http://schemas.microsoft.com/winfx/2006/xaml&quot;
            Name=&quot;Window&quot; Title=&quot;Progress...&quot; WindowStartupLocation = &quot;CenterScreen&quot;
            Width = &quot;300&quot; Height = &quot;100&quot; ShowInTaskbar = &quot;True&quot;&gt;
            &lt;StackPanel Margin=&quot;20&quot;&gt;
               &lt;ProgressBar Name=&quot;ProgressBar&quot; /&gt;
               &lt;TextBlock Text=&quot;{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}&quot; HorizontalAlignment=&quot;Center&quot; VerticalAlignment=&quot;Center&quot; /&gt;
            &lt;/StackPanel&gt;
        &lt;/Window&gt;
"@

        $reader=(New-Object System.Xml.XmlNodeReader $xaml)
        $syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
        #===========================================================================
        # Store Form Objects In PowerShell
        #===========================================================================
        $xaml.SelectNodes("//*[@Name]") | %{ $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name)}

        $updateBlock = {

            $SyncHash.Window.Title = $SyncHash.Activity
            $SyncHash.ProgressBar.Value = $SyncHash.PercentComplete

        }

        ############### New Blog ##############
        $syncHash.Window.Add_SourceInitialized( {
            ## Before the window's even displayed ...
            ## We'll create a timer
            $timer = new-object System.Windows.Threading.DispatcherTimer
            ## Which will fire 4 times every second
            $timer.Interval = [TimeSpan]"0:0:0.01"
            ## And will invoke the $updateBlock
            $timer.Add_Tick( $updateBlock )
            ## Now start the timer running
            $timer.Start()
            if( $timer.IsEnabled ) {
               Write-Host "Clock is running. Don't forget: RIGHT-CLICK to close it."
            } else {
               $clock.Close()
               Write-Error "Timer didn't start"
            }
        } )

        $syncHash.Window.ShowDialog() | Out-Null
        $syncHash.Error = $Error

    })
    $PowerShellCommand.Runspace = $newRunspace
    $data = $PowerShellCommand.BeginInvoke()


    Register-ObjectEvent -InputObject $SyncHash.Runspace `
            -EventName 'AvailabilityChanged' `
            -Action {

                    if($Sender.RunspaceAvailability -eq "Available")
                    {
                        $Sender.Closeasync()
                        $Sender.Dispose()
                    }

                } | Out-Null

    return $syncHash

}


function Write-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        $ProgressBar,
        [Parameter(Mandatory=$true)]
        [String]$Activity,
        [int]$PercentComplete
    )

   $ProgressBar.Activity = $Activity

   if($PercentComplete)
   {

       $ProgressBar.PercentComplete = $PercentComplete

   }

}

function Close-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]$ProgressBar
    )

    $ProgressBar.Window.Dispatcher.Invoke([action]{

      $ProgressBar.Window.close()

    }, "Normal")

}


#Put a Start-Sleep back in if you actually want to see the progress bar up.
$ProgressBar = New-ProgressBar
Measure-Command -Expression {
    1..100 | foreach {Write-ProgressBar -ProgressBar $ProgressBar -Activity "Counting $_ out of 100" -PercentComplete $_}
}
Close-ProgressBar $ProgressBar