##This example demonstrates creating a runspace with a constrained language mode and no modules or commands available.  It simply outputs a message to the console.
#region a completely empty runspace

$Timer = [System.Diagnostics.Stopwatch]::StartNew()
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
$InitialSessionState.LanguageMode = 'Full'
$InitialSessionState.ExecutionPolicy = 'Bypass'

$PowerShell = [powershell]::Create($InitialSessionState)
$PowerShell.Runspace.Name = "Constrained"
[void]$PowerShell.AddScript({
  Write-Output "`e[41mCan you hear me?`e[0m"
})
$Runspace = "" | Select-Object PowerShell,Handle
$Runspace.Handle = $PowerShell.BeginInvoke()
$Runspace.PowerShell = $PowerShell

Write-Output $Runspace.PowerShell.EndInvoke($Runspace.Handle)
$Runspace.PowerShell.Runspace.Close()
$Runspace.PowerShell.Dispose()
$Timer.Stop()
$Timer.Elapsed
#endregion

##This example demonstrates creating a runspace with a constrained language mode and a module imported.  It simply outputs a message to the console.
#region a less completely empty runspace
$Timer = [System.Diagnostics.Stopwatch]::StartNew()
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
$InitialSessionState.LanguageMode = 'Full'
$InitialSessionState.ExecutionPolicy = 'Bypass'
$InitialSessionState.ImportPSModule('Microsoft.PowerShell.Utility')

$PowerShell = [powershell]::Create($InitialSessionState)
$PowerShell.Runspace.Name = "Constrained"
[void]$PowerShell.AddScript({
  Write-Output "`e[41mCan you hear me now?`e[0m"
})
$Runspace = "" | Select-Object PowerShell,Handle
$Runspace.Handle = $PowerShell.BeginInvoke()
$Runspace.PowerShell = $PowerShell

Write-Output $Runspace.PowerShell.EndInvoke($Runspace.Handle)
$Runspace.PowerShell.Runspace.Close()
$Runspace.PowerShell.Dispose()
$Timer.Stop()
$Timer.Elapsed
#endregion

##This example demonstrates a standard runspace with no constraints.  It simply outputs a message to the console.
#region an unconstrained runspace
$Timer = [System.Diagnostics.Stopwatch]::StartNew()
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()

$PowerShell = [powershell]::Create($InitialSessionState)
$PowerShell.Runspace.Name = "Un-Constrained"
[void]$PowerShell.AddScript({
  Write-Output "`e[41mYou can still hear me right?`e[0m"
})
$Runspace = "" | Select-Object PowerShell,Handle
$Runspace.Handle = $PowerShell.BeginInvoke()
$Runspace.PowerShell = $PowerShell

Write-Output $Runspace.PowerShell.EndInvoke($Runspace.Handle)
$Runspace.PowerShell.Runspace.Close()
$Runspace.PowerShell.Dispose()
$Timer.Stop()
$Timer.Elapsed
#endregion