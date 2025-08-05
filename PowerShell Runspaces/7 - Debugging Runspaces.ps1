<#
  Runspace Debugging Samples.  Note, that if you use any console enhancements like oh-my-posh, you may need to disable them for this to work properly.
#>
$ScriptBlock = 
{
    param($attempt)

    #random Error
    if ($attempt -eq 5)
    {
        #for($i = 0; $i -lt 1000;$i++) {start-sleep -seconds 1} #random hang
        #[System.Environment]::FailFast("Simulated crash") #random crash
        Throw "5!!!! really? How dare you!?" # random error
    }

    #Runspaces store variables
    $variable = $attempt

    #just add time for demo
    Start-sleep -second 5
}

$MINRunspaces = 1
$MAXRunspaces = 10
$initialSessionState = [initialsessionstate]::CreateDefault() 
$RunSpacePool = [RunspaceFactory]::CreateRunspacePool($minRunspaces,$MAXRunspaces,$initialSessionState,$Host)
$RunSpacePool.Open()
$PowershellArray = @()
For ($Counter = 0; $Counter -lt 10; $counter++){
    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace.Name = "Runspace_$($Counter)"
    $PowerShell.Runspacepool = $RunSpacePool
    $Null = $PowerShell.AddScript($ScriptBlock)
    $Null = $PowerShell.AddParameter('attempt',$Counter)
    $Null = $PowerShell.BeginInvoke()
    $PowershellArray += $powershell
}
Start-sleep -Seconds 5

#Find Error and runspace
$BadPowershell = $PowershellArray.where({$PSItem.haderrors})
$BadPowershell[-1].InvocationStateInfo
$r = get-runspace
$BadRunspace = $r.where({$_.SessionStateProxy.PSVariable.Get("error").value.Count -gt 0})
$BadRunspace[-1].SessionStateProxy.PSVariable.Get("error")

###### Using Wait-Debugger to pause the runspace for debugging
$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace.Name = "Runspace_Debug"
[void]$PowerShell.AddScript({
    Wait-Debugger
    $Processes = Get-Process
    $x = 5
    $y = 10
    "Completed"
})
[void]$PowerShell.BeginInvoke()
Debug-Runspace -Name "Runspace_Debug"
(Get-Runspace -Name "Runspace_Debug").Dispose()

### What if we don't want to wait for a debugger to attach, but want to break in?  Maybe we have something that's taking too long and we want to see what's going on.
$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace.Name = "Runspace_Debug2"
[void]$PowerShell.AddScript({
  foreach ($i in 1..11) {
    $x = $i * 2
    Start-Sleep -Seconds 1
  }
})
[void]$PowerShell.BeginInvoke()
Start-Sleep -Seconds 3
Debug-Runspace -Name "Runspace_Debug2" -BreakAll
(Get-Runspace -Name "Runspace_Debug2").Dispose()

### We can also call the debugger method to take a quick peek as well without breaking in.
$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace.Name = "Runspace_Debug3"
[void]$PowerShell.AddScript({
  foreach ($i in 1..11) {
    $x = $i * 2
    Start-Sleep -Seconds 1
  }
})
[void]$PowerShell.BeginInvoke()
Start-Sleep -Seconds 3
$r = (get-runspace).where({$PSItem.RunspaceAvailability -eq 'Busy'})
$r[-1].Debugger.GetCallStack()|select *
(Get-Runspace -Name "Runspace_Debug3").Dispose()